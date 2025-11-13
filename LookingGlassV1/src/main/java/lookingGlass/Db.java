package lookingGlass;

import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public final class Db {
    private Db() {}

    // AI DISCLAIMER: ChatGPT helped me with this, because the templates I found wouldn't work
    private static final String FALLBACK_URL =
        "jdbc:mysql://localhost:3306/lookingglass?useUnicode=true&characterEncoding=UTF-8&serverTimezone=America/Chicago&allowPublicKeyRetrieval=true&useSSL=false";
    private static final String FALLBACK_USER = "root";
    private static final String FALLBACK_PASS = "";

    public static Connection getConnection() throws SQLException {
        try {
            InitialContext ic = new InitialContext();
            DataSource ds = (DataSource) ic.lookup("java:comp/env/jdbc/LookingGlassDB");
            if (ds != null) {
                return ds.getConnection();
            }
        } catch (NamingException ignore) {
            // fall through to direct DriverManager connection
        }

        // Fallback direct connection
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException ignore) {
            // modern drivers auto-register; safe to ignore
        }
        return DriverManager.getConnection(FALLBACK_URL, FALLBACK_USER, FALLBACK_PASS);
    }
}
