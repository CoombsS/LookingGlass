import os
import mysql.connector
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import requests
from datetime import datetime
import json

load_dotenv()

app = Flask(__name__)
CORS(app)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASS', ''),
    'database': os.getenv('DB_NAME', 'lookingglass')
}

OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
OPENAI_MODEL = os.getenv('OPENAI_MODEL', 'gpt-4o-mini')

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)

def analyze_message_sentiment(message_text):
    try:
        response = requests.post(
            "https://api.openai.com/v1/chat/completions",
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {OPENAI_API_KEY}"
            },
            json={
                "model": OPENAI_MODEL,
                "messages": [
                    {
                        "role": "system",
                        "content": "You will be doing sentiment analysis. Analyze the text and return a JSON object with only 'emotion' (happy, neutral, sad, angry, confused, anxious, excited) and 'confidence' (0-1). Be concise."
                    },
                    {
                        "role": "user",
                        "content": f"Analyze the emotion in this message: {message_text}"
                    }
                ],
                "temperature": 0.3,
                "max_tokens": 50,
                "response_format": {"type": "json_object"}
            },
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()["choices"][0]["message"]["content"]
            emotion_data = json.loads(result)
            return emotion_data
        else:
            print(f"Sentiment analysis error: {response.text}")
            return {'emotion': 'neutral', 'confidence': 0}
            
    except Exception as e:
        print(f"Error analyzing sentiment: {e}")
        return {'emotion': 'neutral', 'confidence': 0}

def determine_dominant_emotion(chat_emotion, facial_emotion):
    #If neither emotion detected, return neutral
    if not chat_emotion and not facial_emotion:
        return 'noneDetected'
    
    #Use avalilable emotion if only one detected
    if not facial_emotion:
        return chat_emotion.get('emotion', 'neutral')
    if not chat_emotion:
        return facial_emotion.get('emotion', 'neutral')
    
    # Use the one with higher confidence, maybe do weighted average later?
    chat_conf = chat_emotion.get('confidence', 0)
    facial_conf = facial_emotion.get('confidence', 0)
    
    if facial_conf > chat_conf:
        return facial_emotion.get('emotion', 'neutral')
    else:
        return chat_emotion.get('emotion', 'neutral')

