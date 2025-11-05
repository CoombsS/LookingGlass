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

  <style>
    /* ------------------  Base & Theme------------------ */
    :root{
      --bg:#070a0d; --panel:#0e1217; --soft:#141922; --muted:#9aa4b2; --text:#e7edf3;
      --accent:#8b5cf6; --accent-2:#06b6d4; --ring:#2b3340; --card:#0a0f14; --border:#202634;
      --shadow:0 10px 30px rgba(0,0,0,.5);
      --radius:16px; --radius-sm:12px; --radius-xs:10px;
      --gap:16px; --gap-lg:22px; --gap-xl:28px;
    }
    @media (prefers-color-scheme: light){
      :root{
        --bg:#f7fafc; --panel:#ffffff; --soft:#f3f6fb; --muted:#556071; --text:#0f172a;
        --accent:#06b6d4; --accent-2:#8b5cf6; --ring:#d2dae6; --card:#ffffff; --border:#e6ecf5;
        --shadow:0 8px 24px rgba(15,23,42,.08);
      }
    }
    *{box-sizing:border-box}
    html,body{height:100%}
    body{
      margin:0; background:var(--bg); color:var(--text);
      font:16px/1.55 system-ui,-apple-system,Segoe UI,Roboto,Ubuntu,Cantarell,Noto Sans,Helvetica,Arial;
      display:grid; grid-template-columns:320px 1fr; grid-template-rows:auto 1fr auto;
      grid-template-areas:"sidebar header" "sidebar main" "sidebar composer";
    }

    /* ------------------  Sidebar ------------------ */
    .sidebar{
      grid-area:sidebar; background:linear-gradient(180deg,var(--panel),var(--soft));
      border-right:1px solid var(--border); display:flex; flex-direction:column; min-height:100vh;
    }
  .brand{padding:20px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:center; gap:12px}
    .logo{width:36px; height:36px; border-radius:10px;
      background:conic-gradient(from 210deg,var(--accent),var(--accent-2),var(--accent));
      box-shadow:var(--shadow);
    }
    .brand h1{font-size:1.1rem; margin:0; letter-spacing:.3px}

    .sidebar .search{padding:14px 16px; border-bottom:1px solid var(--border)}
    .input{width:100%; padding:10px 12px; border-radius:10px; border:1px solid var(--ring);
      background:var(--card); color:var(--text); outline:none}
    .input:focus{border-color:var(--accent)}

    .list{padding:10px; overflow:auto; flex:1; display:grid; gap:10px}
    .conv{border:1px solid var(--border); border-radius:var(--radius-sm); background:var(--card);
      padding:12px; cursor:pointer; transition:transform .12s ease, border-color .12s}
    .conv:hover{transform:translateY(-1px); border-color:var(--accent)}
    .conv h3{font-size:.95rem; margin:0 0 6px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis}
    .meta{font-size:.78rem; color:var(--muted); display:flex; gap:10px; align-items:center; flex-wrap:wrap}
    .tag{padding:2px 8px; border-radius:999px; border:1px solid var(--border);
      background:rgba(139,92,246,.12); font-size:.72rem; color:var(--text)}

    .sidebar .footer{padding:12px 16px; border-top:1px solid var(--border); color:var(--muted); font-size:.82rem}

    /* ------------------  Header ------------------ */
    .header{
      grid-area:header; display:flex; align-items:center; justify-content:space-between;
      padding:14px 18px; border-bottom:1px solid var(--border); background:var(--panel); position:sticky; top:0; z-index:1200; min-height:64px;
    }
    .controls{display:flex; gap:10px; align-items:center}
    .btn{appearance:none; border:1px solid var(--ring); background:var(--card); color:var(--text);
      padding:8px 12px; border-radius:10px; font-weight:600; letter-spacing:.2px; cursor:pointer;
      transition:transform .12s ease, border-color .12s}
    .btn:hover{border-color:var(--accent); transform:translateY(-1px)}
    .btn.primary{background:linear-gradient(180deg, rgba(139,92,246,.2), var(--card)); border-color:var(--accent)}

    /* ------------------  Main Chat ------------------ */
    main{grid-area:main; padding:var(--gap-lg); overflow:auto}
    .chat-wrap{max-width:1000px; margin-inline:auto; display:grid; gap:14px}
    .system-note{margin:0 auto 8px; font-size:.85rem; color:var(--muted); text-align:center}

    .bubble{
      max-width:80%; padding:12px 14px; border-radius:14px; border:1px solid var(--ring);
      background:var(--card); box-shadow:var(--shadow); position:relative;
      display:inline-flex; flex-direction:column; gap:6px
    }
    .row{display:flex; gap:10px; align-items:flex-end}
    .row.user{justify-content:flex-end}
    .row.assistant{justify-content:flex-start}
    .bubble.user{background:linear-gradient(180deg, rgba(139,92,246,.25), var(--card)); border-color:var(--accent)}
    .bubble .t{white-space:pre-wrap; word-wrap:break-word}
    .bubble .ts{font-size:.75rem; color:var(--muted); align-self:flex-end}
    .avatar{
      width:34px; height:34px; border-radius:50%; background:var(--soft); border:1px solid var(--ring);
      display:flex; align-items:center; justify-content:center; font-weight:700; flex:0 0 34px;
    }
    .avatar.bot{background:linear-gradient(180deg, rgba(6,182,212,.25), var(--soft))}
    .typing{display:inline-block; width:8px; height:8px; margin:0 2px; border-radius:50%; background:var(--muted); opacity:.6; animation:blip 1s infinite}
    .typing:nth-child(2){animation-delay:.15s}
    .typing:nth-child(3){animation-delay:.3s}
    @keyframes blip{0%{opacity:.2; transform:translateY(0)} 50%{opacity:1; transform:translateY(-3px)} 100%{opacity:.2; transform:translateY(0)}}

    /* ------------------  Composer ------------------ */
    .composer{
      grid-area:composer; padding:var(--gap-lg); border-top:1px solid var(--border); background:var(--panel);
      position:sticky; bottom:0; z-index:5;
    }
    .compose-wrap{max-width:1000px; margin-inline:auto; display:grid; gap:10px}
    .bar{display:flex; gap:10px; align-items:flex-end}
    .ta{
      width:100%; min-height:56px; max-height:220px; padding:12px 14px; border-radius:12px;
      border:1px solid var(--ring); background:var(--card); color:var(--text); outline:none; resize:vertical
    }
    .ta:focus{border-color:var(--accent); box-shadow:0 0 0 4px rgba(139,92,246,.2)}
    .hint{font-size:.8rem; color:var(--muted); text-align:right}

    /* ------------------  Responsive ------------------ */
    @media (max-width:1100px){ .chat-wrap{margin-inline:0} }
    @media (max-width:860px){
      body{grid-template-columns:1fr; grid-template-areas:"header" "main" "composer"}
      .sidebar{display:none}
    }

    /* ------------------  Print ------------------ */
    @media print{
      body{display:block; background:#fff; color:#000}
      .sidebar, .header, .composer, .btn{display:none!important}
      main{padding:0}
    }
  </style>
</head>
<body>
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
