package lookingGlass;
// THIS IS UNUSED, DELETED FROM WEB.XML, RESTAPI HANDELS CHAT SAVING NOW
//KEPT ONLY FOR REFERENCE IF NEEDED LATER
import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

public class ChatSaveServlet extends HttpServlet {
    private static final String ENC = "UTF-8";

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {

        req.setCharacterEncoding(ENC);//I was getting errors without the encoding being set, so here it is even though I am not sure if needed
        resp.setCharacterEncoding(ENC); //same with this.
        resp.setContentType("text/html; charset=" + ENC); //and with this. 

        HttpSession s = req.getSession(false);  
        if (s == null || s.getAttribute("uid") == null) {   //if no session or no user associated with session, redirect to login
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }
        String uid = String.valueOf(s.getAttribute("uid")); //get user id from session
        String text = req.getParameter("text");
        if (text == null || text.isBlank()) {   //if no text provided, redirect with error
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
