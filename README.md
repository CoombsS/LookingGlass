**Looking Glass**

Looking glass is a personal wellness advisor that utilizes AI to provide users insight into their behavioral patterns through journaling, chatting with a AI advisor, and analytics. 
Required packages and versions: 
-opencv(cv2) 
-deepface: https://github.com/serengil/deepface 
-OpenAI API key
-Python 3.10.0

You will also need to use Visual Studio code and download the following extensions: TODO, Github, and draw.io (to see the flow charts, not needed but its cool!)

To run: Download all the packages you need and set everything up in the same virtual env as deepface for the recognition and deep learning. Then cd into the deepface_env, and run via "streamlit run chatFrontend.py". Wait for the facial detection to finish and chat away!
1. Create python virtual enviorment in main directory and activate
2. Create .env and place your OpenAI API key inside
3. Optional: Do 'pip install -r requirements.txt'

## Roadmap
- Journaling
- Mood tracking dashboard
- New chat interface 
- Face/voice emotion detection
- TTS and STT