package lookingGlass;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.*;

public class RegisterServlet extends HttpServlet {
    private static final String ENC = "UTF-8";

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
                    "INSERT INTO users (username, password) VALUES (?, ?)", Statement.RETURN_GENERATED_KEYS)) {
                ins.setString(1, username);
                ins.setString(2, password);
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
}
