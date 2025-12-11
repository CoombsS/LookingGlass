package lookingGlass;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import org.json.JSONObject;

public class RegisterServlet extends HttpServlet {
    private static final String ENC = "UTF-8";
    private static final String FACE_SERVICE_URL = "http://localhost:5004/learn-face";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        req.setCharacterEncoding(ENC);
        resp.setCharacterEncoding(ENC);
        resp.setContentType("text/html; charset=" + ENC);
        req.getRequestDispatcher("/register.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        req.setCharacterEncoding(ENC);
        resp.setCharacterEncoding(ENC);
        resp.setContentType("text/html; charset=" + ENC);

        String username = trim(req.getParameter("uname"));
        String password = req.getParameter("psw");
        String password2 = req.getParameter("psw2");

        // Basic validation
        if (isEmpty(username) || isEmpty(password) || isEmpty(password2)) {
            req.setAttribute("registerError", "Please fill out all required fields.");
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }
        if (!password.equals(password2)) {
            req.setAttribute("registerError", "Passwords do not match.");
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        try (Connection con = Db.getConnection()) {
            try (PreparedStatement check = con.prepareStatement("SELECT 1 FROM users WHERE username = ? LIMIT 1")) {
                check.setString(1, username);
                try (ResultSet rs = check.executeQuery()) {
                    if (rs.next()) {
                        req.setAttribute("registerError", "That username is already taken.");
                        req.getRequestDispatcher("/register.jsp").forward(req, resp);
                        return;
                    }
                }
            }

            int newUid = -1;
            try (PreparedStatement ins = con.prepareStatement(
                    "INSERT INTO users (username, password, zip) VALUES (?, ?, ?)", Statement.RETURN_GENERATED_KEYS)) {
                ins.setString(1, username);
                ins.setString(2, password);
                ins.setString(3, req.getParameter("zip"));
                int affected = ins.executeUpdate();
                if (affected == 0) {
                    req.setAttribute("registerError", "Could not create account. Please try again.");
                    req.getRequestDispatcher("/register.jsp").forward(req, resp);
                    return;
                }
                try (ResultSet keys = ins.getGeneratedKeys()) {
                    if (keys.next()) newUid = keys.getInt(1);
                }
            }

            HttpSession old = req.getSession(false);
            if (old != null) old.invalidate();
            HttpSession session = req.getSession(true);
            session.setAttribute("uid", newUid);
            session.setAttribute("username", username);

            // Handling face data if passed
            String faceData = req.getParameter("faceData");
            if (faceData != null && !faceData.trim().isEmpty()) {
                try {
                    learnFace(username, faceData);
                } catch (Exception e) {
                    //Error logging only; do not block registration
                    System.err.println("Failed to learn face for user " + username + ": " + e.getMessage());
                }
            }

            resp.sendRedirect(resp.encodeRedirectURL(req.getContextPath() + "/journal.jsp"));
        } catch (SQLException e) {
            req.setAttribute("registerError", "Database error: " + e.getMessage());
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
        }
    }

    private static boolean isEmpty(String s) {
        return s == null || s.trim().isEmpty();
    }
    private static String trim(String s) { return s == null ? null : s.trim(); }
    //Send to service to learn face data (pretty much copy pasted from previous project)
    private void learnFace(String username, String faceData) throws Exception {
        URL url = new URL(FACE_SERVICE_URL);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setDoOutput(true);

        String jsonPayload = String.format("{\"username\":\"%s\",\"face_data\":\"%s\"}", 
            username.replace("\"", "\\\""), 
            faceData.replace("\"", "\\\""));

        try (OutputStream os = conn.getOutputStream()) {
            byte[] input = jsonPayload.getBytes(StandardCharsets.UTF_8);
            os.write(input, 0, input.length);
        }

        int responseCode = conn.getResponseCode();
        if (responseCode != 200) {
            throw new IOException("Face service returned code: " + responseCode);
        }
    }
}
