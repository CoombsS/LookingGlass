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

    /* --- Compact title-only list for Recent Entries --- */
    .entry-list{margin:0;padding:0;list-style:none;display:grid;gap:8px}
    .entry-item{margin:0}
    .entry-link{
      display:flex;align-items:center;gap:10px;
      padding:10px 12px;border:1px solid var(--ring);
      background:var(--card);border-radius:10px;text-decoration:none;color:var(--text);
      transition:transform .12s ease,border-color .12s ease,box-shadow .12s ease;
      overflow:hidden
    }
    .entry-link:hover{transform:translateY(-1px);border-color:var(--accent);box-shadow:0 6px 14px rgba(0,0,0,.18)}
    .entry-bullet{width:8px;height:8px;border-radius:999px;background:linear-gradient(180deg,var(--accent),var(--accent-2));flex-shrink:0}
    .entry-title{font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;flex:1;min-width:0}

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
      display:grid; grid-template-columns:380px 1fr; grid-template-rows:auto 1fr;
      grid-template-areas:"sidebar header" "sidebar main";
    }

    /* ------------------  Sidebar ------------------ */
    .sidebar{
      grid-area:sidebar; background:linear-gradient(180deg,var(--panel),var(--soft));
      border-right:1px solid var(--border); display:flex; flex-direction:column; min-height:100vh;
    }
  .brand{padding:20px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:center; gap:12px}
    .logo{width:36px; height:36px; border-radius:10px;
      background:conic-gradient(from 210deg,var(--accent),var(--accent-2),var(--accent));
      box-shadow:var(--shadow);
    }
    .brand h1{font-size:1.1rem; margin:0; letter-spacing:.3px}

    .sidebar .search{padding:14px 16px; border-bottom:1px solid var(--border)}
    .input{width:100%; padding:10px 12px; border-radius:10px; border:1px solid var(--ring);
      background:var(--card); color:var(--text); outline:none}
    .input:focus{border-color:var(--accent)}

    .sidebar .card{margin:16px 14px; border:none; box-shadow:none}
    .sidebar .card .body{padding:10px}
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
      padding:14px 18px; border-bottom:1px solid var(--border); background:var(--panel); position:sticky; top:0; z-index:1200; min-height:64px;
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
      border-radius:999px; background:var(--card); font-size:.8rem; color:var(--muted);
      cursor:pointer; transition:all .15s ease; user-select:none}
    .chip:hover{border-color:var(--accent); transform:translateY(-1px)}
    .chip.selected{
      background:linear-gradient(135deg, rgba(139,92,246,.25), rgba(6,182,212,.15));
      border-color:var(--accent); color:var(--text); font-weight:600;
      box-shadow:0 0 0 3px rgba(139,92,246,.15)
    }
    details{border:1px dashed var(--ring); border-radius:var(--radius-xs); padding:10px 12px; background:rgba(255,255,255,.02)}
    summary{cursor:pointer; color:var(--accent-2); font-weight:600}
    .grid{display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:var(--gap)}
    .journal-card{padding:14px}
    .journal-card h3{margin:0 0 6px; font-size:1rem}
    .journal-card p{margin:0; color:var(--muted)}

    /* --- Recent entries (right side) --- */
    .recent-grid{display:grid; grid-template-columns:repeat(auto-fit,minmax(260px,1fr)); gap:12px}
    .recent-item{
      display:block; padding:12px 14px; border:1px solid var(--ring);
      background:var(--card); border-radius:12px; color:var(--text); text-decoration:none;
      transition:transform .12s ease,border-color .12s ease,box-shadow .12s ease; overflow:hidden
    }
    .recent-item:hover{transform:translateY(-1px); border-color:var(--accent); box-shadow:0 6px 14px rgba(0,0,0,.18)}
    .recent-title{margin:0 0 6px; font-size:1rem; font-weight:700; white-space:nowrap; overflow:hidden; text-overflow:ellipsis}
  .recent-snippet{margin:0 0 10px; color:var(--muted); display:-webkit-box; -webkit-line-clamp:2; line-clamp:2; -webkit-box-orient:vertical; overflow:hidden}
  .recent-meta{display:flex; gap:10px; align-items:center; font-size:.8rem; color:var(--muted)}
  .recent-tags{display:flex; gap:6px; flex-wrap:wrap}
  .recent-tag{padding:2px 8px; border:1px solid var(--ring); border-radius:999px}

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

    /* ------------------  Modal ------------------ */
    .modal-overlay{
      display:none; position:fixed; top:0; left:0; right:0; bottom:0;
      background:rgba(0,0,0,.7); z-index:9999; align-items:center; justify-content:center;
      backdrop-filter:blur(4px);
    }
    .modal-overlay.active{display:flex}
    .modal-content{
      background:var(--panel); border:1px solid var(--border); border-radius:var(--radius);
      box-shadow:0 20px 60px rgba(0,0,0,.5); max-width:700px; width:90%;
      max-height:80vh; overflow:auto; animation:modalIn .2s ease;
    }
    @keyframes modalIn{from{opacity:0; transform:scale(.95)} to{opacity:1; transform:scale(1)}}
    .modal-header{
      padding:20px 24px; border-bottom:1px solid var(--border);
      display:flex; justify-content:space-between; align-items:center;
    }
    .modal-header h2{margin:0; font-size:1.3rem}
    .modal-close{
      background:transparent; border:none; color:var(--muted); font-size:1.5rem;
      cursor:pointer; padding:4px 8px; border-radius:6px;
    }
    .modal-close:hover{background:var(--soft); color:var(--text)}
    .modal-body{padding:24px}
    .modal-meta{display:flex; gap:12px; margin-bottom:16px; font-size:.85rem; color:var(--muted)}
    .modal-tags{display:flex; gap:6px; flex-wrap:wrap; margin-bottom:16px}
    .modal-entry{line-height:1.7; white-space:pre-wrap}
  </style>
