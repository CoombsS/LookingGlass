<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<meta charset="UTF-8" />
<!DOCTYPE html>
<html lang="en">
<head>
  <!-- DISCLAIMER: THIS WAS GOTTEN FROM I THINK W3 SCHOOLS LOGIN TEMPLATES-->
  <meta charset="ISO-8859-1" />
  <title>Login</title>
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  
  <!-- External Stylesheet -->
  <link rel="stylesheet" href="css/auth.css">
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

        <div class="field" style="text-align:center; margin-top:10px;">
          <button type="button" class="btn btn-primary" id="faceLoginBtn" style="width:100%; background-color:#06b6d4;">
            Login with Face
          </button>
          <div id="faceStatus" style="font-size:14px; color:#64748b; margin-top:8px;"></div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-ghost" id="cancelBtn">Cancel</button>
          <button type="submit" class="btn btn-primary">Sign in</button>
        </div>
        <div style="padding:0 20px 20px; text-align:center;">
          <span style="color:#64748b; font-size:14px;">Don't have an account? </span>
          <a href="<%= request.getContextPath() %>/register.jsp" style="color:#06b6d4; font-weight:600; text-decoration:none;">Register here</a>
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
      var faceLoginBtn = document.getElementById('faceLoginBtn');
      var faceStatus = document.getElementById('faceStatus');
      var loginForm = document.getElementById('loginForm');

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

      // Face login functionality; fills in fields when recognized
      faceLoginBtn.addEventListener('click', function() {
        faceStatus.textContent = 'Capturing face...';
        faceStatus.style.color = '#3b82f6';
        
        fetch('http://localhost:5004/capture-face', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' }
        })
        .then(response => response.json())
        .then(data => {
          if (data.success && data.face_data) {
            faceStatus.textContent = 'Verifying face...';
            return fetch('http://localhost:5004/verify-face', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ face_data: data.face_data })
            });
          } else {
            throw new Error(data.error || 'Failed to capture face');
          }
        })
        .then(response => response.json())
        .then(data => {
          if (data.success && data.recognized && data.username) {
            faceStatus.textContent = 'Recognized as ' + data.username + 'Logging in...';
            faceStatus.style.color = '#10b981';
            
            // Auto-fill username and submit form
            document.getElementById('uname').value = data.username;
            document.getElementById('psw').value = 'FACE_AUTH_' + data.username;
            
            setTimeout(function() {
              loginForm.submit();
            }, 1000);
          } else {
            faceStatus.textContent = 'Face not recognized. Please use password login.';
            faceStatus.style.color = '#ef4444';
          }
        })
        .catch(error => {
          faceStatus.textContent = 'Error: ' + error.message;
          faceStatus.style.color = '#ef4444';
        });
      });

    }());
  </script>

</body>
</html>
