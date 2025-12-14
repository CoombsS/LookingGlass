import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
from openai import OpenAI
import tempfile

load_dotenv()

app = Flask(__name__)
CORS(app)

# OpenAI Configuration
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
client = OpenAI(api_key=OPENAI_API_KEY)

@app.route('/transcribe', methods=['POST'])
def transcribe_audio():
    try:
        # Check if audio file is in request
        if 'audio' not in request.files:
            return jsonify({
                "success": False, 
                "error": "No audio file provided"
            }), 400
        
        audio_file = request.files['audio']
        
        # Check if file has content
        if audio_file.filename == '':
            return jsonify({
                "success": False, 
                "error": "Empty audio file"
            }), 400
        
        # Save temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix='.webm') as temp_audio:
            audio_file.save(temp_audio.name)
            temp_path = temp_audio.name
        
        try:
            with open(temp_path, 'rb') as audio:
                transcription = client.audio.transcriptions.create(
                    model="whisper-1",
                    file=audio
                )
            
            #clean up temp file
            os.unlink(temp_path)
            
            return jsonify({
                "success": True,
                "text": transcription.text
            }), 200
            
        except Exception as e:
            # Clean up temp file on error
            if os.path.exists(temp_path):
                os.unlink(temp_path)
            raise e
            
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "status": "ok",
        "service": "transcription"
    }), 200

@app.route('/', methods=['GET'])
def index():
    return jsonify({
        "service": "LookingGlass Transcription Service",
        "version": "1.0",
        "endpoints": [
            {"path": "/transcribe", "method": "POST", "description": "Transcribe audio using Whisper"},
            {"path": "/health", "method": "GET", "description": "Health check"}
        ]
    }), 200

if __name__ == '__main__':
    if not OPENAI_API_KEY:
        print("[ERROR] OPENAI_API_KEY environment variable not set!")
        exit(1)
    print("[INFO] Starting Transcription Service on port 5002...")
    app.run(host='0.0.0.0', port=5002, debug=True)
