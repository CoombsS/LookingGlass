package lookingGlass;

import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
// THIS SHOULD NOT ACTUALLY RUN OR BE USED, LEAVING FOR NOW
public class Auth implements Filter {
    @Override public void init(FilterConfig filterConfig) {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req  = (HttpServletRequest) request;
        HttpServletResponse resp= (HttpServletResponse) response;

        String path = req.getRequestURI().substring(req.getContextPath().length());
        System.out.println("Filter - Full URI: " + req.getRequestURI());
        System.out.println("Filter - Context Path: " + req.getContextPath());
        System.out.println("Filter - Processed Path: " + path);

        //Allow pages
        boolean open =
            path.equals("/") ||
            path.equals("/login") ||
            path.equals("/login.jsp") ||
            path.equals("/journal.jsp") ||    
            path.equals("/journal/save") ||
            path.equals("/chat.jsp") ||
            path.equals("/chat/save")  ||
            path.startsWith("/css/") || path.startsWith("/js/") || path.startsWith("/images/") ||
            path.equals("/error.jsp");

        if (open) {
            chain.doFilter(request, response);
            return;
        }

        HttpSession s = req.getSession(false); 
        System.out.println("Auth Filter - Session: " + (s != null ? "exists" : "null")); // Debugging statements
        System.out.println("Auth Filter - UID: " + (s != null ? s.getAttribute("uid") : "null")); 
        System.out.println("Auth Filter - Session ID: " + (s != null ? s.getId() : "null")); 
        
        if (s != null && s.getAttribute("uid") != null) { 
            System.out.println("Auth Filter - User authenticated, proceeding..."); // Debugging
            chain.doFilter(request, response);
        } else {
            System.out.println("Auth Filter - User not authenticated, redirecting to login");
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
        }
    }

    @Override public void destroy() {}
}
