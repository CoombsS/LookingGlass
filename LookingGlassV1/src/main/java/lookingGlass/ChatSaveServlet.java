package lookingGlass;
// THIS IS UNTESTED, BASICALLY A COPY OF JournalSaveServlet WITH RELEVANT CHANGES
import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

public class ChatSaveServlet extends HttpServlet {
    private static final String ENC = "UTF-8";

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {

        req.setCharacterEncoding(ENC);
        resp.setCharacterEncoding(ENC);
        resp.setContentType("text/html; charset=" + ENC);

        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("uid") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }
        String uid = String.valueOf(s.getAttribute("uid")); 
        String text = req.getParameter("text");
        if (text == null || text.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/results.jsp?ok=0&msg=empty");
            return;
        }

        // Saving to DB
        String sql = "INSERT INTO Chats (uid, message, created_at) VALUES (?, ?, NOW())";

        try (Connection c = Db.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, uid);
            ps.setString(2, text);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new ServletException("Failed to save chat: " + e.getMessage(), e);
        }
        resp.sendRedirect(req.getContextPath() + "/results.jsp?ok=1");
    }
}
