from flask import Flask, request, jsonify
from flask_cors import CORS
import cv2
import os
import base64
import numpy as np
from deepface import DeepFace
import json
import mysql.connector
from mysql.connector import Error
# MAJOIRTY OF THIS CODE HAS BEEN TAKEN/MODIFIED FROM faceChatFrontend.py, the precursor project
app = Flask(__name__)
CORS(app)

DB_CONFIG = {
    'host': 'localhost',
    'database': 'lookingglass',
    'user': 'root',
    'password': '',
    'charset': 'utf8mb4'
}

# temp paths
TEMP_FACES_DIR = "data/temp_faces"
os.makedirs(TEMP_FACES_DIR, exist_ok=True)


def get_db_connection():
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except Error as e:
        print(f"Database connection error: {e}")
        return None


def preprocess_face(face_img):
    """
    Preprocess face image for consistent embedding generation.
    Resizes to standard size and applies normalization.
    """
    # Resize to standard size (160x160 is common for Facenet)
    face_resized = cv2.resize(face_img, (160, 160))
    
    # Convert to RGB (DeepFace expects RGB)
    face_rgb = cv2.cvtColor(face_resized, cv2.COLOR_BGR2RGB)
    
    return face_rgb


def get_face_embedding(face_img):
    try:
        # Preprocess the face for consistency
        face_processed = preprocess_face(face_img)
        
        temp_path = os.path.join(TEMP_FACES_DIR, "temp_embedding.jpg")
        cv2.imwrite(temp_path, face_processed)
        
        # make embedding using DeepFace
        embedding_objs = DeepFace.represent(
            img_path=temp_path,
            model_name="Facenet",
            enforce_detection=False,
            detector_backend="skip"  # Skip detection since we already cropped the face
        )
        
        # cleaning up temp file
        if os.path.exists(temp_path):
            os.remove(temp_path)
        
        if embedding_objs and len(embedding_objs) > 0:
            return embedding_objs[0]["embedding"]
        return None
    except Exception as e:
        print(f"Error generating embedding: {e}")
        return None


@app.route("/health", methods=["GET"])
def health():
    response_data = {
        "status": "ok",
        "service": "face_recognition"
    }
    return jsonify(response_data), 200