</head>
<body>
  <% request.setCharacterEncoding("UTF-8"); %>
  <%@ include file="/WEB-INF/drawer.jspf" %>

  <c:set var="uid" value="${sessionScope.uid}" />

  <!-- Defense-in-depth: if not authenticated, redirect to login -->
  <c:if test="${empty uid}">
    <c:redirect url="/login.jsp" />
  </c:if>

  <!-- ====== SEARCH INPUT ====== -->
  <c:set var="q" value="${fn:trim(param.q)}" />
  <c:set var="qLike" value="%${q}%" />

  <!-- ====== DB DATASOURCE ====== -->
  <sql:setDataSource var="db" dataSource="jdbc/LookingGlassDB" />

  <!-- ====== HANDLE GRATITUDE SAVE (inline) ====== -->
  <c:if test="${param.section == 'gratitude' && not empty param.saveGratitude}">
    <sql:update dataSource="${db}" var="gResult">
      INSERT INTO gratitudes (uid, data, time, g1, g2, g3, g4, g5)
      VALUES (?, CURDATE(), ?, ?, ?, ?, ?, ?)
      <sql:param value="${uid}" />
      <sql:param value="${param.time}" />
      <sql:param value="${param.g1}" />
      <sql:param value="${param.g2}" />
      <sql:param value="${param.g3}" />
      <sql:param value="${param.g4}" />
      <sql:param value="${param.g5}" />
    </sql:update>
  </c:if>

  <!-- ====== QUERY: search if q, else recent ====== -->
  <!-- Left list: all entries (or all matches when searching) -->
  <c:choose>
    <c:when test="${not empty q}">
      <sql:query var="listRows" dataSource="${db}">
        SELECT journalID, title, entry, tags, data, time
        FROM journals
        WHERE uid = ?
          AND (
            title LIKE ?
            OR entry LIKE ?
            OR tags  LIKE ?
          )
        ORDER BY data DESC, time DESC
        <sql:param value="${uid}" />
        <sql:param value="${qLike}" />
        <sql:param value="${qLike}" />
        <sql:param value="${qLike}" />
      </sql:query>
    </c:when>
    <c:otherwise>
      <sql:query var="listRows" dataSource="${db}">
        SELECT journalID, title, entry, tags, data, time
        FROM journals
        WHERE uid = ?
        ORDER BY data DESC, time DESC
        <sql:param value="${uid}" />
      </sql:query>
    </c:otherwise>
  </c:choose>

  <!-- Right grid: top 4 most recent always -->
  <sql:query var="recentRows" dataSource="${db}">
    SELECT journalID, title, entry, tags, data, time
    FROM journals
    WHERE uid = ?
    ORDER BY data DESC, time DESC
    LIMIT 4
    <sql:param value="${uid}" />
  </sql:query>

  <!-- Sidebar -->
  <aside class="sidebar">
    <div class="brand">
      <div class="logo" aria-hidden="true"></div>
      <h1>Looking Glass</h1>
    </div>

    <!-- SEARCH FORM (GET) -->
    <form class="search" method="get" action="${pageContext.request.requestURI}">
      <input class="input" type="search" name="q"
             value="${fn:escapeXml(param.q)}"
             placeholder="Search entries, tags..." aria-label="Search" />
    </form>

    <section class="card" aria-labelledby="recent-title">
      <div class="body">
        <h2 id="recent-title">Past Entries</h2>

        <c:if test="${not empty q}">
          <p class="muted" style="margin:6px 0 0">Results for "<c:out value='${q}'/>"</p>
        </c:if>

        <c:choose>
          <c:when test="${empty uid}">
            <p class="muted">Please log in to view your entries.</p>
          </c:when>
          <c:when test="${listRows.rows != null && fn:length(listRows.rows) > 0}">
            <ul class="entry-list">
              <c:forEach var="j" items="${listRows.rows}">
                <c:url var="viewUrl" value="/journal/view">
                  <c:param name="journalID" value="${j.journalID}" />
                </c:url>
                <li class="entry-item">
                  <a class="entry-link" href="#" onclick="showEntryModal('${j.journalID}', this); return false;"
                     data-title="<c:out value='${j.title}'/>"
                     data-entry="<c:out value='${j.entry}'/>"
                     data-date="<c:out value='${j.data}'/>"
                     data-time="<c:out value='${j.time}'/>"
                     data-tags="<c:out value='${j.tags}'/>">
                    <span class="entry-bullet" aria-hidden="true"></span>
                    <span class="entry-title"><c:out value="${j.title}"/></span>
                  </a>
                </li>
              </c:forEach>
            </ul>
          </c:when>
          <c:otherwise>
            <p class="muted">No recent entries yet—write your first one above.</p>
          </c:otherwise>
        </c:choose>
      </div>
    </section>

    <div class="footer">Click here for dictation</div>
  </aside>

  <!-- Form starts -->
  <form id="journalForm"
        method="post"
        action="${pageContext.request.contextPath}/journal/save"
        accept-charset="UTF-8">

  <!-- Hidden fields servlet expects -->
    <input type="hidden" name="uid" value="${sessionScope.uid}"/>
    <input type="hidden" name="time" id="timeInput"/>
    <input type="hidden" name="tagsJson" id="tagsJson" value="[]"/>
  <input type="hidden" name="section" id="sectionField" value="journal"/>

    <!-- Header -->
    <header class="header">
      <div class="controls"><span class="muted">Your private journal</span></div>
    </header>

    <!-- Main Content -->
    <main>
      <section class="tabs">
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

              <section class="card" aria-labelledby="recent-main-title">
                <div class="body">
                  <h2 id="recent-main-title">Recent Entries</h2>
                  <div class="recent-grid">
                    <c:choose>
                      <c:when test="${empty uid}">
                        <p class="muted">Please log in to see your recent entries.</p>
                      </c:when>
                      <c:when test="${recentRows.rows != null && fn:length(recentRows.rows) > 0}">
                        <c:forEach var="j" items="${recentRows.rows}">
                          <a href="#" class="recent-item"
                             onclick="showEntryModal('${j.journalID}', this); return false;"
                             data-title="<c:out value='${j.title}'/>"
                             data-entry="<c:out value='${j.entry}'/>"
                             data-date="<c:out value='${j.data}'/>"
                             data-time="<c:out value='${j.time}'/>"
                             data-tags="<c:out value='${j.tags}'/>">
                            <h3 class="recent-title"><c:out value="${j.title}"/></h3>
                            <p class="recent-snippet"><c:out value="${fn:substring(j.entry, 0, 160)}"/>...</p>
                            <div class="recent-meta">
                              <span><c:out value="${j.data}"/></span>
                              <div class="recent-tags" data-tags-container></div>
                            </div>
                          </a>
                        </c:forEach>
                      </c:when>
                      <c:otherwise>
                        <p class="muted">No entries yet. Start writing above!</p>
                      </c:otherwise>
                    </c:choose>
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
                  <div class="field"><label for="g1">#1</label><input id="g1" name="g1" type="text" placeholder="A person, moment, or tiny win..." /></div>
                  <div class="field"><label for="g2">#2</label><input id="g2" name="g2" type="text" placeholder="Something you tasted, saw, or heard..." /></div>
                  <div class="field"><label for="g3">#3</label><input id="g3" name="g3" type="text" placeholder="A thing you're proud of today..." /></div>
                  <div class="field"><label for="g4">#4</label><input id="g4" name="g4" type="text" placeholder="Who helped you?" /></div>
                  <div class="field"><label for="g5">#5</label><input id="g5" name="g5" type="text" placeholder="What made you smile?" /></div>

                  <div class="controls" style="justify-content:flex-end; margin-top:6px">
                    <button class="btn" type="button" id="gDiscard">Discard</button>
                    <button class="btn primary" type="submit" name="saveGratitude" value="1" id="gSave">Save Gratitudes</button>
                  </div>
                </div>
              </div>
            </section>
          </div>
        </div>
      </section>
    </main>
  </form>

  <!-- Modal for viewing entries -->
  <div class="modal-overlay" id="entryModal">
    <div class="modal-content">
      <div class="modal-header">
        <h2 id="modalTitle"></h2>
        <button class="modal-close" onclick="closeEntryModal()">&times;</button>
      </div>
      <div class="modal-body">
        <div class="modal-meta">
          <span id="modalDate"></span>
          <span id="modalTime"></span>
        </div>
        <div class="modal-tags" id="modalTags"></div>
        <div class="modal-entry" id="modalEntry"></div>
      </div>
    </div>
  </div>

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

      // Tag selection handler
      const tagChips = document.querySelectorAll('#tags .chip');
      tagChips.forEach(function(chip) {
        chip.addEventListener('click', function() {
          this.classList.toggle('selected');
        });
      });

      form.addEventListener('submit', function () {
        const t = document.getElementById('timeInput');
        if (t && !t.value) t.value = nowHMS();

        // Only include selected tags
        const selectedChips = Array.prototype.map.call(
          document.querySelectorAll('#tags .chip.selected'),
          el => (el.textContent || '').replace(/^#/, '').trim()
        ).filter(Boolean);
        const tagsJsonEl = document.getElementById('tagsJson');
        if (tagsJsonEl) tagsJsonEl.value = JSON.stringify(selectedChips);
      });
    })();

    // Modal functions
    function parseTagsString(tags) {
      if (!tags) return [];
      // Try JSON first
      try {
        const parsed = JSON.parse(tags);
        if (Array.isArray(parsed)) return parsed;
      } catch (e) { /* not JSON */ }
      // Fallback: comma-separated
      return String(tags).split(',');
    }

    function cleanTag(tag) {
      return String(tag)
        .replace(/^#/, '')
        .replace(/^\s+|\s+$/g, '')
        .replace(/^\[+|\]+$/g, '')
        .replace(/^['"]+|['"]+$/g, '')
        .trim();
    }

    function showEntryModal(id, linkEl) {
      const modal = document.getElementById('entryModal');
      const title = linkEl.getAttribute('data-title');
      const entry = linkEl.getAttribute('data-entry');
      const date = linkEl.getAttribute('data-date');
      const time = linkEl.getAttribute('data-time');
      const tags = linkEl.getAttribute('data-tags');

      document.getElementById('modalTitle').textContent = title;
      document.getElementById('modalDate').textContent = date;
      document.getElementById('modalTime').textContent = time;
      document.getElementById('modalEntry').textContent = entry;

      // Parse and display tags (supports JSON array or CSV)
      const tagsContainer = document.getElementById('modalTags');
      tagsContainer.innerHTML = '';
      const arr = parseTagsString(tags).map(cleanTag).filter(Boolean);
      arr.forEach(function(tag) {
        const tagEl = document.createElement('span');
        tagEl.className = 'tag';
        tagEl.textContent = '#' + tag;
        tagsContainer.appendChild(tagEl);
      });

      modal.classList.add('active');
    }

    function closeEntryModal() {
      const modal = document.getElementById('entryModal');
      modal.classList.remove('active');
    }

    // Close modal when clicking outside
    document.getElementById('entryModal').addEventListener('click', function(e) {
      if (e.target === this) closeEntryModal();
    });

    // Close modal with Escape key
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') closeEntryModal();
    });

    // Update tab selected state + adjust form action depending on active section
    (function(){
      const form = document.getElementById('journalForm');
      const sectionField = document.getElementById('sectionField');
      const writeRadio = document.getElementById('tab-write');
      const gratRadio = document.getElementById('tab-gratitude');
      const writeLabel = document.querySelector('label[for="tab-write"]');
      const gratLabel = document.querySelector('label[for="tab-gratitude"]');
      const gSave = document.getElementById('gSave');
      const gDiscard = document.getElementById('gDiscard');
      const originalAction = form ? form.getAttribute('action') : '';
      function updateTabs(){
        if (!writeLabel || !gratLabel) return;
        writeLabel.setAttribute('aria-selected', writeRadio && writeRadio.checked ? 'true' : 'false');
        gratLabel.setAttribute('aria-selected', gratRadio && gratRadio.checked ? 'true' : 'false');
      }
      if (writeRadio && gratRadio){
        writeRadio.addEventListener('change', updateTabs);
        gratRadio.addEventListener('change', updateTabs);
        updateTabs();
      }
      if (gSave && form && sectionField){
        gSave.addEventListener('click', function(){
          // Switch to gratitude mode and post to this JSP so JSTL can persist
          sectionField.value = 'gratitude';
          form.setAttribute('action', window.location.pathname);
        });
      }
      // Journal save buttons should mark section=journal and restore action
      if (form){
        document.querySelectorAll('button[type="submit"]').forEach(function(btn){
          if (btn.id === 'gSave') return;
          btn.addEventListener('click', function(){
            if (sectionField){ sectionField.value = 'journal'; }
            if (originalAction){ form.setAttribute('action', originalAction); }
          });
        });
      }
      // Discard only clears gratitude fields
      if (gDiscard){
        gDiscard.addEventListener('click', function(){
          ['g1','g2','g3','g4','g5'].forEach(function(id){
            const el = document.getElementById(id);
            if (el) el.value = '';
          });
        });
      }
    })();

    // Populate right-side recent cards' tag list client-side to avoid JSON artifacts
    document.querySelectorAll('.recent-item').forEach(function(item){
      const tags = item.getAttribute('data-tags') || '';
      const container = item.querySelector('[data-tags-container]');
      if (!container) return;
      container.innerHTML = '';
      const arr = parseTagsString(tags).map(cleanTag).filter(Boolean);
      if (arr.length === 0) {
        container.style.display = 'none';
        return;
      }
      arr.forEach(function(tag){
        const el = document.createElement('span');
        el.className = 'recent-tag';
        el.textContent = '#' + tag;
        container.appendChild(el);
      });
    });
  </script>
</body>
</html>
