package lookingGlass;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
//UNTESTED, BASICALLY A COPY OF JournalSaveServlet WITH RELEVANT CHANGES SO COULD WORK, PROBABLY NOT
public class LoginServlet extends HttpServlet {
    private static final String ENC = "UTF-8";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        req.setCharacterEncoding(ENC);
        resp.setCharacterEncoding(ENC);
        resp.setContentType("text/html; charset=" + ENC);
        req.getRequestDispatcher("/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {

        req.setCharacterEncoding(ENC);
        resp.setCharacterEncoding(ENC);
        resp.setContentType("text/html; charset=" + ENC);

        String username = req.getParameter("uname");
        String password = req.getParameter("psw");

        if (username == null || password == null || username.isEmpty() || password.isEmpty()) {
            req.setAttribute("loginError", "Please enter both username and password.");
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
            return;
        }

        String sql = "SELECT uid, username FROM users " +
                     "WHERE username = ? AND BINARY RTRIM(password) = BINARY ? LIMIT 1";

        try (java.sql.Connection con = Db.getConnection();
             java.sql.PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, username.trim());
            ps.setString(2, password);

            Integer dbUid = null;
            String dbUser = null;

            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    dbUid = rs.getInt("uid");
                    dbUser = rs.getString("username");
                } else {
                    req.setAttribute("loginError", "Invalid username or password.");
                    req.getRequestDispatcher("/login.jsp").forward(req, resp);
                    return;
                }
            }

            HttpSession old = req.getSession(false);
            if (old != null) old.invalidate();

            HttpSession session = req.getSession(true);
            session.setAttribute("uid", dbUid);      
            session.setAttribute("username", dbUser); 

            String target = resp.encodeRedirectURL(req.getContextPath() + "/journal.jsp");
            resp.sendRedirect(target);
        } catch (java.sql.SQLException e) {
            req.setAttribute("loginError", "Database error: " + e.getMessage());
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
        }
    }
}