# Capture face from webcam; pretty much copy/pasted from previous project
@app.route("/capture-face", methods=["POST"])
def capture_face():
    try:
        cam = cv2.VideoCapture(0)
        if not cam.isOpened():
            return jsonify({"error": "Unable to access webcam"}), 500

        face_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
        )
        
        detected_face = None
        max_attempts = 100  # Try for ~3 seconds at 30fps
        
        for attempt in range(max_attempts):
            ret, frame = cam.read()
            if not ret:
                continue
                
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            faces = face_cascade.detectMultiScale(
                gray, scaleFactor=1.3, minNeighbors=5, minSize=(30, 30)
            )
            
            if len(faces) > 0:
                x, y, w, h = faces[0]
                detected_face = frame[y:y+h, x:x+w]
                break

        cam.release()

        if detected_face is None:
            return jsonify({"error": "No face detected"}), 400

        # Encode the detected face image as JPEG
        success, buffer = cv2.imencode('.jpg', detected_face)
        encoded_bytes = base64.b64encode(buffer)
        face_base64 = encoded_bytes.decode('utf-8')
        
        return jsonify({
            "success": True,
            "face_data": face_base64
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Get emotion from face during chat
@app.route("/analyze-emotion", methods=["POST"])
def analyze_emotion():
    try:
        cam = cv2.VideoCapture(0)
        if not cam.isOpened():
            return jsonify({"error": "Unable to access webcam"}), 500
        face_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
        )
        detected_face = None
        max_attempts = 100 # Try for about 3 seconds at 30fps
        
        for attempt in range(max_attempts):
            ret, frame = cam.read()
            if not ret:
                continue
                
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            faces = face_cascade.detectMultiScale(
                gray, scaleFactor=1.3, minNeighbors=5, minSize=(30, 30)
            )
            
            if len(faces) > 0:
                x, y, w, h = faces[0]
                detected_face = frame[y:y+h, x:x+w]
                break

        cam.release()

        if detected_face is None:
            return jsonify({"error": "No face detected"}), 400

        # Save face temporarily
        temp_path = os.path.join(TEMP_FACES_DIR, "temp_emotion.jpg")
        cv2.imwrite(temp_path, detected_face)
        
        # Analyze emotion via DeepFace
        analysis = DeepFace.analyze(
            img_path=temp_path,
            actions=['emotion'],
            enforce_detection=False,
            detector_backend='skip'
        )
        if os.path.exists(temp_path):
            os.remove(temp_path)  
        
        if analysis and len(analysis) > 0:
            emotion_data = analysis[0]['emotion']
            dominant_emotion = analysis[0]['dominant_emotion']
            
            # Convert numpy types to Python native types for JSON serialization
            emotion_data_serializable = {k: float(v) for k, v in emotion_data.items()}
            confidence = float(emotion_data[dominant_emotion])
            
            print(f"[DEBUG] Emotion analysis - Dominant: {dominant_emotion}, Confidence: {confidence:.2f}%")
            print(f"[DEBUG] All emotions: {emotion_data_serializable}")
            
            return jsonify({
                "success": True,
                "emotion": dominant_emotion,
                "confidence": confidence / 100.0,  # Normalize to 0-1
                "all_emotions": emotion_data_serializable
            }), 200
        else:
            return jsonify({"error": "Failed to analyze emotion"}), 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/learn-face", methods=["POST"])
def learn_face():
    try:
        data = request.get_json()
        username = data.get("username")
        face_data_input = data.get("face_data")

        if not username or not face_data_input:
            return jsonify({"error": "Missing username or face_data"}), 400

        # Handle both single face and array of faces
        if isinstance(face_data_input, str):
            face_data_list = [face_data_input]
        elif isinstance(face_data_input, list):
            face_data_list = face_data_input
        else:
            return jsonify({"error": "Invalid face_data format"}), 400

        embeddings = []
        
        # Generate embeddings for each face
        for idx, face_base64 in enumerate(face_data_list):
            face_bytes = base64.b64decode(face_base64)
            nparr = np.frombuffer(face_bytes, np.uint8)
            face_img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

            # Generate face embedding
            embedding = get_face_embedding(face_img)
            if embedding is None:
                return jsonify({"error": f"Failed to generate face embedding for capture {idx + 1}"}), 500
            
            embeddings.append(embedding)
            print(f"[DEBUG] Generated embedding {idx + 1}/{len(face_data_list)} for {username}, length: {len(embedding)}")

        # Store all embeddings in database as JSON array
        connection = get_db_connection()
        if not connection:
            return jsonify({"error": "Database connection failed"}), 500

        try:
            cursor = connection.cursor()
            
            # Convert embeddings array to json for storage
            embeddings_json = json.dumps(embeddings)
            embeddings_bytes = embeddings_json.encode('utf-8')
            
            # Update the faceData column for this user
            update_query = """
                UPDATE users 
                SET faceData = %s 
                WHERE username = %s
            """
            cursor.execute(update_query, (embeddings_bytes, username))
            connection.commit()
            
            rows_affected = cursor.rowcount
            cursor.close()
            connection.close()

            if rows_affected == 0:
                return jsonify({"error": "User not found"}), 404

            return jsonify({
                "success": True,
                "message": f"Face learned for user {username}",
                "face_count": len(embeddings)
            }), 200

        except Error as e:
            if connection:
                connection.close()
            return jsonify({"error": f"Database error: {str(e)}"}), 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/verify-face", methods=["POST"])
def verify_face():
    try:
        data = request.get_json()
        face_base64 = data.get("face_data")

        if not face_base64:
            return jsonify({"error": "Missing face_data"}), 400

        # Decode base64 image
        face_bytes = base64.b64decode(face_base64)
        nparr = np.frombuffer(face_bytes, np.uint8)
        face_img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        # Generate embedding for captured face
        captured_embedding = get_face_embedding(face_img)
        if captured_embedding is None:
            return jsonify({"error": "Failed to generate face embedding from captured image"}), 500
        
        print(f"[DEBUG] verify-face: Generated embedding, length: {len(captured_embedding)}")

        # Get all face embeddings from database
        connection = get_db_connection()
        if not connection:
            return jsonify({"error": "Database connection failed"}), 500

        try:
            cursor = connection.cursor()
            select_query = "SELECT username, faceData FROM users WHERE faceData IS NOT NULL"
            cursor.execute(select_query)
            results = cursor.fetchall()
            cursor.close()
            connection.close()

            if not results:
                return jsonify({
                    "success": True,
                    "recognized": False,
                    "username": None,
                    "message": "No learned faces in database"
                }), 200

            # Compare using cosine similarity (more reliable for face recognition)
            best_match_username = None
            best_match_similarity = -1  # Cosine similarity ranges from -1 to 1
            threshold = 0.70  # Cosine similarity threshold (0.70 = 70% similar, good for faces)

            captured_embedding_np = np.array(captured_embedding)
            captured_norm = captured_embedding_np / np.linalg.norm(captured_embedding_np)
            
            print(f"[DEBUG] Comparing against {len(results)} users")
            print(f"[DEBUG] Captured embedding length: {len(captured_embedding)}")
            
            for username, face_data_blob in results:
                embedding_json = face_data_blob.decode('utf-8')
                stored_data = json.loads(embedding_json)
                
                # Handle both single embedding and array of embeddings
                if isinstance(stored_data[0], list):
                    # Multiple embeddings (new format with 3 faces)
                    stored_embeddings = stored_data
                    print(f"[DEBUG] User {username} has {len(stored_embeddings)} stored face embeddings")
                else:
                    # Single embedding (old format or 1 face)
                    stored_embeddings = [stored_data]
                    print(f"[DEBUG] User {username} has 1 stored face embedding")
                
                # Compare against all stored embeddings and take the best match
                max_similarity_for_user = -1
                
                for idx, stored_embedding in enumerate(stored_embeddings):
                    stored_embedding_np = np.array(stored_embedding)
                    
                    # Calculate cosine similarity (higher = more similar)
                    stored_norm = stored_embedding_np / np.linalg.norm(stored_embedding_np)
                    cosine_sim = np.dot(captured_norm, stored_norm)
                    
                    # Calculate Euclidean distance for reference
                    distance = np.linalg.norm(captured_embedding_np - stored_embedding_np)
                    
                    print(f"[DEBUG] {username} face {idx + 1}/{len(stored_embeddings)}: Similarity: {cosine_sim:.4f}, Distance: {distance:.4f}")
                    
                    if cosine_sim > max_similarity_for_user:
                        max_similarity_for_user = cosine_sim
                
                print(f"[DEBUG] {username} best match: {max_similarity_for_user:.4f}")
                
                # Track best match across all users
                if max_similarity_for_user > best_match_similarity:
                    best_match_similarity = max_similarity_for_user
                    best_match_username = username

            # Check threshold 
            print(f"[DEBUG] Best match: {best_match_username} with similarity: {best_match_similarity:.4f} (threshold: {threshold})")
            
            if best_match_similarity >= threshold:
                print(f"[DEBUG] Match found! Returning {best_match_username}")
                return jsonify({
                    "success": True,
                    "recognized": True,
                    "username": best_match_username,
                    "confidence": float(best_match_similarity)
                }), 200
            else:
                print(f"[DEBUG] No match - similarity {best_match_similarity:.4f} below threshold {threshold}")
                return jsonify({
                    "success": True,
                    "recognized": False,
                    "username": None,
                    "message": f"No match found (best similarity: {best_match_similarity:.4f})"
                }), 200

        except Error as e:
            if connection:
                connection.close()
            return jsonify({
                "success": True,
                "recognized": False,
                "username": None,
                "message": f"Database error: {str(e)}"
            }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/verify-user-face", methods=["POST"])
def verify_user_face():
    try:
        data = request.get_json()
        username = data.get("username")
        face_base64 = data.get("face_data")

        if not username or not face_base64:
            return jsonify({"error": "Missing username or face_data"}), 400

        # Decode base64 image
        face_bytes = base64.b64decode(face_base64)
        nparr = np.frombuffer(face_bytes, np.uint8)
        face_img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        # Generate embedding for captured face
        captured_embedding = get_face_embedding(face_img)
        if captured_embedding is None:
            return jsonify({"error": "Failed to generate face embedding"}), 500

        # Get face embedding for this specific user from database
        connection = get_db_connection()
        if not connection:
            return jsonify({"error": "Database connection failed"}), 500

        try:
            cursor = connection.cursor()
            select_query = "SELECT faceData FROM users WHERE username = %s"
            cursor.execute(select_query, (username,))
            result = cursor.fetchone()
            cursor.close()
            connection.close()

            if not result or not result[0]:
                return jsonify({
                    "success": True,
                    "verified": False,
                    "message": "No face data for this user"
                }), 200

            # Decode to get the embedding
            face_data_blob = result[0]
            embedding_json = face_data_blob.decode('utf-8')
            stored_embedding = json.loads(embedding_json)

            # Compare 
            threshold = 0.6  
            captured_embedding_np = np.array(captured_embedding)
            stored_embedding_np = np.array(stored_embedding)
            
            distance = np.linalg.norm(captured_embedding_np - stored_embedding_np)
            
            # Check if match is below threshold
            if distance < threshold:
                return jsonify({
                    "success": True,
                    "verified": True,
                    "message": f"Face verified for {username}",
                    "confidence": float(1 - distance)
                }), 200
            else:
                return jsonify({
                    "success": True,
                    "verified": False,
                    "message": "Face does not match"
                }), 200

        except Error as e:
            if connection:
                connection.close()
            return jsonify({
                "success": True,
                "verified": False,
                "message": f"Database error: {str(e)}"
            }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5004, debug=True)
