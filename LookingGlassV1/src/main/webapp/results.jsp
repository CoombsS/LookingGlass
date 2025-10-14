<%@ page language="java"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Results</title>
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
    <%
      String mood = request.getParameter("mood");
      if (mood != null) {
        out.print("<h2>Your mood is: " + mood + "</h2>");
      } else {
        out.print("<h2>No mood selected.</h2>");
      }
    %>
  </div>

</body>
</html>