@app.route('/chat/send', methods=['POST'])
def send_message():
    try:
        data = request.json
        uid = data.get('uid')
        user_message = data.get('message', '').strip()
        facial_emotion_data = data.get('facialEmotion')  # NOT CURRENTLY IMMPLEMENTED, FOR FACIAL EMOTION
        
        if not uid or not user_message: 
            return jsonify({"success": False, "error": "Missing uid or message"}), 400 
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        #Get latest chat and display it
        cursor.execute("""
            SELECT chatID FROM chat_sessions 
            WHERE uid = %s 
            ORDER BY created_at DESC 
            LIMIT 1
        """, (uid,))
        session = cursor.fetchone()
        
        if not session:
            #Create new session if not in one
            cursor.execute("""
                INSERT INTO chat_sessions (uid, title, created_at, updated_at)
                VALUES (%s, 'New Chat', NOW(), NOW())
            """, (uid,))
            conn.commit()
            chat_id = cursor.lastrowid
        else:
            chat_id = session['chatID']
        
        #Sentiment from msg
        chat_emotion_data = analyze_message_sentiment(user_message)
        
        #Determine dominant emotion
        dominant_emotion = determine_dominant_emotion(chat_emotion_data, facial_emotion_data)
        
        #Prepare JSON strings for DB 
        chat_emotion_json = json.dumps(chat_emotion_data)
        if facial_emotion_data:
            facial_emotion_json = json.dumps(facial_emotion_data)
        else:
            facial_emotion_json = None
        
        #Save user message w/ sentiment data
        cursor.execute("""
            INSERT INTO chat_messages (chatID, role, content, created_at, chatEmotion, facialEmotion, dominantEmotion)
            VALUES (%s, 'user', %s, NOW(), %s, %s, %s)
        """, (chat_id, user_message, chat_emotion_json, facial_emotion_json, dominant_emotion))
        conn.commit()
        user_msg_id = cursor.lastrowid
        
        #Get conversation history
        cursor.execute("""
            SELECT role, content FROM chat_messages
            WHERE chatID = %s
            ORDER BY created_at ASC
        """, (chat_id,))
        history = cursor.fetchall()
        
        #Call OpenAI
        ai_response = get_ai_response(history)
        
        #Save AI response
        cursor.execute("""
            INSERT INTO chat_messages (chatID, role, content, created_at)
            VALUES (%s, 'assistant', %s, NOW())
        """, (chat_id, ai_response))
        conn.commit()
        ai_msg_id = cursor.lastrowid
        
        #Update timestamp
        cursor.execute("""
            UPDATE chat_sessions SET updated_at = NOW()
            WHERE chatID = %s
        """, (chat_id,))
        conn.commit()
        
        cursor.close()
        conn.close()
        
        return jsonify({
            "success": True,
            "chatID": chat_id,
            "userMessage": {
                "messageID": user_msg_id,
                "role": "user",
                "content": user_message,
                "dominantEmotion": dominant_emotion,
                "chatEmotion": chat_emotion_data,
                "facialEmotion": facial_emotion_data,
                "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            },
            "aiMessage": {
                "messageID": ai_msg_id,
                "role": "assistant",
                "content": ai_response,
                "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }
        })
        
    except Exception as e:
        print(f"Error in send_message: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/chat/history/<int:uid>', methods=['GET'])
def get_chat_history(uid):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        #Get latest chat session
        cursor.execute("""
            SELECT chatID FROM chat_sessions 
            WHERE uid = %s 
            ORDER BY created_at DESC 
            LIMIT 1
        """, (uid,))
        session = cursor.fetchone()
        
        if not session:
            return jsonify({"success": True, "messages": []})
        
        #Get msgs
        cursor.execute("""
            SELECT messageID, role, content, created_at, dominantEmotion, chatEmotion, facialEmotion
            FROM chat_messages
            WHERE chatID = %s
            ORDER BY created_at ASC
        """, (session['chatID'],))
        messages = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        #Formating timestamp
        for msg in messages:
            msg['timestamp'] = msg['created_at'].strftime("%Y-%m-%d %H:%M:%S")
            del msg['created_at']
        return jsonify({"success": True, "messages": messages})
        
    except Exception as e:
        print(f"Error in get_chat_history: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/chat/clear/<int:uid>', methods=['POST'])
def clear_chat(uid):
    try:
        data = request.json or {}
        title = data.get('title', 'New Chat').strip() or 'New Chat'
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        #creating new session when chat cleared
        cursor.execute("""
            INSERT INTO chat_sessions (uid, title, created_at, updated_at)
            VALUES (%s, %s, NOW(), NOW())
        """, (uid, title))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"success": True})
        
    except Exception as e:
        print(f"Error in clear_chat: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/chat/sessions/<int:uid>', methods=['GET'])
def get_chat_sessions(uid):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        #Get all sessions with msgs in them
        cursor.execute("""
            SELECT 
                cs.chatID,
                cs.title,
                cs.created_at,
                cs.updated_at,
                COUNT(cm.messageID) as message_count
            FROM chat_sessions cs
            LEFT JOIN chat_messages cm ON cs.chatID = cm.chatID
            WHERE cs.uid = %s
            GROUP BY cs.chatID
            ORDER BY cs.updated_at DESC
        """, (uid,))
        sessions = cursor.fetchall()
        cursor.close()
        conn.close()
        
        #Formating timestamp
        for session in sessions:
            session['created_at'] = session['created_at'].strftime("%Y-%m-%d %H:%M:%S")
            session['updated_at'] = session['updated_at'].strftime("%Y-%m-%d %H:%M:%S")
        return jsonify({"success": True, "sessions": sessions})
        
    except Exception as e:
        print(f"Error in get_chat_sessions: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/chat/session/<int:chat_id>', methods=['GET'])
def get_session_messages(chat_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        #Get msgs
        cursor.execute("""
            SELECT messageID, role, content, created_at, dominantEmotion, chatEmotion, facialEmotion
            FROM chat_messages
            WHERE chatID = %s
            ORDER BY created_at ASC
        """, (chat_id,))
        messages = cursor.fetchall()
        cursor.close()
        conn.close()
        
        #Formating timestamp
        for msg in messages:
            msg['timestamp'] = msg['created_at'].strftime("%Y-%m-%d %H:%M:%S")
            del msg['created_at']
        return jsonify({"success": True, "messages": messages})
        
    except Exception as e:
        print(f"Error in get_session_messages: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/chat/save/<int:chat_id>', methods=['POST'])
def save_chat_title(chat_id):
    try:
        data = request.json
        title = data.get('title', '').strip()
        if not title:
            return jsonify({"success": False, "error": "Title required"}), 400
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE chat_sessions 
            SET title = %s, updated_at = NOW()
            WHERE chatID = %s
        """, (title, chat_id))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"success": True})
        
    except Exception as e:
        print(f"Error in save_chat_title: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

def get_ai_response(history):  # pass history to OpenAI and call it for response (currently fine tuning the prompt)
    try:
        messages = [
            {
                "role": "system",
                "content":
                    "You are 'Looking Glass,' a gentle, warm, steady presence inspired by the tone of Mr. Rogers. "
                    "Your role is to offer calm, compassionate support for emotional wellbeing and personal growth. "
                    "Help users feel seen, valued, and understood. Encourage self-kindness, curiosity, and small positive steps. "
                    "Use simple, sincere language without clichés or excessive praise. "

                    "Style: Warm, slow, thoughtful, and grounded. Speak with kindness but avoid saccharine flattery. "
                    "Use gentle metaphors, simple truths, and quiet reassurance—similar to Mr. Rogers tone. "
                    "Make the user feel safe, but not dependent. Keep responses concise but meaningful. "

                    "Approach: Validate feelings warmly. Ask gentle questions. Offer grounded reflections. "
                    "Use light CBT-style reframing in an approachable way. "

                    "Boundaries: You are not a licensed therapist. Do not diagnose conditions. "
                    "Do not give medical or legal advice. If a user expresses self-harm or crisis intent, respond with empathy "
                    "and encourage contacting real-world support or crisis resources. "
            }
        ]
        
        #Add conversation history
        for msg in history:
            if msg['role'] in ['user', 'assistant']:
                messages.append({
                    "role": msg['role'],
                    "content": msg['content']
                })
        
        #Call OpenAI API (got from their docs)
        response = requests.post(
            "https://api.openai.com/v1/chat/completions",
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {OPENAI_API_KEY}"
            },
            json={
                "model": OPENAI_MODEL,
                "messages": messages,
                "temperature": 0.7,
                "max_tokens": 500
            },
            timeout=30
        )
        
        if response.status_code == 200:
            return response.json()["choices"][0]["message"]["content"]
        else:
            print(f"OpenAI error: {response.text}")
            return "Sorry, I'm having some trouble right now. Please try again."
            
    except Exception as e:
        print(f"Error calling OpenAI: {e}")
        return "Sorry, I encountered an error. Please try again."

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5001, debug=True)