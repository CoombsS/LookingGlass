<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"  uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>

<!DOCTYPE html>
<!--
  AI USAGE DISCLAIMER
  ALL STYLING ON THIS PAGE IS AI-GENERATED TO SPEED UP FRONTEND WORK.
-->
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Looking Glass Journal</title>

  <style>
    /* ------------------  Base & Theme  ------------------ */
    :root{
      --bg:#070a0d; --panel:#0e1217; --soft:#141922; --muted:#9aa4b2; --text:#e7edf3;
      --accent:#8b5cf6; --accent-2:#06b6d4; --ring:#2b3340; --card:#0a0f14; --border:#202634;
      --shadow:0 10px 30px rgba(0,0,0,.5);
      --radius:16px; --radius-sm:12px; --radius-xs:10px;
      --gap:16px; --gap-lg:22px; --gap-xl:28px;
    }
    @media (prefers-color-scheme: light){
      :root{
        --bg:#f7fafc; --panel:#ffffff; --soft:#f3f6fb; --muted:#556071; --text:#0f172a;
        --accent:#06b6d4; --accent-2:#8b5cf6; --ring:#d2dae6; --card:#ffffff; --border:#e6ecf5;
        --shadow:0 8px 24px rgba(15,23,42,.08);
      }
    }

    *{box-sizing:border-box}
    html,body{height:100%}
    body{
      margin:0; background:var(--bg); color:var(--text);
      font:16px/1.55 system-ui,-apple-system,Segoe UI,Roboto,Ubuntu,Cantarell,Noto Sans,Helvetica,Arial;
      display:grid; grid-template-columns:320px 1fr; grid-template-rows:auto 1fr;
      grid-template-areas:"sidebar header" "sidebar main";
    }

    /* ------------------  Sidebar ------------------ */
    .sidebar{
      grid-area:sidebar; background:linear-gradient(180deg,var(--panel),var(--soft));
      border-right:1px solid var(--border); display:flex; flex-direction:column; min-height:100vh;
    }
    .brand{padding:20px; border-bottom:1px solid var(--border); display:flex; align-items:center; gap:12px}
    .logo{width:36px; height:36px; border-radius:10px;
      background:conic-gradient(from 210deg,var(--accent),var(--accent-2),var(--accent));
      box-shadow:var(--shadow);
    }
    .brand h1{font-size:1.1rem; margin:0; letter-spacing:.3px}

    .sidebar .search{padding:14px 16px; border-bottom:1px solid var(--border)}
    .input{width:100%; padding:10px 12px; border-radius:10px; border:1px solid var(--ring);
      background:var(--card); color:var(--text); outline:none}
    .input:focus{border-color:var(--accent)}

    .list{padding:10px; overflow:auto; flex:1; display:grid; gap:10px}
    .entry{border:1px solid var(--border); border-radius:var(--radius-sm); background:var(--card);
      padding:12px; cursor:pointer; transition:transform .12s ease, border-color .12s}
    .entry:hover{transform:translateY(-1px); border-color:var(--accent)}
    .entry h3{font-size:.95rem; margin:0 0 4px}
    .meta{font-size:.78rem; color:var(--muted); display:flex; gap:10px; align-items:center}
    .tag{padding:2px 8px; border-radius:999px; border:1px solid var(--border);
      background:rgba(139,92,246,.12); font-size:.72rem; color:var(--text)}
    .sidebar .footer{padding:12px 16px; border-top:1px solid var(--border); color:var(--muted); font-size:.82rem}

    /* ------------------  Header ------------------ */
    .header{
      grid-area:header; display:flex; align-items:center; justify-content:space-between;
      padding:14px 18px; border-bottom:1px solid var(--border); background:var(--panel); position:sticky; top:0; z-index:5;
    }
    .controls{display:flex; gap:10px; align-items:center}
    .btn{appearance:none; border:1px solid var(--ring); background:var(--card); color:var(--text);
      padding:8px 12px; border-radius:10px; font-weight:600; letter-spacing:.2px; cursor:pointer;
      transition:transform .12s ease, border-color .12s}
    .btn:hover{border-color:var(--accent); transform:translateY(-1px)}
    .btn.primary{background:linear-gradient(180deg, rgba(139,92,246,.2), var(--card)); border-color:var(--accent)}

    /* ------------------  Main ------------------ */
    main{grid-area:main; padding:var(--gap-lg); overflow:auto}
    .tabs{display:grid; gap:10px}
    .tab-bar{display:flex; gap:8px; flex-wrap:wrap}
    .tab-btn{appearance:none; border:1px solid var(--ring); background:var(--card); color:var(--text);
      padding:8px 12px; border-radius:999px; font-weight:600; cursor:pointer}
    .tab-btn[aria-selected="true"]{border-color:var(--accent); box-shadow:0 0 0 4px rgba(139,92,246,.18)}
    [data-tab-panel]{display:none}
    #tab-write:checked ~ .panels #panel-write,
    #tab-gratitude:checked ~ .panels #panel-gratitude{display:block}

    .wrap{display:grid; grid-template-columns:1.1fr .9fr; gap:var(--gap-lg); align-items:start}
    .card{background:var(--panel); border:1px solid var(--border); border-radius:var(--radius); box-shadow:var(--shadow)}
    .card h2{margin:0 0 6px; font-size:1.05rem}
    .card .body{padding:16px; display:grid; gap:12px}
    .fieldset{display:grid; gap:10px}
    label{font-size:.86rem; color:var(--muted)}
    .field{display:grid; gap:6px}
    .row{display:grid; grid-template-columns:repeat(3,1fr); gap:10px}
    textarea, input[type="text"], input[type="date"], select{
      width:100%; padding:10px 12px; border-radius:10px; border:1px solid var(--ring);
      background:var(--card); color:var(--text); outline:none
    }
    textarea{min-height:220px; resize:vertical}
    input:focus, select:focus, textarea:focus{border-color:var(--accent); box-shadow:0 0 0 4px rgba(139,92,246,.2)}
    .chips{display:flex; gap:8px; flex-wrap:wrap}
    .chip{display:inline-flex; align-items:center; gap:8px; padding:6px 10px; border:1px solid var(--ring);
      border-radius:999px; background:var(--card); font-size:.8rem; color:var(--muted)}
    details{border:1px dashed var(--ring); border-radius:var(--radius-xs); padding:10px 12px; background:rgba(255,255,255,.02)}
    summary{cursor:pointer; color:var(--accent-2); font-weight:600}
    .grid{display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:var(--gap)}
    .journal-card{padding:14px}
    .journal-card h3{margin:0 0 6px; font-size:1rem}
    .journal-card p{margin:0; color:var(--muted)}

    /* ------------------  Responsive ------------------ */
    @media (max-width:1100px){ .wrap{grid-template-columns:1fr} .grid{grid-template-columns:1fr} }
    @media (max-width:860px){
      body{grid-template-columns:1fr; grid-template-areas:"header" "main"}
      .sidebar{display:none} /* hide sidebar on small screens */
    }

    /* ------------------  Print ------------------ */
    @media print{
      body{display:block; background:#fff; color:#000}
      .sidebar, .header, .btn{display:none!important}
      main{padding:0}
      .card{box-shadow:none; border:1px solid #cfcfcf}
    }
  </style>
</head>
<body>
  <% request.setCharacterEncoding("UTF-8"); %>
  <%@ include file="/WEB-INF/drawer.jspf" %>
  

  <!-- Sidebar -->
  <aside class="sidebar">
    <div class="brand">
      <div class="logo" aria-hidden="true"></div>
      <h1>Looking Glass UPDATED???</h1>
    </div>

    <div class="search">
      <input class="input" type="search" placeholder="Search entries, tags..." aria-label="Search" />
    </div>
    <c:set var="uid" value="${sessionScope.uid}" />
    <c:if test="${empty uid}">
      <c:redirect url="${pageContext.request.contextPath}/login.jsp"/>
    </c:if>

    <sql:setDataSource var="db"
        driver="com.mysql.cj.jdbc.Driver"
        url="jdbc:mysql://localhost:3306/lookingglass?useSSL=false&serverTimezone=UTC"
        user="root"
        password="" />

    <sql:query var="recentRows" dataSource="${db}">
      SELECT journalID, title, entry, tags, data, time
      FROM journals
      WHERE uid = ?
      ORDER BY data DESC, time DESC
      LIMIT 4
      <sql:param value="${uid}" />
    </sql:query>

    <section class="card" aria-labelledby="recent-title">
  <div class="body">
    <h2 id="recent-title">Recent Entries</h2>

    <c:choose>
      <c:when test="${recentRows.rows != null && fn:length(recentRows.rows) > 0}">
        <div class="grid">
          <c:forEach var="j" items="${recentRows.rows}">
            <article class="card journal-card">
              <h3><c:out value="${j.title}"/></h3>
              <p class="muted">
                <c:out value="${fn:length(j.entry) > 120 ? fn:substring(j.entry,0,120).concat('…') : j.entry}"/>
              </p>
              <div class="meta" style="margin-top:8px">
                <span><c:out value="${j.data}"/></span>
                <c:if test="${not empty j.tags}">
                  <span class="tag">
                    #<c:out value="${fn:replace(fn:replace(j.tags,'[',''),']','')}"/>
                  </span>
                </c:if>
              </div>
            </article>
          </c:forEach>
        </div>
      </c:when>
      <c:otherwise>
        <p class="muted">No recent entries yet—write your first one above.</p>
      </c:otherwise>
    </c:choose>
  </div>
</section>


    <div class="footer">Click here for dictation</div>
  </aside>

  <!-- Wrap header+main in a form (no style change) -->
  <form id="journalForm"
        method="post"
        action="${pageContext.request.contextPath}/journal/save"
        accept-charset="UTF-8">

    <!-- Hidden fields servlet expects -->
	<input type="hidden" name="uid" 
	value="<%= (session.getAttribute("uid") == null) ? "" : session.getAttribute("uid").toString() %>"/>
    <input type="hidden" name="time" id="timeInput"/>
    <input type="hidden" name="tagsJson" id="tagsJson" value="[]"/>

    <!-- Header -->
    <header class="header">
      <div class="controls"><span class="muted">Your private journal</span></div>
      <div class="controls">
        <button class="btn" type="button">New Entry</button>
        <button class="btn primary" type="submit">Save</button>
      </div>
    </header>

    <!-- Main Content -->
    <main>
      <section class="tabs">
        <!-- Tab radios -->
        <input type="radio" id="tab-write" name="tabset" checked hidden />
        <input type="radio" id="tab-gratitude" name="tabset" hidden />

        <div class="tablist" role="tablist" aria-label="Journal Tabs">
          <label for="tab-write" class="tab-btn" role="tab" aria-selected="true" aria-controls="panel-write">Write</label>
          <label for="tab-gratitude" class="tab-btn" role="tab" aria-controls="panel-gratitude">Gratitude</label>
        </div>

        <div class="panels">
          <!-- Write Panel -->
          <div id="panel-write" data-tab-panel role="tabpanel" aria-labelledby="tab-write">
            <div class="wrap">
              <section class="card" aria-labelledby="editor-title">
                <div class="body">
                  <h2 id="editor-title">Write Entry</h2>

                  <div class="fieldset">
                    <div class="row">
                      <div class="field">
                        <label for="title">Title</label>
                        <input id="title" name="title" type="text" placeholder="Today's headline..." />
                      </div>

                      <div class="field">
                        <label for="date">Date</label>
                        <input id="date" name="date" type="date" />
                      </div>

                      <div class="field">
                        <label for="mood">Mood</label>
                        <select id="mood" name="mood">
                          <option>Happy</option>
                          <option>Calm</option>
                          <option>Neutral</option>
                          <option>Anxious</option>
                          <option>Low</option>
                        </select>
                      </div>
                    </div>

                    <div class="field">
                      <label for="tags">Tags</label>
                      <div class="chips" id="tags">
                        <span class="chip">#Work</span>
                        <span class="chip">#Personal</span>
                        <span class="chip">#Gratitude</span>
                        <span class="chip">#Ideas</span>
                      </div>
                    </div>

                    <div class="field">
                      <label for="content">Entry</label>
                      <textarea id="content" name="entry" placeholder="Stream of thoughts, gratitude list, or how was your day?"></textarea>
                    </div>

                    <details>
                      <summary>More prompts</summary>
                      <div class="grid">
                        <div class="field">
                          <label>What went well?</label>
                          <textarea name="whatWentWell" placeholder="Wins and bright spots..."></textarea>
                        </div>
                        <div class="field">
                          <label>What could be better?</label>
                          <textarea name="whatCouldBeBetter" placeholder="Stumbles, lessons, next steps..."></textarea>
                        </div>
                      </div>
                    </details>

                    <div class="controls" style="justify-content:flex-end; margin-top:6px">
                      <button class="btn" type="reset">Discard</button>
                      <button class="btn primary" type="submit">Save Entry</button>
                    </div>
                  </div>
                </div>
              </section>

              <section class="card" aria-labelledby="recent-title">
                <div class="body">
                  <h2 id="recent-title">Recent Entries</h2>
                  <div class="grid">
                    <article class="card journal-card">
                      <h3>Test1</h3>
                      <p class="muted">Thank God for chatgpt, because there is no WAY I could make it look this good</p>
                      <div class="meta" style="margin-top:8px"><span>Oct 6, 2025</span><span class="tag">#Work</span></div>
                    </article>
                    <article class="card journal-card">
                      <h3>Send Help (These will be dynamic from DB, the 2-4 most recent entries)</h3>
                      <p class="muted">Almost tearing my hair out due to UI design</p>
                      <div class="meta" style="margin-top:8px"><span>Oct 5, 2025</span><span class="tag">#SaveTheCoders</span></div>
                    </article>
                  </div>
                </div>
              </section>
            </div>
          </div>

          <!-- Gratitude Panel -->
          <div id="panel-gratitude" data-tab-panel role="tabpanel" aria-labelledby="tab-gratitude">
            <section class="card" style="max-width:940px; margin-inline:auto;">
              <div class="body">
                <h2>Gratitude Log</h2>
                <p class="muted">Write 3-5 quick bullets. Keep it light and specific.</p>

                <div class="fieldset">
                  <div class="field"><label for="g1">#1</label><input id="g1" type="text" placeholder="A person, moment, or tiny win..." /></div>
                  <div class="field"><label for="g2">#2</label><input id="g2" type="text" placeholder="Something you tasted, saw, or heard..." /></div>
                  <div class="field"><label for="g3">#3</label><input id="g3" type="text" placeholder="A thing you're proud of today..." /></div>
                  <div class="field"><label for="g4">#4</label><input id="g4" type="text" placeholder="Who helped you?" /></div>
                  <div class="field"><label for="g5">#5</label><input id="g5" type="text" placeholder="What made you smile?" /></div>
                </div>
              </div>
            </section>
          </div>
        </div>
      </section>
    </main>
  </form>

  <!-- Tiny helper to keep visuals unchanged but send time + tags -->
  <script>
    (function () {
      function pad(n){ return n<10 ? '0'+n : ''+n; }
      function nowHMS(){
        const d = new Date();
        return pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds());
      }
      const form = document.getElementById('journalForm');
      if (!form) return;

      form.addEventListener('submit', function () {
        const t = document.getElementById('timeInput');
        if (t && !t.value) t.value = nowHMS();

        const chips = Array.prototype.map.call(
          document.querySelectorAll('#tags .chip'),
          el => (el.textContent || '').replace(/^#/, '').trim()
        ).filter(Boolean);
        const tagsJsonEl = document.getElementById('tagsJson');
        if (tagsJsonEl) tagsJsonEl.value = JSON.stringify(chips);
      });
    })();
  </script>
</body>
