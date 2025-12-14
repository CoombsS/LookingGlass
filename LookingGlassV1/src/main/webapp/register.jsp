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

        <div class="field">
          <label>Face Recognition (Optional)</label>
          <button type="button" class="btn btn-primary" id="captureFaceBtn" style="width:100%; margin-bottom:10px;">
            Capture Face (1/3)
          </button>
          <div id="faceStatus" style="font-size:14px; color:#64748b; text-align:center;"></div>
          <div id="faceProgress" style="font-size:12px; color:#64748b; text-align:center; margin-top:5px;"></div>
          <input type="hidden" id="faceData" name="faceData" />
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
      var captureFaceBtn = document.getElementById('captureFaceBtn');
      var faceStatus = document.getElementById('faceStatus');
      var faceProgress = document.getElementById('faceProgress');
      var faceDataInput = document.getElementById('faceData');
      
      var capturedFaces = [];
      var captureCount = 0;
      var totalCaptures = 3;

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

      // Face capture functionality - capture 3 times
      captureFaceBtn.addEventListener('click', function() {
        faceStatus.textContent = 'Capturing face ' + (captureCount + 1) + '...';
        faceStatus.style.color = '#3b82f6';
        captureFaceBtn.disabled = true;
        
        fetch('http://localhost:5004/capture-face', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' }
        })
        .then(response => response.json())
        .then(data => {
          if (data.success && data.face_data) {
            capturedFaces.push(data.face_data);
            captureCount++;
            
            if (captureCount < totalCaptures) {
              faceStatus.textContent = 'Face ' + captureCount + ' captured! Please capture again.';
              faceStatus.style.color = '#10b981';
              faceProgress.textContent = 'Progress: ' + captureCount + '/' + totalCaptures;
              captureFaceBtn.textContent = 'Capture Face (' + (captureCount + 1) + '/3)';
              captureFaceBtn.disabled = false;
            } else {
              // All 3 faces captured
              faceDataInput.value = JSON.stringify(capturedFaces);
              faceStatus.textContent = 'All 3 faces captured successfully!';
              faceStatus.style.color = '#10b981';
              faceProgress.textContent = 'Complete: 3/3';
              captureFaceBtn.textContent = 'Re-capture Faces';
              captureFaceBtn.disabled = false;
              
              // Allow re-capturing by resetting
              captureFaceBtn.addEventListener('click', function resetCapture() {
                capturedFaces = [];
                captureCount = 0;
                faceDataInput.value = '';
                faceStatus.textContent = '';
                faceProgress.textContent = '';
                captureFaceBtn.textContent = 'Capture Face (1/3)';
                captureFaceBtn.removeEventListener('click', resetCapture);
              }, { once: true });
            }
          } else {
            faceStatus.textContent = 'Error: ' + (data.error || 'Failed to capture face');
            faceStatus.style.color = '#ef4444';
            captureFaceBtn.disabled = false;
          }
        })
        .catch(error => {
          faceStatus.textContent = 'Error: ' + error.message;
          faceStatus.style.color = '#ef4444';
          captureFaceBtn.disabled = false;
        });
      });

    }());
  </script>

</body>
</html>
