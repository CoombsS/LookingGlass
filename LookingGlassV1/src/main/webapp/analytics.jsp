<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"  uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<!DOCTYPE html>
<!--
  AI USAGE DISCLAIMER
  ALL STYLING, LAYOUT, AND JAVASCRIPT CODE IN THIS FILE WAS GENERATED OR
  ASSISTED BY CHATGPT; SQL, api calls, and functional logic will be/is Skyler generated. 
  Pretty much gave me a template tailored to this project.
-->
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Looking Glass — Analytics</title>
  <link rel="stylesheet" href="css/app.css">
  <link rel="stylesheet" href="css/analytics.css">
</head>
<body class="grid-analytics">
  <% request.setCharacterEncoding("UTF-8"); %>
  <%@ include file="/WEB-INF/drawer.jspf" %>

  <c:set var="uid" value="${sessionScope.uid}" />
  <c:if test="${empty uid}">
    <c:redirect url="/login.jsp" />
  </c:if>

  <% 
    String uidValue = "";
    if (session != null && session.getAttribute("uid") != null) {
      uidValue = session.getAttribute("uid").toString();
    }
  %>
  <input type="hidden" id="uid" value='<%= uidValue %>' />

  <script>
    const ANALYTICS_API = 'http://127.0.0.1:5003/analytics';
    const uidInput = document.getElementById('uid');
    const userUid = uidInput ? uidInput.value : null;

    if (!userUid) {
      window.location.href = 'login.jsp';
    }

    // Fetch all analytics data
    async function loadAnalyticsData() {
      try {
        const [chatEmotionData, journalSentimentData, journalData, chatData, activityData, tagsData, patternsData, trendsData] = await Promise.all([
          fetch(ANALYTICS_API + '/emotion-distribution/' + userUid).then(r => r.json()),
          fetch(ANALYTICS_API + '/journal-sentiment/' + userUid).then(r => r.json()),
          fetch(ANALYTICS_API + '/journal-stats/' + userUid).then(r => r.json()),
          fetch(ANALYTICS_API + '/chat-stats/' + userUid).then(r => r.json()),
          fetch(ANALYTICS_API + '/recent-activity/' + userUid).then(r => r.json()),
          fetch(ANALYTICS_API + '/top-tags/' + userUid).then(r => r.json()),
          fetch(ANALYTICS_API + '/engagement-patterns/' + userUid).then(r => r.json()),
          fetch(ANALYTICS_API + '/emotion-trends/' + userUid).then(r => r.json())
        ]);

        renderJournalStats(journalData);
        renderChatStats(chatData);
        renderJournalSentimentChart(journalSentimentData);
        renderChatEmotionChart(chatEmotionData);
        renderRecentActivity(activityData);
        renderTags(tagsData);
        renderEngagementPatterns(patternsData);
        renderEmotionTrends(trendsData);
        renderEngagementScore(journalData, chatData);
        renderAchievements(journalData, chatData);
      } catch (error) {
        console.error('Failed to load analytics:', error);
      }
    }

    function renderJournalStats(data) {
      if (!data.success || !data.stats) {
        return;
      }
      
      const stats = data.stats;
      const totalEl = document.querySelector('.journal-stat-value');
      const weekEl = document.querySelector('.journal-stat-meta');
      const monthEl = document.querySelector('.activity-stat-value');
      
      if (totalEl) {
        totalEl.textContent = stats.total_entries || 0;
      }
      if (weekEl) {
        weekEl.textContent = (stats.week_entries || 0) + ' this week';
      }
      if (monthEl) {
        monthEl.textContent = stats.month_entries || 0;
      }
    }

    function renderChatStats(data) {
      if (!data.success || !data.stats) {
        return;
      }
      
      const stats = data.stats;
      const sessionsEl = document.querySelector('.chat-stat-value');
      const messagesEl = document.querySelector('.chat-stat-meta');
      
      if (sessionsEl) {
        sessionsEl.textContent = stats.total_sessions || 0;
      }
      if (messagesEl) {
        messagesEl.textContent = (stats.total_messages || 0) + ' total messages';
      }

      // Chat insights
      const metricsContainer = document.querySelector('.metric-list');
      if (metricsContainer && stats.total_sessions > 0) {
        const avgMessages = Math.round(stats.total_messages / stats.total_sessions);
        metricsContainer.innerHTML = '<div class="metric-item">' +
          '<span class="metric-label">Total Conversations</span>' +
          '<span class="metric-value">' + stats.total_sessions + '</span>' +
          '</div>' +
          '<div class="metric-item">' +
          '<span class="metric-label">Total Messages</span>' +
          '<span class="metric-value">' + stats.total_messages + '</span>' +
          '</div>' +
          '<div class="metric-item">' +
          '<span class="metric-label">Messages This Week</span>' +
          '<span class="metric-value">' + (stats.week_messages || 0) + '</span>' +
          '</div>' +
          '<div class="metric-item">' +
          '<span class="metric-label">Avg Messages/Session</span>' +
          '<span class="metric-value">' + avgMessages + '</span>' +
          '</div>';
      }
    }

    function renderChatEmotionChart(data) {
      const chartContainer = document.querySelector('.chat-emotion-chart');
      if (!chartContainer) {
        return;
      }

      if (!data.success || !data.distribution || data.distribution.length === 0) {
        chartContainer.innerHTML = '<p class="muted">No emotion data available yet. Keep chatting!</p>';
        return;
      }

      chartContainer.innerHTML = '';
      
      data.distribution.forEach(item => {
        const emotionName = item.emotion.charAt(0).toUpperCase() + item.emotion.slice(1);
        const emotionLower = item.emotion.toLowerCase();
        
        const barDiv = document.createElement('div');
        barDiv.className = 'sentiment-bar';
        barDiv.innerHTML = '<div class="sentiment-label">' +
          '<span class="sentiment-name">' + emotionName + '</span>' +
          '<span class="sentiment-count">' + item.count + '</span>' +
          '</div>' +
          '<div class="bar-container">' +
          '<div class="bar-fill sentiment-' + emotionLower + '" ' +
          'style="width: ' + item.percentage + '%" ' +
          'data-percentage="' + item.percentage + '%">' +
          '</div>' +
          '</div>';
        chartContainer.appendChild(barDiv);
      });
    }

    function renderJournalSentimentChart(data) {
      const chartContainer = document.querySelector('.journal-sentiment-chart');
      if (!chartContainer) {
        return;
      }

      if (!data.success || !data.distribution || data.distribution.length === 0) {
        chartContainer.innerHTML = '<p class="muted">No sentiment data available yet. Keep journaling!</p>';
        return;
      }

      chartContainer.innerHTML = '';
      
      data.distribution.forEach(item => {
        const sentimentName = item.sentiment.charAt(0).toUpperCase() + item.sentiment.slice(1);
        const sentimentLower = item.sentiment.toLowerCase();
        
        const barDiv = document.createElement('div');
        barDiv.className = 'sentiment-bar';
        barDiv.innerHTML = '<div class="sentiment-label">' +
          '<span class="sentiment-name">' + sentimentName + '</span>' +
          '<span class="sentiment-count">' + item.count + '</span>' +
          '</div>' +
          '<div class="bar-container">' +
          '<div class="bar-fill sentiment-' + sentimentLower + '" ' +
          'style="width: ' + item.percentage + '%" ' +
          'data-percentage="' + item.percentage + '%">' +
          '</div>' +
          '</div>';
        chartContainer.appendChild(barDiv);
      });
    }

    function renderRecentActivity(data) {
      const activityList = document.querySelector('.activity-list');
      if (!activityList) {
        return;
      }

      if (!data.success || !data.activity || data.activity.length === 0) {
        activityList.innerHTML = '<p class="muted">No recent activity. Start journaling to see your progress!</p>';
        return;
      }

      activityList.innerHTML = '';
      data.activity.slice(0, 10).forEach(activity => {
        const activityItem = document.createElement('div');
        activityItem.className = 'activity-item';
        
        let entryText = 'entries';
        if (activity.count === 1) {
          entryText = 'entry';
        }
        
        activityItem.innerHTML = '<div class=\"activity-date\">' + activity.entry_date + '</div>' +
          '<div class=\"activity-bar-wrapper\">' +
          '<div class=\"activity-bar\" style=\"width: ' + Math.min(activity.count * 20, 100) + '%\"></div>' +
          '</div>' +
          '<div class=\"activity-count\">' + activity.count + ' ' + entryText + '</div>';
        activityList.appendChild(activityItem);
      });
    }

    function renderTags(data) {
      const tagCloud = document.getElementById('tagCloud');
      const noTagsMessage = document.getElementById('noTagsMessage');
      
      if (!tagCloud) {
        return;
      }

      if (!data.success || !data.tags || data.tags.length === 0) {
        if (noTagsMessage) {
          noTagsMessage.style.display = 'block';
        }
        return;
      }

      const tagCounts = {};
      
      data.tags.forEach(entry => {
        const tagsStr = entry.tags;
        if (tagsStr && tagsStr.trim() && tagsStr !== '[]' && tagsStr !== 'null') {
          try {
            const tags = JSON.parse(tagsStr);
            if (Array.isArray(tags)) {
              tags.forEach(tag => {
                if (tag && typeof tag === 'string') {
                  const cleanTag = tag.replace(/^[#\[\]"']+|[#\[\]"']+$/g, '').trim();
                  if (cleanTag && cleanTag.length > 0) {
                    tagCounts[cleanTag] = (tagCounts[cleanTag] || 0) + 1;
                  }
                }
              });
            }
          } catch (e) {
            console.error('Error parsing tags:', e);
          }
        }
      });

      const sortedTags = Object.entries(tagCounts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 20);

      if (sortedTags.length > 0) {
        if (noTagsMessage) {
          noTagsMessage.style.display = 'none';
        }
        
        const maxCount = Math.max(...sortedTags.map(t => t[1]));
        
        sortedTags.forEach(([tag, count]) => {
          const size = Math.max(0.8, Math.min(2, count / maxCount * 1.5));
          const tagEl = document.createElement('span');
          tagEl.className = 'tag-item';
          tagEl.textContent = '#' + tag;
          tagEl.style.fontSize = size + 'rem';
          tagEl.style.opacity = 0.6 + (count / maxCount * 0.4);
          tagEl.title = count + ' ' + (count === 1 ? 'use' : 'uses');
          tagCloud.appendChild(tagEl);
        });
      }
    }

    function renderEngagementScore(journalData, chatData) {
      const scoreEl = document.querySelector('.engagement-stat-value');
      if (!scoreEl) {
        return;
      }

      let weekEntries = 0;
      if (journalData.success && journalData.stats.week_entries) {
        weekEntries = journalData.stats.week_entries;
      }
      
      let weekMessages = 0;
      if (chatData.success && chatData.stats.week_messages) {
        weekMessages = chatData.stats.week_messages;
      }
      
      const entryScore = weekEntries * 10;
      const messageScore = weekMessages / 2;
      const totalScore = entryScore + messageScore;
      const score = Math.min(100, Math.round(totalScore));
      
      scoreEl.textContent = score;
    }

    function renderAchievements(journalData, chatData) {
      const weekStreak = document.getElementById('achievementWeekStreak');
      const dedicatedWriter = document.getElementById('achievementDedicatedWriter');
      const conversationalist = document.getElementById('achievementConversationalist');

      if (journalData.success && journalData.stats) {
        const stats = journalData.stats;
        
        if (weekStreak && stats.week_entries >= 7) {
          weekStreak.classList.add('unlocked');
          weekStreak.classList.remove('locked');
        }
        
        if (dedicatedWriter && stats.total_entries >= 50) {
          dedicatedWriter.classList.add('unlocked');
          dedicatedWriter.classList.remove('locked');
        }
      }

      if (chatData.success && chatData.stats) {
        const stats = chatData.stats;
        
        if (conversationalist && stats.total_sessions >= 10) {
          conversationalist.classList.add('unlocked');
          conversationalist.classList.remove('locked');
        }
      }
    }

    function renderEngagementPatterns(data) {
      if (!data.success || !data.patterns) {
        return;
      }
      
      const patterns = data.patterns;
      
      // Update morning pattern
      const morningBar = document.querySelector('.pattern-item:nth-child(1) .pattern-fill');
      if (morningBar && patterns.morning) {
        morningBar.style.width = patterns.morning.percentage + '%';
      }
      
      // Update afternoon pattern
      const afternoonBar = document.querySelector('.pattern-item:nth-child(2) .pattern-fill');
      if (afternoonBar && patterns.afternoon) {
        afternoonBar.style.width = patterns.afternoon.percentage + '%';
      }
      
      // Update evening pattern
      const eveningBar = document.querySelector('.pattern-item:nth-child(3) .pattern-fill');
      if (eveningBar && patterns.evening) {
        eveningBar.style.width = patterns.evening.percentage + '%';
      }
    }

    function renderEmotionTrends(data) {
      const trendsContainer = document.querySelector('#emotionTrendsChart');
      if (!trendsContainer) {
        return;
      }

      if (!data.success || !data.dates || data.dates.length === 0) {
        trendsContainer.innerHTML = '<p class=\"muted\">No emotion trend data available yet. Keep chatting to track your emotional journey!</p>';
        return;
      }

      // Creating line chart
      const dates = data.dates;
      const emotions = data.emotions;
      const series = data.series;

      // Define colors for emotions
      const emotionColors = {
        'happy': '#4CAF50',
        'sad': '#2196F3',
        'angry': '#F44336',
        'neutral': '#9E9E9E',
        'fear': '#9C27B0',
        'surprise': '#FF9800',
        'disgust': '#795548'
      };

      trendsContainer.innerHTML = '';

      // legend (chat styled it)
      const legend = document.createElement('div');
      legend.className = 'trend-legend';
      legend.style.cssText = 'display: flex; gap: 15px; margin-bottom: 20px; flex-wrap: wrap;';

      emotions.forEach(emotion => {
        const legendItem = document.createElement('div');
        legendItem.style.cssText = 'display: flex; align-items: center; gap: 5px;';
        const colorBox = document.createElement('div');
        colorBox.style.cssText = 'width: 12px; height: 12px; background-color: ' + (emotionColors[emotion.toLowerCase()] || '#666') + '; border-radius: 2px;';
        const label = document.createElement('span');
        label.textContent = emotion.charAt(0).toUpperCase() + emotion.slice(1);
        label.style.fontSize = '0.9rem';
        legendItem.appendChild(colorBox);
        legendItem.appendChild(label);
        legend.appendChild(legendItem);
      });

      trendsContainer.appendChild(legend);

      // chart area
      const chartArea = document.createElement('div');
      chartArea.className = 'trend-chart-area';
      chartArea.style.cssText = 'position: relative; height: 300px; border-left: 2px solid #ddd; border-bottom: 2px solid #ddd; padding: 10px;';

      // max value to scale chart
      let maxValue = 0;
      emotions.forEach(emotion => {
        const values = series[emotion];
        const max = Math.max(...values);
        if (max > maxValue) {
          maxValue = max;
        }
      });
      if (maxValue === 0) {
        maxValue = 1;
      }

      // canvas for lines
      const canvas = document.createElement('canvas');
      canvas.width = 800;
      canvas.height = 280;
      canvas.style.cssText = 'width: 100%; height: 100%;';
      chartArea.appendChild(canvas);
      const ctx = canvas.getContext('2d');
      const width = canvas.width;
      const height = canvas.height;
      const padding = 40;
      const chartWidth = width - padding * 2;
      const chartHeight = height - padding * 2;

      // grid lines
      ctx.strokeStyle = '#eee';
      ctx.lineWidth = 1;
      for (let i = 0; i <= 5; i++) {
        const y = padding + (chartHeight / 5) * i;
        ctx.beginPath();
        ctx.moveTo(padding, y);
        ctx.lineTo(width - padding, y);
        ctx.stroke();
      }

      // emotion lines
      emotions.forEach(emotion => {
        const values = series[emotion];
        const color = emotionColors[emotion.toLowerCase()] || '#666';
        
        ctx.strokeStyle = color;
        ctx.lineWidth = 2;
        ctx.beginPath();
        values.forEach((value, index) => {
          const x = padding + (chartWidth / (dates.length - 1 || 1)) * index;
          const y = height - padding - (value / maxValue) * chartHeight;
          if (index === 0) {
            ctx.moveTo(x, y);
          } else {
            ctx.lineTo(x, y);
          }
        });

        ctx.stroke();

        // points
        ctx.fillStyle = color;
        values.forEach((value, index) => {
          const x = padding + (chartWidth / (dates.length - 1 || 1)) * index;
          const y = height - padding - (value / maxValue) * chartHeight;
          ctx.beginPath();
          ctx.arc(x, y, 4, 0, Math.PI * 2);
          ctx.fill();
        });
      });

      // Draw date labels 
      ctx.fillStyle = '#666';
      ctx.font = '11px sans-serif';
      ctx.textAlign = 'center';
      const labelStep = Math.ceil(dates.length / 6);
      dates.forEach((date, index) => {
        if (index % labelStep === 0 || index === dates.length - 1) {
          const x = padding + (chartWidth / (dates.length - 1 || 1)) * index;
          const shortDate = date.substring(5);
          ctx.fillText(shortDate, x, height - 10);
        }
      });

      trendsContainer.appendChild(chartArea);
    }

    // Load all data when page loads
    document.addEventListener('DOMContentLoaded', loadAnalyticsData);
  </script>

  <!-- Sidebar -->
  <aside class="sidebar">
    <div class="brand">
      <div class="logo" aria-hidden="true"></div>
      <h1>Looking Glass</h1>
    </div>

    <div class="analytics-nav">
      <h3 class="nav-title">Analytics</h3>
      <nav>
        <ul class="nav-list">
          <li><a href="#overview" class="nav-link active">Overview</a></li>
          <li><a href="#journal-insights" class="nav-link">Journal Insights</a></li>
          <li><a href="#chat-insights" class="nav-link">Chat Insights</a></li>
          <li><a href="#trends" class="nav-link">Trends</a></li>
          <li><a href="#resources" class="nav-link">Recommended Resources</a></li>
        </ul>
      </nav>
    </div>

    <div class="sidebar-info">
      <div class="info-card">
        <div class="info-icon">📊</div>
        <div class="info-content">
          <h4>Your Progress</h4>
          <p class="muted">Track your wellness journey with detailed insights</p>
        </div>
      </div>
    </div>

    <div class="footer">Your data is private and secure</div>
  </aside>

  <!-- Header -->
  <header class="header">
    <div class="controls">
      <h2 class="page-title">Analytics Dashboard</h2>
    </div>
    <div class="controls">
      <select id="timeRange" class="input-sm">
        <option value="7">Last 7 days</option>
        <option value="30" selected>Last 30 days</option>
        <option value="90">Last 90 days</option>
        <option value="365">Last year</option>
      </select>
    </div>
  </header>

  <!-- Main Content -->
  <main>
    <!-- Overview Section -->
    <section id="overview" class="analytics-section">
      <h2 class="section-title">Overview</h2>
      
      <div class="stats-grid">
        <!-- Journal Stats -->
        <div class="stat-card">
          <div class="stat-icon journal-icon">📝</div>
          <div class="stat-content">
            <h3 class="stat-label">Total Journal Entries</h3>
            <p class="stat-value journal-stat-value">0</p>
            <p class="stat-meta muted journal-stat-meta">Loading...</p>
          </div>
        </div>

        <!-- Chat Stats -->
        <div class="stat-card">
          <div class="stat-icon chat-icon">💬</div>
          <div class="stat-content">
            <h3 class="stat-label">Chat Sessions</h3>
            <p class="stat-value chat-stat-value">0</p>
            <p class="stat-meta muted chat-stat-meta">Loading...</p>
          </div>
        </div>

        <!-- Activity Stats -->
        <div class="stat-card">
          <div class="stat-icon activity-icon">📈</div>
          <div class="stat-content">
            <h3 class="stat-label">Activity This Month</h3>
            <p class="stat-value activity-stat-value">0</p>
            <p class="stat-meta muted">Journal entries logged</p>
          </div>
        </div>

        <!-- Engagement Score -->
        <div class="stat-card">
          <div class="stat-icon engagement-icon">⭐</div>
          <div class="stat-content">
            <h3 class="stat-label">Engagement Score</h3>
            <p class="stat-value engagement-stat-value">0</p>
            <p class="stat-meta muted">Keep up the great work!</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Journal Insights Section -->
    <section id="journal-insights" class="analytics-section">
      <h2 class="section-title">Journal Insights</h2>
      
      <div class="insights-grid">
        <!-- Journal Sentiment Distribution -->
        <div class="insight-card">
          <div class="card-header">
            <h3>Sentiment Distribution</h3>
            <span class="muted">How you've been feeling in your journal</span>
          </div>
          <div class="card-body">
            <div class="journal-sentiment-chart">
              <p class="muted">Loading sentiment data...</p>
            </div>
          </div>
        </div>

        <!-- Activity Heatmap -->
        <div class="insight-card">
          <div class="card-header">
            <h3>Recent Activity</h3>
            <span class="muted">Last 30 days</span>
          </div>
          <div class="card-body">
            <div class="activity-list">
              <p class="muted">Loading activity data...</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Tag Cloud -->
      <div class="insight-card full-width">
        <div class="card-header">
          <h3>Popular Tags</h3>
          <span class="muted">Your most used topics</span>
        </div>
        <div class="card-body">
          <div class="tag-cloud" id="tagCloud">
            <c:if test="${not empty topTags.rows}">
              <!-- Tags will be processed and rendered by JavaScript -->
              <c:forEach var="entry" items="${topTags.rows}">
                <span class="tag-data" data-tags='<c:out value="${entry.tags}" escapeXml="true"/>' style="display:none;"></span>
              </c:forEach>
            </c:if>
            <p class="muted" id="noTagsMessage">No tags found yet. Try adding tags to your journal entries!</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Chat Insights Section -->
    <section id="chat-insights" class="analytics-section">
      <h2 class="section-title">Chat Insights</h2>
      
      <div class="insights-grid">
        <!-- Chat Emotion Distribution -->
        <div class="insight-card">
          <div class="card-header">
            <h3>Emotion Distribution</h3>
            <span class="muted">Emotions detected in your conversations</span>
          </div>
          <div class="card-body">
            <div class="chat-emotion-chart">
              <p class="muted">Loading emotion data...</p>
            </div>
          </div>
        </div>

        <!-- Conversation Metrics -->
        <div class="insight-card">
          <div class="card-header">
            <h3>Conversation Metrics</h3>
            <span class="muted">Your chat activity</span>
          </div>
          <div class="card-body">
            <div class="metric-list">
              <p class="muted">Loading chat metrics...</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Engagement Patterns -->
      <div class="insight-card full-width">
        <div class="card-header">
          <h3>Engagement Patterns</h3>
          <span class="muted">When you're most active</span>
        </div>
        <div class="card-body">
          <div class="pattern-visualization">
            <div class="pattern-item">
              <div class="pattern-icon">🌅</div>
              <div class="pattern-info">
                <span class="pattern-label">Morning</span>
                <span class="pattern-bar">
                  <span class="pattern-fill" style="width: 35%"></span>
                </span>
              </div>
            </div>
            <div class="pattern-item">
              <div class="pattern-icon">☀️</div>
              <div class="pattern-info">
                <span class="pattern-label">Afternoon</span>
                <span class="pattern-bar">
                  <span class="pattern-fill" style="width: 65%"></span>
                </span>
              </div>
            </div>
            <div class="pattern-item">
              <div class="pattern-icon">🌙</div>
              <div class="pattern-info">
                <span class="pattern-label">Evening</span>
                <span class="pattern-bar">
                  <span class="pattern-fill" style="width: 45%"></span>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Trends Section -->
    <section id="trends" class="analytics-section">
      <h2 class="section-title">Trends & Growth</h2>
      
      <div class="insight-card full-width">
        <div class="card-header">
          <h3>Emotional Trends Chart</h3>
          <span class="muted">Your emotional journey over the last 30 days</span>
        </div>
        <div class="card-body">
          <div id="emotionTrendsChart">
            <p class="muted">Loading emotion trends...</p>
          </div>
        </div>
      </div>
      <!-- Achievement Cards -->
      <div class="achievements-grid">
        <div class="achievement-card">
          <div class="achievement-icon">🏆</div>
          <h4>First Steps</h4>
          <p class="muted">Created your first journal entry</p>
        </div>
        <div id="achievementWeekStreak" class="achievement-card locked">
          <div class="achievement-icon">🔥</div>
          <h4>Week Streak</h4>
          <p class="muted">Journaled 7 days in a row</p>
        </div>
        <div id="achievementDedicatedWriter" class="achievement-card locked">
          <div class="achievement-icon">📚</div>
          <h4>Dedicated Writer</h4>
          <p class="muted">Reached 50 journal entries</p>
        </div>
        <div id="achievementConversationalist" class="achievement-card locked">
          <div class="achievement-icon">💭</div>
          <h4>Conversationalist</h4>
          <p class="muted">Completed 10 chat sessions</p>
        </div>
      </div>
    </section>


     <!-- Recommended Resources Section TO BE FINISHED-->
      <section id="Resources" class = "resources-section">
        <h2 class ="section-title">Recommended Resources</h2>
        <div class="resources-grid">

      </section>






  </main>

  <!-- JavaScript for dynamic features -->
  <script>
    (function() {
      // Process and render tag cloud
      const tagDataElements = document.querySelectorAll('.tag-data');
      const tagCloud = document.getElementById('tagCloud');
      const noTagsMessage = document.getElementById('noTagsMessage');
      
      if (tagDataElements.length > 0) {
        const tagCounts = {};
        
        // Helper function to clean individual tags
        function cleanTag(tag) {
          if (!tag || typeof tag !== 'string') {
            return null;
          }
          const cleaned = tag.replace(/^[#\[\]"']+|[#\[\]"']+$/g, '').trim();
          return cleaned.length > 0 ? cleaned : null;
        }
        
        // Helper function to count tags from an array
        function countTags(tags) {
          tags.forEach(tag => {
            const cleaned = cleanTag(tag);
            if (cleaned) {
              if (!tagCounts[cleaned]) {
                tagCounts[cleaned] = 0;
              }
              tagCounts[cleaned]++;
            }
          });
        }
        
        // Process each tag data element
        tagDataElements.forEach(el => {
          const tagsStr = el.getAttribute('data-tags');
          
          // Skip empty or invalid tag strings
          if (!tagsStr || !tagsStr.trim() || tagsStr === '[]' || tagsStr === 'null') {
            return;
          }
          
          // Try parsing as JSON first
          try {
            const tags = JSON.parse(tagsStr);
            if (Array.isArray(tags)) {
              countTags(tags);
            }
          } catch (e) {
            console.error('Error parsing tags:', e);
            // Fallback: try comma-separated format
            const tags = tagsStr.split(',').map(t => t.trim()).filter(t => t);
            countTags(tags);
          }
        });
        
        // Sort tags by count
        const sortedTags = Object.entries(tagCounts)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 20);
        
        if (sortedTags.length > 0) {
          noTagsMessage.style.display = 'none';
          
          // Find max count for sizing
          const maxCount = Math.max(...sortedTags.map(t => t[1]));
          
          // Render tags
          sortedTags.forEach(([tag, count]) => {
            // Calculate relative size (0.8 to 2 rem)
            const relativeSize = (count / maxCount) * 1.5;
            const fontSize = Math.max(0.8, Math.min(2, relativeSize));
            
            // Calculate opacity (0.6 to 1.0)
            const relativeOpacity = (count / maxCount) * 0.4;
            const opacity = 0.6 + relativeOpacity;
            
            // Create tag element
            const tagEl = document.createElement('span');
            tagEl.className = 'tag-item';
            tagEl.textContent = '#' + tag;
            tagEl.style.fontSize = fontSize + 'rem';
            tagEl.style.opacity = opacity;
            
            // Set tooltip with usage count
            const useText = count === 1 ? 'use' : 'uses';
            tagEl.title = count + ' ' + useText;
            
            tagCloud.appendChild(tagEl);
          });
        }
      }

      // Smooth scroll for navigation
      document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', function(e) {
          e.preventDefault();
          const targetId = this.getAttribute('href').substring(1);
          const target = document.getElementById(targetId);
          
          if (target) {
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
            
            // Update active state
            document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
            this.classList.add('active');
          }
        });
      });

      // Time range selector (placeholder for future implementation)
      document.getElementById('timeRange').addEventListener('change', function() {
        console.log('Time range changed to:', this.value, 'days');
        // Future: Implement AJAX call to reload data with new time range
      });

      // Add animation on scroll
      const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
      };

      const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            entry.target.classList.add('fade-in');
          }
        });
      }, observerOptions);

      document.querySelectorAll('.stat-card, .insight-card, .achievement-card').forEach(el => {
        observer.observe(el);
      });
    })();
  </script>
</body>
</html>
