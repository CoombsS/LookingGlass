package lookingGlass;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;


@WebFilter("/*")
public class Auth implements Filter {
    @Override public void init(FilterConfig filterConfig) { /* no-op */ }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req  = (HttpServletRequest) request;
        HttpServletResponse resp= (HttpServletResponse) response;

        String ctx  = req.getContextPath();                 // ex /LookingGlassV1
        String uri  = req.getRequestURI();                  // ex /LookingGlassV1/chat.jsp
        String path = uri.substring(ctx.length());          // ex /chat.jsp
        if (path.isEmpty()) path = "/";

        System.out.println("Filter - Full URI: " + uri);
        System.out.println("Filter - Context Path: " + ctx);
        System.out.println("Filter - Processed Path: " + path);

        boolean open =
            path.equals("/") ||
            path.equals("/login") ||
            path.equals("/login.jsp") ||
            path.equals("/journal.jsp") ||
            path.equals("/journal/save") ||
            path.equals("/chat.jsp") ||
            path.equals("/chat/save") ||
            path.startsWith("/css/") || path.startsWith("/js/") || path.startsWith("/images/") ||
            path.equals("/error.jsp");

        if (open) {
            chain.doFilter(request, response);
            return;
        }

        HttpSession s = req.getSession(false);
        System.out.println("Auth Filter - Session: " + (s != null ? "exists" : "null"));
        System.out.println("Auth Filter - UID: " + (s != null ? s.getAttribute("uid") : "null"));
        System.out.println("Auth Filter - Session ID: " + (s != null ? s.getId() : "null"));

        if (s != null && s.getAttribute("uid") != null) {
            System.out.println("Auth Filter - User authenticated, proceeding...");
            chain.doFilter(request, response);
        } else {
            System.out.println("Auth Filter - User not authenticated, redirecting to login");
            resp.sendRedirect(ctx + "/login.jsp");
        }
    }

    @Override public void destroy() {}
}
