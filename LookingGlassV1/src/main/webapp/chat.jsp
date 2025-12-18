<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<!--
  AI USAGE DISCLAIMER
  MOST (TBH ALL) STYLING ON THIS PAGE IS AI-GENERATED
-->
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Looking Glass — Chat</title>

  <!-- External Stylesheets -->
  <link rel="stylesheet" href="css/app.css">
  <link rel="stylesheet" href="css/chat.css">
</head>
<body class="grid-chat">
  <% request.setCharacterEncoding("UTF-8"); %>
  <%@ include file="/WEB-INF/drawer.jspf" %>

  <!-- Sidebar -->
  <aside class="sidebar" aria-label="Conversations">
    <div class="brand">
      <div class="logo" aria-hidden="true"></div>
      <h1>Looking Glass</h1>
    </div>

    <div class="search">
      <input class="input" id="chatSearchInput" type="search" placeholder="Search chats..." aria-label="Search conversations" />
    </div>

    <div class="list" role="list" id="chatSessionsList">
      <p class="muted" style="padding: 12px;">Loading conversations...</p>
    </div>

    <div class="footer">Check analytics tab for recommended resources</div>
  </aside>

  <input type="hidden" id="uid" value='<%= (session != null && session.getAttribute("uid") != null) ? session.getAttribute("uid").toString() : "" %>' />
  <input type="hidden" id="currentChatID" value="" />

  <!-- Header -->
  <header class="header" aria-label="Chat header">
      <div class="controls">
        <span class="muted">Private chat</span>
      </div>
      <div class="controls">
        <button class="btn" type="button" id="clearChatBtn">New Chat</button>
        <button class="btn primary" type="button" id="saveBtn">Save</button>
      </div>
    </header>

    <!-- Main Chat -->
    <main>
      <div class="chat-wrap" id="chatScrollRegion" aria-live="polite" aria-relevant="additions">
        <p class="system-note">This conversation is for mental wellness support. Please avoid sharing identifying information.</p>

        <!-- Typing indicator -->
        <div class="row assistant" id="typingRow" style="display:none">
          <div class="avatar bot">LG</div>
          <div class="bubble" aria-label="Assistant is typing">
            <span class="typing"></span><span class="typing"></span><span class="typing"></span>
          </div>
        </div>
      </div>
    </main>

    <!-- Input box (chat helped with styling of course) -->
    <section class="composer" aria-label="Message composer">
      <div class="compose-wrap">
        <div class="bar">
          <textarea id="message" class="ta" placeholder="Type a message... (Shift+Enter for newline)" aria-label="Message"></textarea>
          <button class="btn primary" id="sendBtn" type="button">Send</button>
        </div>
        <div class="hint" id="statusHint">Press Enter to send</div>
      </div>
    </section>

  <!-- connection to apis, and var declaration -->
  <script>
    (function(){
      const API_BASE = 'http://127.0.0.1:5001';
      const messageEl = document.getElementById('message');
      const scrollRegion = document.getElementById('chatScrollRegion');
      const typingRow = document.getElementById('typingRow');
      const sendBtn = document.getElementById('sendBtn');
      const uidInput = document.getElementById('uid');
      const currentChatIDInput = document.getElementById('currentChatID');
      const chatSessionsList = document.getElementById('chatSessionsList');
      const chatSearchInput = document.getElementById('chatSearchInput');
      const statusHint = document.getElementById('statusHint');
      let allSessions = [];

      // Date/time formatting (chat helped with this as well)
      function pad(n){ return n<10 ? '0'+n : ''+n; }
      function formatTime(dateStr){
        const d = dateStr ? new Date(dateStr) : new Date();
        let h = d.getHours();
        const m = pad(d.getMinutes());
        const ampm = h >= 12 ? 'PM' : 'AM';
        h = h % 12 || 12;
        return h + ':' + m + ' ' + ampm;
      }

      function formatDate(dateStr){
        const d = new Date(dateStr);
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[d.getMonth()] + ' ' + d.getDate() + ', ' + d.getFullYear();
      }

      //Scroll chat automatically to bottom/most recent messages
      function scrollToBottom(){
        if (!scrollRegion) return;
        setTimeout(() => {
          scrollRegion.scrollTop = scrollRegion.scrollHeight + 9999;
        }, 50);
      }

      // Sending message/displaying in bubbles
      function addMessage(role, content, timestamp){
        const isUser = role === 'user';
        const rowDiv = document.createElement('div');
        rowDiv.className = 'row ' + (isUser ? 'user' : 'assistant');

        const timeStr = formatTime(timestamp);
        const bubbleHTML = `
          <div class="bubble ${isUser ? 'user' : ''}" aria-label="${isUser ? 'You' : 'Assistant'} at ${timeStr}">
            <div class="t">${escapeHtml(content)}</div>
            <div class="ts">${timeStr}</div>
          </div>
        `;
        // Avatar and typing showing when ai is responding (maybe make an actual png/use logo instead of 'LG')
        if (isUser) {
          rowDiv.innerHTML = bubbleHTML + '<div class="avatar">U</div>';
        } else {
          rowDiv.innerHTML = '<div class="avatar bot">LG</div>' + bubbleHTML;
        }
        scrollRegion.insertBefore(rowDiv, typingRow);
        scrollToBottom();
      }

      function escapeHtml(text){
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
      }
      //disclaimer, AI helped me with all the loading past chat history and sessions bc i could not figure that out and make it look good.
      function loadChatHistory(){
        const uid = uidInput.value;
        if (!uid) return; //if no user logged in exit, cause why you here??
        // ask api for chat history
        fetch(API_BASE + '/chat/history/' + uid)  //ask api for history
          .then(res => res.json())  //when successful, parse it
          .then(data => {           //then if successful and a message is there, display it
            if (data.success && data.messages) {
              const messages = scrollRegion.querySelectorAll('.row:not(#typingRow)');
              messages.forEach(m => {
                if (!m.querySelector('.system-note')) m.remove();
              });
              // Add messages
              data.messages.forEach(msg => {
                addMessage(msg.role, msg.content, msg.timestamp);
              });
            }
          })
          .catch(err => console.error('Error loading chat history:', err));
      }

      function loadChatSessions(){
        const uid = uidInput.value;
        if (!uid) return; //if no user logged in exit, cause why you here??
        fetch(API_BASE + '/chat/sessions/' + uid)
          .then(res => res.json())
          .then(data => {
            if (data.success && data.sessions) {
              allSessions = data.sessions; // Store all sessions
              displaySessions(allSessions);
            }
          })
          .catch(err => console.error('Error loading chat sessions:', err));
      }

      function displaySessions(sessions){
        if (sessions.length === 0) {
          const searchQuery = chatSearchInput.value.trim();
          if (searchQuery) {
            chatSessionsList.innerHTML = '<p class="muted" style="padding: 12px;">No conversations match "' + escapeHtml(searchQuery) + '"</p>';
          } else {
            chatSessionsList.innerHTML = '<p class="muted" style="padding: 12px;">No conversations yet. Start chatting!</p>';
          }
          return;
        }

        chatSessionsList.innerHTML = '';
        sessions.forEach(session => {
          const convDiv = document.createElement('div');
          convDiv.className = 'conv';
          convDiv.role = 'listitem';
          convDiv.tabIndex = 0;
          convDiv.dataset.chatId = session.chatID;
          const title = session.title || 'New Chat';
          const date = formatDate(session.updated_at);
          const msgCount = session.message_count || 0;
          convDiv.innerHTML = `
            <h3>${escapeHtml(title)}</h3>
            <div class="meta"><span>${date}</span><span class="tag">${msgCount} messages</span></div>
          `;
          convDiv.addEventListener('click', () => loadSpecificChat(session.chatID));
          chatSessionsList.appendChild(convDiv);
        });
      }

      function filterSessions(){
        const searchQuery = chatSearchInput.value.trim().toLowerCase();

        if (!searchQuery) {
          // No search, show all sessions
          displaySessions(allSessions);
          return;
        }

        // Filter sessions by title or date
        const filteredSessions = allSessions.filter(session => {
          const title = (session.title || 'New Chat').toLowerCase();
          const date = formatDate(session.updated_at).toLowerCase();

          return title.includes(searchQuery) || date.includes(searchQuery);
        });

        displaySessions(filteredSessions);
      }
      chatSearchInput.addEventListener('input', filterSessions);

      function loadSpecificChat(chatId){
        fetch(API_BASE + '/chat/session/' + chatId)
          .then(res => res.json())
          .then(data => {
            if (data.success && data.messages) {
              // Update current chat ID
              currentChatIDInput.value = chatId;

              // Clear existing messages
              const messages = scrollRegion.querySelectorAll('.row:not(#typingRow)');
              messages.forEach(m => {
                if (!m.querySelector('.system-note')) m.remove();
              });

              // Add messages
              data.messages.forEach(msg => {
                addMessage(msg.role, msg.content, msg.timestamp);
              });
            }
          })
          .catch(err => console.error('Error loading specific chat:', err));
      }

      async function sendMessage(audioBase64 = null){
        const message = audioBase64 ? '' : messageEl.value.trim();
        const uid = uidInput.value;
        if ((!message && !audioBase64) || !uid) return;

        // Disable send button
        sendBtn.disabled = true;
        messageEl.disabled = true;
        if (window.voiceChat) {
          window.voiceChat.micBtn.disabled = true;
        }

        // Capture facial emotion before sending
        statusHint.textContent = 'Analyzing facial emotion...';
        statusHint.style.color = '#3b82f6';

        let facialEmotionData = null;
        try {
          console.log('[DEBUG] Attempting to capture facial emotion...');
          const emotionResponse = await fetch('http://localhost:5004/analyze-emotion', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'}
          });

          console.log('[DEBUG] Emotion response status:', emotionResponse.status);

          if (emotionResponse.ok) {
            const emotionData = await emotionResponse.json();
            console.log('[DEBUG] Emotion data received:', emotionData);

            if (emotionData.success) {
              facialEmotionData = {
                emotion: emotionData.emotion,
                confidence: emotionData.confidence,
                all_emotions: emotionData.all_emotions
              };
              console.log('[DEBUG] Facial emotion captured successfully:', facialEmotionData);
              statusHint.textContent = `Emotion detected: ${emotionData.emotion}`;
              statusHint.style.color = '#10b981';
            } else {
              console.warn('[DEBUG] Emotion data success=false:', emotionData);
              statusHint.textContent = 'Emotion capture failed, sending message...';
              statusHint.style.color = '#f59e0b';
            }
          } else {
            const errorData = await emotionResponse.json();
            console.warn('[DEBUG] Emotion response not OK:', errorData);
            statusHint.textContent = 'Emotion capture failed, sending message...';
            statusHint.style.color = '#f59e0b';
          }
        } catch (emotionErr) {
          console.error('[DEBUG] Exception during emotion capture:', emotionErr);
          statusHint.textContent = 'Emotion capture failed, sending message...';
          statusHint.style.color = '#f59e0b';
          // Continue with message send even if emotion capture fails
        }

        // Show typing indicator
        statusHint.textContent = audioBase64 ? 'Sending voice message...' : 'Sending message...';
        statusHint.style.color = '#3b82f6';
        typingRow.style.display = 'flex';
        scrollToBottom();

        try {
          const payload = {
            uid: parseInt(uid),
            message: message,
            facialEmotion: facialEmotionData
          };

          // Add audio if present
          if (audioBase64) {
            payload.audio_base64 = audioBase64;
          }

          console.log('[DEBUG] Sending to chat service:', payload);

          const response = await fetch(API_BASE + '/chat/send', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(payload)
          });
          const data = await response.json();
          console.log('[DEBUG] Chat service response:', data);

          if (data.success) {
            // Update current chat ID if this is a new chat
            if (data.chatID && !currentChatIDInput.value) {
              currentChatIDInput.value = data.chatID;
            }

            // Add user message
            addMessage('user', data.userMessage.content, data.userMessage.timestamp);

            // Add AI response
            addMessage('assistant', data.aiMessage.content, data.aiMessage.timestamp);

            // Clear input
            messageEl.value = '';

            // Play AI audio response if available
            if (data.content_audio_base64 && window.voiceChat) {
              statusHint.textContent = 'Playing response...';
              statusHint.style.color = '#10b981';
              await window.voiceChat.playAudio(data.content_audio_base64);

              // After playing, start recording again if in voice mode
              if (audioBase64) {
                setTimeout(() => {
                  if (window.voiceChat && !window.voiceChat.isRecording) {
                    window.voiceChat.startRecording();
                  }
                }, 500);
              }
            }

            // Reload sidebar to show updated conversation
            loadChatSessions();
          } else {
            alert('Error: ' + (data.error || 'Failed to send message'));
          }
        } catch (err) {
          console.error('Error sending message:', err);
          alert('Failed to send message. Make sure the chat service is running on port 5001.');
        } finally {
          // Hide typing indicator
          typingRow.style.display = 'none';

          // Reset status hint
          statusHint.textContent = 'Press Enter to send';
          statusHint.style.color = '';

          // Re-enable inputs
          sendBtn.disabled = false;
          messageEl.disabled = false;
          if (window.voiceChat) {
            window.voiceChat.micBtn.disabled = false;
          }
          messageEl.focus();
        }
      }

      // Enter to send, Shift+Enter for newline
      messageEl.addEventListener('keydown', function(e){
        if (e.key === 'Enter' && !e.shiftKey){
          e.preventDefault();
          sendMessage();
        }
      });

      // Send button
      sendBtn.addEventListener('click', () => sendMessage());

      // New Chat button
      document.getElementById('clearChatBtn').addEventListener('click', async function(){
        const uid = uidInput.value;
        const chatId = currentChatIDInput.value;
        if (!uid) return;

        // Check if current chat needs a title first
        if (chatId) {
          try {
            const sessionsResponse = await fetch(API_BASE + '/chat/sessions/' + uid);
            const sessionsData = await sessionsResponse.json();
            if (sessionsData.success && sessionsData.sessions) {
              const currentSession = sessionsData.sessions.find(s => s.chatID == chatId);
              if (currentSession && currentSession.title === 'New Chat') {
                // Prompt for title for the current chat before creating new one
                let currentTitle = '';
                while (!currentTitle || !currentTitle.trim()) {
                  currentTitle = prompt('Please give the current chat a title before starting a new one:');
                  if (currentTitle === null) {
                    return; // User cancelled
                  }
                  if (!currentTitle.trim()) {
                    alert('Title is required for the current chat.');
                  }
                }
                // Save the current chat title
                await fetch(API_BASE + '/chat/save/' + chatId, {
                  method: 'POST',
                  headers: {'Content-Type': 'application/json'},
                  body: JSON.stringify({title: currentTitle.trim()})
                });
              }
            }
          } catch (err) {
            console.error('Error checking current chat title:', err);
          }
        }

        if (!confirm('Start a new chat?')) return;

        try {
          const response = await fetch(API_BASE + '/chat/clear/' + uid, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({title: 'New Chat'})
          });

          const data = await response.json();
          if (data.success) {
            // Clear messages from UI
            const messages = scrollRegion.querySelectorAll('.row:not(#typingRow)');
            messages.forEach(m => {
              if (!m.querySelector('.system-note')) m.remove();
            });

            // Clear current chat ID
            currentChatIDInput.value = '';

            // Reload sidebar
            loadChatSessions();
          }
        } catch (err) {
          console.error('Error creating new chat:', err);
          alert('Failed to create new chat.');
        }
      });

      // Save button
      document.getElementById('saveBtn').addEventListener('click', async function(){
        const chatId = currentChatIDInput.value;
        if (!chatId) {
          alert('No active chat to save. Send a message first.');
          return;
        }
        //require title for chat
        let title = '';
        while (!title || !title.trim()) {
          title = prompt('Enter a title for this conversation (required):');
          if (title === null) {
            // User clicked cancel
            return;
          }
          if (!title.trim()) {
            alert('Title is required to save the chat.');
          }
        }

        try {
          const response = await fetch(API_BASE + '/chat/save/' + chatId, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({title: title.trim()})
          });

          const data = await response.json();
          if (data.success) {
            alert('Chat saved successfully!');
            loadChatSessions(); // Reload sidebar to show updated title
          } else {
            alert('Error: ' + (data.error || 'Failed to save chat'));
          }
        } catch (err) {
          console.error('Error saving chat:', err);
          alert('Failed to save chat.');
        }
      });

      // Load chat history and sessions on page load
      loadChatHistory();
      loadChatSessions();
      scrollToBottom();

      // Expose sendMessage globally for voice chat
      window.sendMessage = sendMessage;
    })();

    // VOICE CHAT SCRIPT //
    class VoiceChat {
      constructor() {
        this.mediaRecorder = null;
        this.audioChunks = [];
        this.isRecording = false;
        this.silenceThreshold = 10000; // 10 seconds
        this.audioContext = null;

        this.micBtn = document.getElementById('micBtn');
        this.statusHint = document.getElementById('statusHint');

        if (this.micBtn) {
          this.init();
        }
      }

      init() {
        this.micBtn.addEventListener('click', () => this.toggleRecording());
      }

      async toggleRecording() {
        if (!this.isRecording) {
          await this.startRecording();
        } else {
          this.stopRecording();
        }
      }

      async startRecording() {
        try {
          const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
          this.mediaRecorder = new MediaRecorder(stream);
          this.audioChunks = [];

          this.mediaRecorder.ondataavailable = (event) => {
            if (event.data.size > 0) {
              this.audioChunks.push(event.data);
            }
          };

          this.mediaRecorder.onstop = () => {
            this.processAudio();
          };

          this.mediaRecorder.start();
          this.isRecording = true;
          this.micBtn.classList.add('recording');
          this.micBtn.textContent = '⏹️ Stop';
          this.statusHint.textContent = 'Recording... (will auto-stop after 10 seconds of silence)';

          // Setup silence detection
          this.setupSilenceDetection(stream);

        } catch (error) {
          console.error('Error accessing microphone:', error);
          this.statusHint.textContent = 'Error: Could not access microphone';
        }
      }

      setupSilenceDetection(stream) {
        if (this.audioContext) {
          this.audioContext.close();
        }

        this.audioContext = new AudioContext();
        const analyser = this.audioContext.createAnalyser();
        const microphone = this.audioContext.createMediaStreamSource(stream);
        const dataArray = new Uint8Array(analyser.frequencyBinCount);

        microphone.connect(analyser);
        analyser.fftSize = 512;

        let lastSoundTime = Date.now();

        const checkAudioLevel = () => {
          if (!this.isRecording) {
            if (this.audioContext) {
              this.audioContext.close();
              this.audioContext = null;
            }
            return;
          }

          analyser.getByteFrequencyData(dataArray);
          const average = dataArray.reduce((a, b) => a + b) / dataArray.length;

          // Threshold for detecting sound (adjust as needed)
          if (average > 10) {
            lastSoundTime = Date.now();
          }

          // Check if silence duration exceeded
          if (Date.now() - lastSoundTime > this.silenceThreshold) {
            this.stopRecording();
            if (this.audioContext) {
              this.audioContext.close();
              this.audioContext = null;
            }
            return;
          }

          requestAnimationFrame(checkAudioLevel);
        };

        checkAudioLevel();
      }

      stopRecording() {
        if (this.mediaRecorder && this.isRecording) {
          this.mediaRecorder.stop();
          this.mediaRecorder.stream.getTracks().forEach(track => track.stop());
          this.isRecording = false;
          this.micBtn.classList.remove('recording');
          this.micBtn.textContent = '🎤 Voice';
          this.statusHint.textContent = 'Processing audio...';
        }
      }

      async processAudio() {
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' });

        try {
          // Convert to WAV format
          const arrayBuffer = await audioBlob.arrayBuffer();
          const audioContext = new AudioContext();
          const audioBuffer = await audioContext.decodeAudioData(arrayBuffer);
          const wavBlob = await this.audioBufferToWav(audioBuffer);

          // Convert to base64
          const reader = new FileReader();
          reader.onloadend = async () => {
            const base64Audio = reader.result.split(',')[1];
            // Call the global sendMessage function with audio
            await window.sendMessage(base64Audio);
          };
          reader.readAsDataURL(wavBlob);
        } catch (error) {
          console.error('Error processing audio:', error);
          this.statusHint.textContent = 'Error processing audio';
        }
      }

      async audioBufferToWav(audioBuffer) {
        const numberOfChannels = audioBuffer.numberOfChannels;
        const length = audioBuffer.length * numberOfChannels * 2;
        const buffer = new ArrayBuffer(44 + length);
        const view = new DataView(buffer);
        const channels = [];
        let pos = 0;

        // Write WAV header
        const setUint16 = (data) => {
          view.setUint16(pos, data, true);
          pos += 2;
        };
        const setUint32 = (data) => {
          view.setUint32(pos, data, true);
          pos += 4;
        };

        // "RIFF" chunk descriptor
        setUint32(0x46464952); // "RIFF"
        setUint32(36 + length); // file length
        setUint32(0x45564157); // "WAVE"

        // "fmt " sub-chunk
        setUint32(0x20746d66); // "fmt "
        setUint32(16); // subchunk1 size
        setUint16(1); // audio format (1 = PCM)
        setUint16(numberOfChannels);
        setUint32(audioBuffer.sampleRate);
        setUint32(audioBuffer.sampleRate * 2 * numberOfChannels); // byte rate
        setUint16(numberOfChannels * 2); // block align
        setUint16(16); // bits per sample

        // "data" sub-chunk
        setUint32(0x61746164); // "data"
        setUint32(length);

        // Write interleaved data
        for (let i = 0; i < audioBuffer.numberOfChannels; i++) {
          channels.push(audioBuffer.getChannelData(i));
        }

        let offset = 0;
        while (pos < buffer.byteLength) {
          for (let i = 0; i < numberOfChannels; i++) {
            let sample = Math.max(-1, Math.min(1, channels[i][offset]));
            sample = sample < 0 ? sample * 0x8000 : sample * 0x7FFF;
            view.setInt16(pos, sample, true);
            pos += 2;
          }
          offset++;
        }

        return new Blob([buffer], { type: 'audio/wav' });
      }

      async playAudio(base64Audio) {
        return new Promise((resolve, reject) => {
          const audio = new Audio('data:audio/wav;base64,' + base64Audio);
          audio.onended = () => {
            this.statusHint.textContent = 'Response finished. Recording...';
            resolve();
          };
          audio.onerror = (error) => {
            this.statusHint.textContent = 'Error playing audio';
            reject(error);
          };
          audio.play();
        });
      }
    }

    // Initialize voice chat when page loads
    document.addEventListener('DOMContentLoaded', () => {
      window.voiceChat = new VoiceChat();
    });
</script>
</body>
</html>