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
      <input class="input" type="search" placeholder="Search chats..." aria-label="Search conversations" />
    </div>

    <div class="list" role="list" id="chatSessionsList">
      <p class="muted" style="padding: 12px;">Loading conversations...</p>
    </div>

    <div class="footer">Click here for resources</div>
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
        <div class="hint">Press Enter to send</div>
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
          <div class="bubble \${isUser ? 'user' : ''}" aria-label="\${isUser ? 'You' : 'Assistant'} at \${timeStr}">
            <div class="t">\${escapeHtml(content)}</div>
            <div class="ts">\${timeStr}</div>
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
              if (data.sessions.length === 0) {
                chatSessionsList.innerHTML = '<p class="muted" style="padding: 12px;">No conversations yet. Start chatting!</p>';
                return;
              }
              chatSessionsList.innerHTML = '';
              data.sessions.forEach(session => {
                const convDiv = document.createElement('div');
                convDiv.className = 'conv';
                convDiv.role = 'listitem';
                convDiv.tabIndex = 0;
                convDiv.dataset.chatId = session.chatID;
                const title = session.title || 'New Chat';
                const date = formatDate(session.updated_at);
                const msgCount = session.message_count || 0;
                convDiv.innerHTML = `
                  <h3>\${escapeHtml(title)}</h3>
                  <div class="meta"><span>\${date}</span><span class="tag">\${msgCount} messages</span></div>
                `;
                convDiv.addEventListener('click', () => loadSpecificChat(session.chatID));
                chatSessionsList.appendChild(convDiv);
              });
            }
          })
          .catch(err => console.error('Error loading chat sessions:', err));
      }

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

      async function sendMessage(){
        const message = messageEl.value.trim();
        const uid = uidInput.value;
        if (!message || !uid) return;
        // Disable send button
        sendBtn.disabled = true;
        messageEl.disabled = true;
        // Show typing indicator
        typingRow.style.display = 'flex';
        scrollToBottom();
        try {
          const response = await fetch(API_BASE + '/chat/send', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({uid: parseInt(uid), message: message})
          });
          const data = await response.json();
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
          
          // Re-enable inputs
          sendBtn.disabled = false;
          messageEl.disabled = false;
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
      sendBtn.addEventListener('click', sendMessage);

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
    })();
  </script>
</body>
</html>