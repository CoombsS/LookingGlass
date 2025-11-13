import os
import json
from flask import Flask, request, jsonify
import logging
import mysql.connector
from mysql.connector import Error

# Load .env file if it exists
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass 

# ---------- Config ----------
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "root")
DB_PASS = os.getenv("DB_PASS", "")
DB_NAME = os.getenv("DB_NAME", "lookingglass")
DB_TABLE = "journals"

# Only create openai client if needed
if OPENAI_API_KEY:
    from openai import OpenAI
    client = OpenAI(api_key=OPENAI_API_KEY)
else:
    client = None

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

# DB connection
def get_db_connection():
    conn_params = {
        "host": DB_HOST,
        "user": DB_USER,
        "database": DB_NAME
    }
    # since no password, and it does not like it
    if DB_PASS:
        conn_params["password"] = DB_PASS
    return mysql.connector.connect(**conn_params)

def analyze_sentiment(entry_text: str):
    if not client:
        raise ValueError("There is no OpenAI client, please set the OPENAI_API_KEY environment variable.")
    
    #key phrases will be sent to 'data' field. 
    prompt = f"Analyze this journal entry for sentiment and return JSON with fields: sentiment (positive/negative/neutral), score (0-1), and key_phrases (list). Entry: {entry_text}"
    resp = client.chat.completions.create(
        model=OPENAI_MODEL,
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"}
    )
    raw_text = resp.choices[0].message.content
    return json.loads(raw_text)


# ---------- REST Endpoints ----------
@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint to verify service is running."""
    return jsonify({"status": "ok", "service": "sentiment-analysis"}), 200

@app.route("/sentiment", methods=["POST"])
def analyze_sentiment_only():
    """Endpoint to analyze sentiment of a journal entry and update DB."""
    payload = request.get_json() or {}
    logging.info("/sentiment called with payload: %s", payload) #debugging log

    # Require both uid and journalId to ensure correct entry
    journal_id = payload.get("journalId")
    uid = payload.get("uid")
    if journal_id is None or uid is None:
        return jsonify({"error": "must include both 'uid' and 'journalId'"}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Fetch the journal row and verify ownership by uid
        cursor.execute(f"SELECT journalID, uid, entry FROM journals WHERE journalID=%s", (journal_id,))
        row = cursor.fetchone()
        if not row:
            return jsonify({"error": "journalId not found"}), 404 #if none, send 404
        row_id, row_uid, entry = row[0], row[1], row[2]
        if int(row_uid) != int(uid):
            return jsonify({"error": "uid does not match journal owner"}), 403 #if uid mismatch (which shouldnt happen), send 403

        # analyze 
        try:
            sentiment_result = analyze_sentiment(entry)
            # Extract score and key phrases from sentiment result
            sentiment_score = sentiment_result.get("score", 0.5)
            key_phrases = sentiment_result.get("key_phrases", [])
            # Convert key phrases list to JSON string for data field
            key_phrases_json = json.dumps(key_phrases) if key_phrases else None
        except Exception as e:
            logging.exception("analyze_sentiment failed for journalId=%s", journal_id)
            return jsonify({"error": f"analysis failed: {str(e)}"}), 500

        # Update both sentiment score and data (key phrases)
        update_sql = f"UPDATE journals SET sentiment=%s, data=%s WHERE journalID=%s"
        cursor.execute(update_sql, (sentiment_score, key_phrases_json, journal_id))
        conn.commit()
        cursor.close()
        conn.close()
        logging.info("Updated sentiment for journalId=%s with score=%s and key_phrases", journal_id, sentiment_score)
        return jsonify({"journalId": journal_id, "sentiment": sentiment_result, "score": sentiment_score, "key_phrases": key_phrases}), 200

    except Error as e:
        logging.exception("DB error in /sentiment endpoint")
        if cursor:
            try:
                cursor.close()
            except:
                pass
        if conn:
            try:
                conn.close()
            except:
                pass
        return jsonify({"error": f"DB error: {str(e)}"}), 500
    except Exception as e:
        logging.exception("Unexpected error in /sentiment endpoint")
        if cursor:
            try:
                cursor.close()
            except:
                pass
        if conn:
            try:
                conn.close()
            except:
                pass
        return jsonify({"error": f"Unexpected error: {str(e)}"}), 500

# ---------- Run server ----------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)