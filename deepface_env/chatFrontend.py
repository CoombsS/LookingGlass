import os
import requests
import streamlit as st
from dotenv import load_dotenv
from datetime import datetime
import faceDetectionAndRecognition as FDR

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '.env'))

if "userName" not in st.session_state:
    st.session_state.userName = "Guest"

openai_api_key = os.getenv("OPENAI_API_KEY")
if not openai_api_key:
    raise ValueError("OpenAI API key is not set in environment variables.")

st.set_page_config(layout="wide", page_title="Chatbot Frontend")
st.title("Chatbot Frontend")
st.subheader(f"Welcome {st.session_state.userName}!")

st.markdown("""
    <style>
        .stApp {
            background-image: url("https://images.unsplash.com/photo-1506744038136-46273834b3fb");
            background-size: cover;
            background-position: center;
            color: white;
            padding: 20px;
        }
        .chat-container {
            height: 40vh;
            overflow-y: auto;
            background: rgba(0, 0, 0, 0.4);
            padding: 15px;
            border-radius: 15px;
            margin-bottom: 20px;
        }
        .user-bubble {
            background-color: #4CAF50;
            color: white;
            padding: 12px;
            border-radius: 20px;
            margin: 10px 0;
            max-width: 65%;
            float: right;
            clear: both;
            box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.3);
        }
        .bot-bubble {
            background-color: #333;
            color: white;
            padding: 12px;
            border-radius: 20px;
            margin: 10px 0;
            max-width: 65%;
            float: left;
            clear: both;
            box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.3);
        }
        .timestamp {
            font-size: 0.8em;
            color: #ccc;
            margin-top: 2px;
            display: block;
        }
        .stButton > button {
            background-color: #4CAF50;
            color: white;
            border: none;
            padding: 10px 20px;
            text-align: center;
            display: inline-block;
            font-size: 16px;
            margin: 4px 2px;
            cursor: pointer;
            border-radius: 8px;
        }
        .stButton > button:hover {
            background-color: #45a049;
        }
    </style>
""", unsafe_allow_html=True)

if "chat_history" not in st.session_state:
    st.session_state.chat_history = []

st.session_state.chat_history = [
    entry for entry in st.session_state.chat_history
    if isinstance(entry, tuple) and len(entry) == 3
]

def add_message(sender: str, message: str):
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    st.session_state.chat_history.append((sender, message, now))

def saveChat(userName):
    with open(f"chat_history_{userName}.txt", "w") as f:
        for sender, message, timestamp in st.session_state.chat_history:
            f.write(f"{timestamp} - {sender}: {message}\n")
    st.success("Chat history saved!")

def loadChat(userName):
    filename = f"chat_history_{userName}.txt"
    if os.path.exists(filename):
        with open(filename, "r") as f:
            lines = f.readlines()
            history = []
            for line in lines:
                try:
                    timestamp, rest = line.strip().split(" - ", 1)
                    sender, message = rest.split(": ", 1)
                    sender = sender.strip().lower()
                    history.append((sender, message, timestamp))
                except ValueError:
                    continue
            st.session_state.chat_history = history
        st.success(f"Previous chat history loaded for {userName}")
    else:
        st.session_state.chat_history = []
        st.info("No previous chat history found.")

chat_html = '<div class="chat-container">'
for sender, message, timestamp in reversed(st.session_state.chat_history):
    if sender == "user":
        chat_html += f'''
            <div class="user-bubble">
                <strong>You:</strong> {message}
                <span class="timestamp">{timestamp}</span>
            </div>'''
    else:
        chat_html += f'''
            <div class="bot-bubble">
                <strong>Bot:</strong> {message}
                <span class="timestamp">{timestamp}</span>
            </div>'''
chat_html += '</div>'
st.markdown(chat_html, unsafe_allow_html=True)

input_key = "question_input"
placeholder = st.empty()

def handle_input():
    user_input = st.session_state.get(input_key, "").strip()
    if user_input:
        add_message("user", user_input)
        with st.spinner("Thinking..."):
            conversation = [
                {"role": "user" if s == "user" else "assistant", "content": m}
                for s, m, _t in st.session_state.chat_history
            ]
            response = requests.post(
                "https://api.openai.com/v1/chat/completions",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {openai_api_key}"
                },
                json={
                    "model": "gpt-3.5-turbo",
                    "messages": conversation
                }
            )
            if response.status_code == 200:
                bot_reply = response.json()["choices"][0]["message"]["content"]
            else:
                bot_reply = response.json().get("error", {}).get("message", "Failed to get response.")
            add_message("bot", bot_reply)
        st.session_state[input_key] = ""

clearChat_col, send_col, endChat_col, saveChat_col, detect_col = st.columns([1, 0.3, 0.3, 0.5, 1])

with clearChat_col:
    if st.button("Clear Chat"):
        st.session_state.chat_history = []

with send_col:
    if st.button("Send", key="send_button"):
        handle_input()

with endChat_col:
    if st.button("End Chat"):
        st.success("Chat has ended. Please close the tab or refresh to restart.")
        st.stop()

with saveChat_col:
    if st.session_state.userName != "Guest":
        if st.button("Save Chat"):
            saveChat(st.session_state.userName)
    else:
        if st.button("Save Chat"):
            st.warning("User not detected. Please run face detection or create a user.")

with detect_col:
    if st.button("Recognize Me"):
        detectedName = FDR.detect()
        if detectedName:
            st.session_state.userName = detectedName
            loadChat(detectedName)
            add_message("bot", f"Welcome back, {detectedName}!")
            st.success(f"User detected: {detectedName}")
        else:
            st.error("No face detected.")
            add_message("bot", "No face detected.")

user_input = placeholder.text_input(
    "Your message:",
    key=input_key,
    label_visibility="collapsed",
    on_change=handle_input
)
