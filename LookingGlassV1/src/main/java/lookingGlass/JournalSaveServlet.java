package lookingGlass;
import javax.servlet.ServletException;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;
import java.net.HttpURLConnection;
import java.net.URL;
import java.io.OutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;


public class JournalSaveServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        resp.sendRedirect(req.getContextPath() + "/login.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        System.out.println("JournalSaveServlet - RequestURI: " + req.getRequestURI() + " ContextPath: " + req.getContextPath());

        // Get user ID
        String uidParam = nvl(req.getParameter("uid"));
        if (uidParam.isEmpty()) throw new ServletException("Missing uid.");
        final int uid;
        try {
            uid = Integer.parseInt(uidParam.trim());
        } catch (NumberFormatException ex) {
            throw new ServletException("Bad uid format: " + uidParam, ex);
        }

        // Check if this is a gratitude submission
        String section = nvl(req.getParameter("section"));
        String saveGratitude = req.getParameter("saveGratitude");
        
        if ("gratitude".equals(section) && "1".equals(saveGratitude)) {
            handleGratitudeSubmission(req, resp, uid);
            return;
        }

        // Getting form fields (nvl = null value)
        String title    = nvl(req.getParameter("title"));
        String dateStr  = nvl(req.getParameter("date"));    
        String timeStr  = nvl(req.getParameter("time"));    
        String entry    = nvl(req.getParameter("entry"));
        String w1       = nvl(req.getParameter("whatWentWell"));
        String w2 = nvl(req.getParameter("whatCouldBeBetter"));
        String tagsJson = nvl(req.getParameter("tagsJson"));
        String mood = nvl(req.getParameter("mood"));
        String moodDb = mood.isEmpty() ? null : mood;

        // dealing with tag JSON format (Thank God for ChatGPT cause this sucks)
        if (tagsJson.isEmpty()) {
            String tags = req.getParameter("tags");
            if (tags != null && !tags.trim().isEmpty()) {
                String[] parts = tags.split(",");
                StringBuilder sb = new StringBuilder("[");
                for (String p : parts) {
                    String t = p.trim();
                    if (!t.isEmpty()) {
                        if (sb.length() > 1) sb.append(',');
                        sb.append('"').append(t.replace("\"", "\\\"")).append('"');
                    }
                }
                sb.append(']');
                tagsJson = sb.toString();
            } else {
                tagsJson = "[]";
            }
        }

        // Normalizing 
        if (title.isEmpty()) title = "(untitled)";
        // Leave data NULL initially - sentiment service will populate with key phrases

        // Date+Time parsing
        LocalDate ld = dateStr.isEmpty() ? LocalDate.now() : LocalDate.parse(dateStr);
        if (timeStr.matches("^\\d{2}:\\d{2}$")) timeStr += ":00";
        LocalTime lt = timeStr.isEmpty()
                ? LocalTime.now().withSecond(0).withNano(0)
                : LocalTime.parse(timeStr);
        LocalDateTime ldt = LocalDateTime.of(ld, lt);

        // Sends to DB then the sentiment api
        final String sql =
            "INSERT INTO journals " +
            "(`uid`, `title`, `data`, `time`, `whatWentWell`, `whatCouldBeBetter`, `userGivenMood`, `tags`, `entry`, `sentiment`) " +
            "VALUES (?, ?, NULL, ?, ?, ?, ?, CAST(? AS JSON), ?, NULL)";
        int insertedId = -1;
        try (Connection c = Db.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            //prepared statements to avoid sql injection
            int i = 1;
            ps.setInt(i++, uid);
            ps.setString(i++, title);
            // Skip data field - left as NULL for sentiment service to populate
            ps.setTimestamp(i++, Timestamp.valueOf(ldt));
            ps.setString(i++, w1);
            ps.setString(i++, w2);
            if (moodDb == null) {
                ps.setNull(i++, Types.VARCHAR);
            } else {
                ps.setString(i++, moodDb);
            }
            ps.setString(i++, tagsJson);
            ps.setString(i++, entry);

            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs != null && rs.next()) {
                    insertedId = rs.getInt(1);
                }
            }

        } catch (SQLException e) {
            throw new ServletException("Failed to save journal: " + e.getMessage(), e);
        }

        // uid and journal id passed to sentiment api
        //try/catch to make sure something happened and if not it wont get hung up
        try {
            callSentimentService(uid, insertedId);
        } catch (Exception ex) {
            System.err.println("Warning: failed to call sentiment service: " + ex.getMessage());
        }

        // If we reach here, success and redirect back to journal
        String target = resp.encodeRedirectURL(req.getContextPath() + "/journal.jsp?ok=1");
        resp.sendRedirect(target);
    }

    private void handleGratitudeSubmission(HttpServletRequest req, HttpServletResponse resp, int uid) 
            throws ServletException, IOException {
        
        // Get gratitude fields
        String timeStr = nvl(req.getParameter("time"));
        String g1 = nvl(req.getParameter("g1"));
        String g2 = nvl(req.getParameter("g2"));
        String g3 = nvl(req.getParameter("g3"));
        String g4 = nvl(req.getParameter("g4"));
        String g5 = nvl(req.getParameter("g5"));
        
        // Convert time format
        if (timeStr.matches("^\\d{2}:\\d{2}$")) {
            timeStr += ":00";
        }
        if (timeStr.isEmpty()) {
            LocalTime lt = LocalTime.now().withSecond(0).withNano(0);
            timeStr = lt.toString();
        }
        
        // Insert into database (I fixed this, was taking in wrong parameter names)
        final String sql = "INSERT INTO gratitudes (uid, time, g1, g2, g3, g4, g5, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())";
        
        try (Connection c = Db.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            
            ps.setInt(1, uid);
            ps.setString(2, timeStr);
            ps.setString(3, g1.isEmpty() ? null : g1);
            ps.setString(4, g2.isEmpty() ? null : g2);
            ps.setString(5, g3.isEmpty() ? null : g3);
            ps.setString(6, g4.isEmpty() ? null : g4);
            ps.setString(7, g5.isEmpty() ? null : g5);
            
            ps.executeUpdate();
            
        } catch (SQLException e) {
            throw new ServletException("Failed to save gratitude: " + e.getMessage(), e);
        }
        
        // Redirect back to journal
        String target = resp.encodeRedirectURL(req.getContextPath() + "/journal.jsp?gratitude=saved");
        resp.sendRedirect(target);
    }
    private static String nvl(String s) { return (s == null) ? "" : s.trim(); }

    // Sentiment api called
    private void callSentimentService(int uid, int journalId) {
        try {
            URL url = new URL("http://127.0.0.1:5000/sentiment");
            HttpURLConnection con = (HttpURLConnection) url.openConnection();
            con.setRequestMethod("POST");
            con.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            con.setDoOutput(true);
            con.setConnectTimeout(3000); //chat recommended this, and it seems good so its here
            con.setReadTimeout(3000);

            // formating and transmitting 
            String payload = String.format("{\"uid\":%d,\"journalId\":%d}", uid, journalId);
            byte[] out = payload.getBytes(StandardCharsets.UTF_8);
            con.setFixedLengthStreamingMode(out.length);
            try (OutputStream os = con.getOutputStream()) {
                os.write(out);
            }

            // response handling (again, chat recommended this and i dont think it hurts. Discards the body of the response b/c not needed)
            int code = con.getResponseCode();
            if (code < 200 || code >= 300) {
                System.err.println("callSentimentService returned HTTP code: " + code);
            }
            try (InputStream is = (code >= 200 && code < 300) ? con.getInputStream() : con.getErrorStream()) {
                if (is != null) {
                    byte[] buf = new byte[256];
                    while (is.read(buf) > 0) { /* discard */ }
                }
            }

        } catch (Exception e) {
            System.err.println("callSentimentService error: " + e.getMessage());
        }
    }
}