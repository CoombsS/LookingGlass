<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<meta charset="UTF-8" />
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="ISO-8859-1" />
  <title>Login</title>
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <style>
    body { font-family: Arial, Helvetica, sans-serif; background:#f3f4f6; margin:0; padding:40px; display:flex; align-items:center; justify-content:center; min-height:100vh; }
    .open-btn { background:#06b6d4; color:#fff; border:none; padding:12px 18px; border-radius:8px; cursor:pointer; box-shadow:0 6px 18px rgba(2,6,23,0.08); font-weight:600; }
    .modal { display:none; position:fixed; left:0; top:0; right:0; bottom:0; background:rgba(0,0,0,0.45); z-index:1000; align-items:center; justify-content:center; padding:20px; }
    .modal-box { width:100%; max-width:420px; background:#fff; border-radius:10px; overflow:hidden; box-shadow:0 20px 50px rgba(2,6,23,0.16); transform-origin:center center; animation-duration:320ms; animation-timing-function:cubic-bezier(.2,.9,.3,1); }
    .modal-header { padding:20px; border-bottom:1px solid #eef2f7; background:#ffffff; }
    .modal-header h2 { margin:0; font-size:18px; color:#0f172a; }
    .modal-body { padding:18px 20px; }
    .field { margin-bottom:12px; }
    label { display:block; font-size:14px; color:#334155; margin-bottom:6px; }
    input[type="text"], input[type="password"] { width:100%; padding:10px 12px; border:1px solid #e6e9ef; border-radius:8px; font-size:15px; box-sizing:border-box; }
    .modal-footer { padding:16px 20px; border-top:1px solid #eef2f7; display:flex; gap:10px; }
    .btn { flex:1; padding:10px 12px; border-radius:8px; border:none; cursor:pointer; font-weight:600; }
    .btn-ghost { background:#f8fafc; color:#0f172a; border:1px solid #e6e9ef; }
    .btn-primary { background:#06b6d4; color:#fff; }
    .close-x { position:absolute; right:14px; top:12px; font-size:20px; color:#475569; cursor:pointer; }
    @keyframes zoomIn { from { transform: scale(.92); opacity:0.0; } 60% { transform: scale(1.03); opacity:1; } to { transform: scale(1); opacity:1; } }
    .zoom-in { animation-name: zoomIn; }
    @media (max-width:420px) { .modal-box { width: 100%; border-radius:8px; margin:8px; } }
    .err { padding:8px 20px; color:#b91c1c; background:#fee2e2; border-bottom:1px solid #fecaca; }
  </style>
</head>
<body>

  <button class="open-btn" id="openLogin">Open Login</button>

  <div id="loginModal" class="modal" role="dialog" aria-modal="true" aria-labelledby="loginTitle">
    <div class="modal-box" id="modalBox" style="position:relative;">
      <span class="close-x" id="closeX" title="Close">&times;</span>

      <div class="modal-header">
        <h2 id="loginTitle">Sign in</h2>
      </div>

      <% String err = (String) request.getAttribute("loginError"); %>
      <% if (err != null) { %>
        <div class="err"><%= err %></div>
      <% } %>

      <form class="modal-body" action="<%= request.getContextPath() %>/login" method="post" id="loginForm">
        <div class="field">
          <label for="uname">Username</label>
          <input id="uname" name="uname" type="text" placeholder="Enter username" autocomplete="username" required />
        </div>

        <div class="field">
          <label for="psw">Password</label>
          <input id="psw" name="psw" type="password" placeholder="Enter password" autocomplete="current-password" required />
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-ghost" id="cancelBtn">Cancel</button>
          <button type="submit" class="btn btn-primary">Sign in</button>
        </div>
      </form>
    </div>
  </div>

  <script>
    (function () {
      var openBtn   = document.getElementById('openLogin');
      var modal     = document.getElementById('loginModal');
      var modalBox  = document.getElementById('modalBox');
      var closeX    = document.getElementById('closeX');
      var cancelBtn = document.getElementById('cancelBtn');

      function openModal() {
        modal.style.display = 'flex';
        modalBox.classList.remove('zoom-in');
        void modalBox.offsetWidth; /* restart animation */
        modalBox.classList.add('zoom-in');
      }
      function closeModal() { modal.style.display = 'none'; }

      openBtn.addEventListener('click', openModal);
      closeX.addEventListener('click', closeModal);
      cancelBtn.addEventListener('click', closeModal);
      window.addEventListener('click', function (e) { if (e.target === modal) closeModal(); });
      window.addEventListener('keydown', function (e) { if (e.key === 'Escape' && modal.style.display === 'flex') closeModal(); });

      /* Do not hide modal on submit; allow navigation per servlet response */
      /* document.getElementById('loginForm').addEventListener('submit', function(){ modal.style.display='none'; }); */

      /* Auto-open if there was an error from the servlet */
      <% boolean openNow = (request.getAttribute("loginError") != null); %>
      if (<%= openNow ? "true" : "false" %>) {
        openModal();
      }
    }());
  </script>

</body>
</html>
