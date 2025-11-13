package lookingGlass;

import javax.servlet.http.*;
import java.io.IOException;
// Logout servlet for later use.
//Also untested, basically a copy of LoginServlet with relevant changes so could work, most likely not knowing me though
public class LogoutServlet extends HttpServlet {
    private static final String ENC = "UTF-8";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding(ENC);
        resp.setCharacterEncoding(ENC);
        resp.setContentType("text/html; charset=" + ENC);

        HttpSession s = req.getSession(false);
        if (s != null) s.invalidate();
        resp.sendRedirect(req.getContextPath() + "/login.jsp");
    }
}
