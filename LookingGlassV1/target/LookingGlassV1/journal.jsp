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
  <link rel="stylesheet" href="css/app.css">
  <link rel="stylesheet" href="css/journal.css">
</head>
<body class="grid-journal">
  <% request.setCharacterEncoding("UTF-8"); %>
  <%@ include file="/WEB-INF/drawer.jspf" %>

  <c:set var="uid" value="${sessionScope.uid}" />
  <!-- check if user logged in-->
  <c:if test="${empty uid}">
    <c:redirect url="/login.jsp" />
  </c:if>

  <!--  Searching tags using wildcards (%${q}% = search param ex: tagname, specific word, etc.)-->
  <c:set var="q" value="${fn:trim(param.q)}" />
  <c:set var="qLike" value="%${q}%" />

  <!-- DB Connection -->
  <sql:setDataSource var="db" dataSource="jdbc/LookingGlassDB" />

<!-- Query for journal entries-->
  <c:choose>
    <c:when test="${not empty q}">
      <sql:query var="listRows" dataSource="${db}">
        SELECT journalID, title, entry, tags, data, time, sentiment
        FROM journals
        WHERE uid = ?
          AND (
            title LIKE ?
            OR entry LIKE ?
            OR tags  LIKE ?
          )
        ORDER BY time DESC
        <sql:param value="${uid}" />
        <sql:param value="${qLike}" />
        <sql:param value="${qLike}" />
        <sql:param value="${qLike}" />
      </sql:query>
    </c:when>
    <c:otherwise>
      <sql:query var="listRows" dataSource="${db}">
        SELECT journalID, title, entry, tags, data, time, sentiment
        FROM journals
        WHERE uid = ?
        ORDER BY time DESC
        <sql:param value="${uid}" />
      </sql:query>
    </c:otherwise>
  </c:choose>

  <!-- Right grid: 4 most recent entries -->
  <sql:query var="recentRows" dataSource="${db}">
    SELECT journalID, title, entry, tags, data, time, sentiment
    FROM journals
    WHERE uid = ?
    ORDER BY time DESC
    LIMIT 4
    <sql:param value="${uid}" />
  </sql:query>

  <!-- Sidebar -->
  <aside class="sidebar">
    <div class="brand">
      <div class="logo" aria-hidden="true"></div>
      <h1>Looking Glass</h1>
    </div>

    <!-- Searchbar -->
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
        <!-- Search Results -->
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
                     data-sentiment="<c:out value='${j.sentiment}'/>"
                     data-time="<c:out value='${j.time}'/>"
                     data-tags="<c:out value='${j.tags}'/>"
                     data-keyphrases="<c:out value='${j.data}'/>">
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

    <div class="footer">Click here for dictation (not working currently)</div>
  </aside>

  <!-- Actual journal -->
  <form id="journalForm"
        method="post"
        action="${pageContext.request.contextPath}/journalsave"
        accept-charset="UTF-8">

  <!-- Hidden fields for servlet -->
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

              <!-- Left side recent entries -->
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
                             data-sentiment="<c:out value='${j.sentiment}'/>"
                             data-time="<c:out value='${j.time}'/>"
                             data-tags="<c:out value='${j.tags}'/>"
                             data-keyphrases="<c:out value='${j.data}'/>">
                            <h3 class="recent-title"><c:out value="${j.title}"/></h3>
                            <p class="recent-snippet"><c:out value="${fn:substring(j.entry, 0, 160)}"/>...</p>
                            <div class="recent-meta">
                              <c:choose>
                                <c:when test="${j.sentiment != null}">
                                  <c:set var="score" value="${j.sentiment}" />
                                  <c:choose>
                                    <c:when test="${score > 0.6}">
                                      <span>Positive (<c:out value="${score}"/>)</span>
                                    </c:when>
                                    <c:when test="${score < 0.4}">
                                      <span>Negative (<c:out value="${score}"/>)</span>
                                    </c:when>
                                    <c:otherwise>
                                      <span>Neutral (<c:out value="${score}"/>)</span>
                                    </c:otherwise>
                                  </c:choose>
                                </c:when>
                                <c:otherwise>
                                  <span>N/A</span>
                                </c:otherwise>
                              </c:choose>
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

  <!-- Viewing entries modal -->
  <div class="modal-overlay" id="entryModal">
    <div class="modal-content">
      <div class="modal-header">
        <h2 id="modalTitle"></h2>
        <button class="modal-close" onclick="closeEntryModal()">&times;</button>
      </div>
      <div class="modal-body">
        <div class="modal-meta">
          <span id="modalSentiment"></span>
          <span id="modalTime"></span>
        </div>
        <div class="modal-tags" id="modalTags"></div>
        <div class="modal-entry" id="modalEntry"></div>
        <div class="modal-keyphrases" id="modalKeyPhrases" style="margin-top: 16px; padding-top: 16px; border-top: 1px solid #e0e0e0;"></div>
      </div>
    </div>
  </div>

  <!-- Helpers and random stuff-->

  <!-- Formating time -->
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
          //only selected tags
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
      // Try JSON 
      try {
        const parsed = JSON.parse(tags);
        if (Array.isArray(parsed)) return parsed;
      } catch (e) { /* not JSON */ }
      return String(tags).split(',');
    }
    //cleaning up the tags
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
      const sentiment = linkEl.getAttribute('data-sentiment');
      const time = linkEl.getAttribute('data-time');
      const tags = linkEl.getAttribute('data-tags');
      const keyPhrases = linkEl.getAttribute('data-keyphrases');

      document.getElementById('modalTitle').textContent = title;

      // Formating the sentiment (maybe actual emojis later)
      const sentimentEl = document.getElementById('modalSentiment');
      if (sentiment && sentiment !== 'null' && sentiment !== '') {
        const score = parseFloat(sentiment);
        let label = 'Neutral';
        let emoji = '-_-';
        if (score > 0.6) {
          label = 'Positive';
          emoji = ':)';
        } else if (score < 0.4) {
          label = 'Negative';
          emoji = ':(';
        }
        sentimentEl.textContent = emoji + ' Sentiment: ' + label + ' (' + score.toFixed(2) + ')';
      } else {
        sentimentEl.textContent = 'Sentiment: Analyzing...';
      }
      
      document.getElementById('modalTime').textContent = time;
      document.getElementById('modalEntry').textContent = entry;

      // Parse and display tags
      const tagsContainer = document.getElementById('modalTags');
      tagsContainer.innerHTML = '';
      const arr = parseTagsString(tags).map(cleanTag).filter(Boolean);
      arr.forEach(function(tag) {
        const tagEl = document.createElement('span');
        tagEl.className = 'tag';
        tagEl.textContent = '#' + tag;
        tagsContainer.appendChild(tagEl);
      });

      // Display key phrases (data field)
      //DISCLAIMER: CHATGPT GENERATED THIS SECTION (keyPhrases DISPLAY)
      const keyPhrasesContainer = document.getElementById('modalKeyPhrases');
      keyPhrasesContainer.innerHTML = '';
      if (keyPhrases && keyPhrases !== 'null' && keyPhrases !== '') {
        try {
          const phrases = JSON.parse(keyPhrases);
          if (Array.isArray(phrases) && phrases.length > 0) {
            const heading = document.createElement('h3');
            heading.textContent = 'Key Phrases';
            heading.style.marginBottom = '8px';
            heading.style.fontSize = '14px';
            heading.style.fontWeight = 'bold';
            keyPhrasesContainer.appendChild(heading);
            
            const list = document.createElement('ul');
            list.style.listStyle = 'disc';
            list.style.paddingLeft = '20px';
            phrases.forEach(function(phrase) {
              const li = document.createElement('li');
              li.textContent = phrase;
              li.style.marginBottom = '4px';
              list.appendChild(li);
            });
            keyPhrasesContainer.appendChild(list);
          }
        } catch (e) {
          // If not JSON, display as plain text
          const p = document.createElement('p');
          p.textContent = 'Key Phrases: ' + keyPhrases;
          keyPhrasesContainer.appendChild(p);
        }
      }

      modal.classList.add('active');
    }

    function closeEntryModal() {
      const modal = document.getElementById('entryModal');
      modal.classList.remove('active');
    }
    //if click outside, close
    document.getElementById('entryModal').addEventListener('click', function(e) {
      if (e.target === this) closeEntryModal();
    });

    //if esc, close
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') closeEntryModal();
    });

    //Update the selected tab
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
          //Switch to gratitude mode and post to servlet
          sectionField.value = 'gratitude';
          form.setAttribute('action', '${pageContext.request.contextPath}/journalsave');
        });
      }
      //Journal save buttons 
      if (form){
        document.querySelectorAll('button[type="submit"]').forEach(function(btn){
          if (btn.id === 'gSave') return;
          btn.addEventListener('click', function(){
            if (sectionField){ sectionField.value = 'journal'; }
            if (originalAction){ form.setAttribute('action', originalAction); }
          });
        });
      }
      if (gDiscard){
        gDiscard.addEventListener('click', function(){
          ['g1','g2','g3','g4','g5'].forEach(function(id){
            const el = document.getElementById(id);
            if (el) el.value = '';
          });
        });
      }
    })();

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