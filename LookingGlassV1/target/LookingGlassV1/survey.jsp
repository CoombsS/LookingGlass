<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Mood Survey</title>
  <style>
    body {
      margin: 0;
      font-family: Arial, sans-serif;
      display: flex;
      min-height: 100vh;
    }
    .content {
      flex: 1;
      padding: 2rem;
    }
  </style>
</head>
<body>
  <%@ include file="/WEB-INF/displayUser.jspf" %>
<%@ include file="/WEB-INF/drawer.jspf" %>

  <div class="content">
    <h1>How are you feeling today?</h1>
    <form action="results.jsp" method="get">
      <div class="mood-options">
        <label><input type="radio" name="mood" value="Very Bad"> Very Bad</label>
        <label><input type="radio" name="mood" value="Bad"> Bad</label>
        <label><input type="radio" name="mood" value="Neutral"> Neutral</label>
        <label><input type="radio" name="mood" value="Good"> Good</label>
        <label><input type="radio" name="mood" value="Excellent"> Excellent</label>
      </div>
      <button type="submit">Submit</button>
    </form>
  </div>

</body>
</html>
