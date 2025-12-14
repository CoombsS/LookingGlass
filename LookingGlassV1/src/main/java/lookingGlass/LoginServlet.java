package lookingGlass;
import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
public class LoginServlet extends HttpServlet {
    private static final String ENC = "UTF-8";
    private static final String FACE_AUTH_ = "FACE_AUTH_";
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
        
        // Check if this is a face authentication login
        boolean isFaceAuth = password.startsWith(FACE_AUTH_);
        
        String sql;
        if (isFaceAuth) {
            sql = "SELECT uid, username FROM users WHERE username = ? LIMIT 1";
        } else {
            sql = "SELECT uid, username FROM users WHERE username = ? AND BINARY RTRIM(password) = BINARY ? LIMIT 1";
        }
        
        try (java.sql.Connection con = Db.getConnection();
             java.sql.PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username.trim());
            if (!isFaceAuth) {
                ps.setString(2, password);
            }
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
            
            // Get the originally requested URL from the session, default to journal.jsp if none
            String requestedUrl = (String) session.getAttribute("requested_url");
            if (requestedUrl == null) {
                requestedUrl = req.getContextPath() + "/journal.jsp";
            }
            session.removeAttribute("requested_url"); // Clear it after use
            
            String target = resp.encodeRedirectURL(requestedUrl);
            resp.sendRedirect(target);
        } catch (java.sql.SQLException e) {
            req.setAttribute("loginError", "Database error: " + e.getMessage());
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
        }
    }
}
