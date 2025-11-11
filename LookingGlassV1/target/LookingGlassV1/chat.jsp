<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<!--
  AI USAGE DISCLAIMER
  MOST STYLING ON THIS PAGE IS AI-GENERATED
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

    <div class="list" role="list">
      <!-- THIS WILL BE REPLACED WITH REAL CHAT HISTORY, CURRENTLY A PLACEHOLDER -->
      <div class="conv" role="listitem" tabindex="0">
        <h3>Therapy check-in</h3>
        <div class="meta"><span>Oct 14, 2025</span><span class="tag">#Wellness</span></div>
      </div>
      <div class="conv" role="listitem" tabindex="0">
        <h3>Project scoping with AI</h3>
        <div class="meta"><span>Oct 13, 2025</span><span class="tag">#Work</span></div>
      </div>
      <div class="conv" role="listitem" tabindex="0">
        <h3>Gratitude sprint</h3>
        <div class="meta"><span>Oct 12, 2025</span><span class="tag">#Gratitude</span></div>
      </div>
    </div>

    <div class="footer">Click here for dictation</div>
  </aside>

  <!-- Chat Form wraps header + main + composer -->
  <form id="chatForm"
        method="post"
        action="${pageContext.request.contextPath}/chat/send"
        accept-charset="UTF-8">

    <input type="hidden" name="uid" value='<%= (session != null && session.getAttribute("uid") != null) ? session.getAttribute("uid").toString() : "" %>' />
    <input type="hidden" name="chatID" value='<%= (request.getAttribute("chatID") == null) ? "" : request.getAttribute("chatID").toString() %>' />
    <input type="hidden" name="time" id="timeInput"/>

    <!-- Header -->
    <header class="header" aria-label="Chat header">
      <div class="controls">
        <span class="muted">Private chat</span>
      </div>
      <div class="controls">
        <button class="btn" type="button" id="newChatBtn">New Chat</button>
        <button class="btn" type="button" id="exportBtn">Export</button>
        <button class="btn primary" type="submit">End Chat</button>
      </div>
    </header>

    <!-- Main Chat -->
    <main>
      <div class="chat-wrap" id="chatScrollRegion" aria-live="polite" aria-relevant="additions">
        <p class="system-note">This conversation is for wellness support. Avoid sharing sensitive personal identifiers.</p>

        <!-- PLACEHOLDER MESSAGES -->
        <!-- User -->
        <div class="row user">
          <div class="bubble user" aria-label="You at 9:41 PM">
            <div class="t">Hey, can we talk through some stress I'm having about deadlines?</div>
            <div class="ts">9:41 PM</div>
          </div>
          <div class="avatar">U</div>
        </div>

        <!-- Assistant -->
        <div class="row assistant">
          <div class="avatar bot">LG</div>
          <div class="bubble" aria-label="Assistant at 9:41 PM">
            <div class="t">Absolutely. Want to start with the one that feels heaviest right now?</div>
            <div class="ts">9:41 PM</div>
          </div>
        </div>

        <!-- Typing indicator (toggle via JS while awaiting response) -->
        <div class="row assistant" id="typingRow" style="display:none">
          <div class="avatar bot">LG</div>
          <div class="bubble" aria-label="Assistant is typing">
            <span class="typing"></span><span class="typing"></span><span class="typing"></span>
          </div>
        </div>
      </div>
    </main>

    <!-- Composer -->
    <section class="composer" aria-label="Message composer">
      <div class="compose-wrap">
        <div class="bar">
          <textarea id="message" name="message" class="ta" placeholder="Type a message... (Shift+Enter for newline)" aria-label="Message"></textarea>
          <button class="btn primary" id="sendBtn" type="submit" name="action" value="send">Send</button>
        </div>
        <div class="hint">Press Enter to send • Shift+Enter for newline</div>
      </div>
    </section>
  </form>

  <!-- Behavior -->
  <script>
    (function(){
      function pad(n){ return n<10 ? '0'+n : ''+n; }
      function nowHMS(){
        const d = new Date();
        return pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds());
      }

      const chatForm = document.getElementById('chatForm');
      const messageEl = document.getElementById('message');
      const timeInput = document.getElementById('timeInput');
      const scrollRegion = document.getElementById('chatScrollRegion');
      const typingRow = document.getElementById('typingRow');

      function scrollToBottom(){
        if (!scrollRegion) return;
        scrollRegion.scrollTop = scrollRegion.scrollHeight + 9999;
      }
      scrollToBottom();

      // Enter to send, Shift+Enter for newline
      messageEl.addEventListener('keydown', function(e){
        if (e.key === 'Enter' && !e.shiftKey){
          e.preventDefault();
          document.getElementById('sendBtn').click();
        }
      });

      chatForm.addEventListener('submit', function(){
        if (timeInput && !timeInput.value) timeInput.value = nowHMS();
        // optional visual typing while server responds
        if (typingRow) typingRow.style.display = 'flex';
      });

      // New Chat button: navigate to a fresh chat (adjust path as needed)
      document.getElementById('newChatBtn').addEventListener('click', function(){
        window.location.href = '${pageContext.request.contextPath}/chat/new';
      });

      // Export button: simple client-side export of visible chat (adjust to server export if you prefer)
      document.getElementById('exportBtn').addEventListener('click', function(){
        const msgs = Array.from(document.querySelectorAll('.bubble .t')).map(n => n.textContent.trim());
        const blob = new Blob([msgs.join('\n\n')], {type:'text/plain;charset=utf-8'});
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = 'chat-export.txt';
        document.body.appendChild(a);
        a.click();
        a.remove();
      });

  
  </script>
</body>
</html>
