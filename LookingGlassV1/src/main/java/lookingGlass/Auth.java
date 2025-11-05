package lookingGlass;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

public class Auth implements Filter {
    @Override 
    public void init(FilterConfig filterConfig) { 

    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

    HttpServletRequest req = (HttpServletRequest) request;
    HttpServletResponse resp = (HttpServletResponse) response;

    String ctx  = req.getContextPath();                 // ex /LookingGlassV1
    String uri  = req.getRequestURI();                  // ex /LookingGlassV1/chat.jsp;jsessionid=ABC
    String path = uri.substring(ctx.length());          // ex /chat.jsp;jsessionid=ABC
    if (path.isEmpty()) path = "/";
    int scIdx = path.indexOf(';');
    if (scIdx != -1) path = path.substring(0, scIdx);
    int qmIdx = path.indexOf('?');
    if (qmIdx != -1) path = path.substring(0, qmIdx);

        boolean open =
            path.equals("/login") ||
            path.equals("/login.jsp") ||
            path.equals("/register") ||
            path.equals("/register.jsp") ||
            path.equals("/logout") ||
            path.startsWith("/css/") || path.startsWith("/js/") || path.startsWith("/images/") ||
            path.equals("/error.jsp");

        if (path.endsWith(".jsp") && !path.equals("/login.jsp") && !path.equals("/register.jsp") && !path.equals("/error.jsp")) {
            open = false;
        }

        if (open) {
            chain.doFilter(request, response);
            return;
        }

        HttpSession s = req.getSession(false);
        if (s != null && s.getAttribute("uid") != null) {
            chain.doFilter(request, response);
        } else {
            resp.sendRedirect(ctx + "/login.jsp");
        }
    }

    @Override public void destroy() {}
}
