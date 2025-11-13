<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<meta charset="UTF-8" />
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="ISO-8859-1" />
  <title>Register</title>
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  
  <!-- External Stylesheet -->
  <link rel="stylesheet" href="css/auth.css">
</head>
<body>

  <button class="open-btn" id="openRegister">Open Registration</button>

  <div id="registerModal" class="modal" role="dialog" aria-modal="true" aria-labelledby="registerTitle">
    <div class="modal-box" id="modalBox" style="position:relative;">
      <span class="close-x" id="closeX" title="Close">&times;</span>

      <div class="modal-header">
        <h2 id="registerTitle">Create Account</h2>
      </div>

      <% String err = (String) request.getAttribute("registerError"); %>   
      <% if (err != null) { %>
        <div class="err"><%= err %></div>
      <% } %>

      <% String success = (String) request.getAttribute("registerSuccess"); %>   
      <% if (success != null) { %>
        <div class="success"><%= success %></div>
      <% } %>

      <form class="modal-body" action="<%= request.getContextPath() %>/register" method="post" id="registerForm">
        <div class="field">
          <label for="uname">Username</label>
          <input id="uname" name="uname" type="text" placeholder="Choose a username" autocomplete="username" required />
        </div>

        <div class="field">
          <label for="psw">Password</label>
          <input id="psw" name="psw" type="password" placeholder="Enter password" autocomplete="new-password" required />
        </div>

        <div class="field">
          <label for="psw2">Confirm Password</label>
          <input id="psw2" name="psw2" type="password" placeholder="Confirm password" autocomplete="new-password" required />
        </div>
        
        <div class="field">
          <label for="zip">Enter zip code</label>
          <input id="zip" name="zip" type="text" placeholder="Enter zip code" required />
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-ghost" id="cancelBtn">Cancel</button>
          <button type="submit" class="btn btn-primary">Register</button>
        </div>
      </form>
    </div>
  </div>

  <script>
    (function () {
      var openBtn   = document.getElementById('openRegister');
      var modal     = document.getElementById('registerModal');
      var modalBox  = document.getElementById('modalBox');
      var closeX    = document.getElementById('closeX');
      var cancelBtn = document.getElementById('cancelBtn');

      function openModal() {
        modal.style.display = 'flex';
        modalBox.classList.remove('zoom-in');
        void modalBox.offsetWidth; 
        modalBox.classList.add('zoom-in');
      }
      function closeModal() { modal.style.display = 'none'; }

      openBtn.addEventListener('click', openModal);
      closeX.addEventListener('click', closeModal);
      cancelBtn.addEventListener('click', closeModal);
      window.addEventListener('click', function (e) { if (e.target === modal) closeModal(); });
      window.addEventListener('keydown', function (e) { if (e.key === 'Escape' && modal.style.display === 'flex') closeModal(); });

      <% boolean openNow = (request.getAttribute("registerError") != null || request.getAttribute("registerSuccess") != null); %>
      if (<%= openNow ? "true" : "false" %>) {
        openModal();
      }
    }());
  </script>

</body>
</html>
