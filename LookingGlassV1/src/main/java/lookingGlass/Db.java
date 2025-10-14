package lookingGlass;

public final class Db {
    private Db() {}
    // AI DISCLAIMER: ChatGPT helped me with this, because the templates I found woudlnt work
    private static final String FALLBACK_URL =
        "jdbc:mysql://localhost:3306/lookingglass?useUnicode=true&characterEncoding=UTF-8&serverTimezone=America/Chicago&allowPublicKeyRetrieval=true&useSSL=false";
    private static final String FALLBACK_USER = "root";
    private static final String FALLBACK_PASS = "";

    public static java.sql.Connection getConnection() throws java.sql.SQLException {
        try {
            javax.naming.InitialContext ic = new javax.naming.InitialContext();
            javax.sql.DataSource ds = (javax.sql.DataSource) ic.lookup("java:comp/env/jdbc/LookingGlassDB");
            if (ds != null) {
                return ds.getConnection();
            }
        } catch (javax.naming.NamingException ignore) {}

        // Fallback
        try { Class.forName("com.mysql.cj.jdbc.Driver"); } catch (ClassNotFoundException ignore) {}
        return java.sql.DriverManager.getConnection(FALLBACK_URL, FALLBACK_USER, FALLBACK_PASS);
    }
}
