import os
import mysql.connector
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
from datetime import datetime, timedelta

load_dotenv()

app = Flask(__name__)
CORS(app)
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASS', ''),
    'database': os.getenv('DB_NAME', 'lookingglass')
}
def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)

#EMOTION DISTRIBUTION PANEL (CHAT)
@app.route('/analytics/emotion-distribution/<int:uid>', methods=['GET'])
def get_emotion_distribution(uid):
    #get emotions per user from chat messages
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT 
                cm.dominantEmotion as emotion,
                COUNT(*) as count
            FROM chat_messages cm
            INNER JOIN chat_sessions cs ON cm.chatID = cs.chatID
            WHERE cs.uid = %s
              AND cm.dominantEmotion IS NOT NULL 
              AND cm.dominantEmotion != ''
              AND cm.role = 'user'
            GROUP BY cm.dominantEmotion
            ORDER BY count DESC
        """, (uid,))
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        # Getting totals and percentages
        total = sum(row['count'] for row in results)
        distribution = []
        for row in results:
            if total > 0:
                percentage = (row['count'] * 100) / total
            else:
                percentage = 0
            distribution.append({
                'emotion': row['emotion'],
                'count': row['count'],
                'percentage': round(percentage, 1)
            })
        return jsonify({
            'success': True,
            'total': total,
            'distribution': distribution
        })
    except Exception as e:
        print(f"Error in chat stats emotion distribution: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


#JOURNAL SENTIMENT DISTRIBUTION PANEL
@app.route('/analytics/journal-sentiment/<int:uid>', methods=['GET'])
def get_journal_sentiment(uid):
    #get sentiment distribution from journal entries
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT 
                CASE 
                    WHEN sentiment >= 0.7 THEN 'positive'
                    WHEN sentiment <= 0.3 THEN 'negative'
                    ELSE 'neutral'
                END as sentiment_category,
                COUNT(*) as count
            FROM journals
            WHERE uid = %s AND sentiment IS NOT NULL
            GROUP BY sentiment_category
            ORDER BY count DESC
        """, (uid,))
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        # Getting totals and percentages
        total = sum(row['count'] for row in results)
        distribution = []
        for row in results:
            if total > 0:
                percentage = (row['count'] * 100) / total
            else:
                percentage = 0
            distribution.append({
                'sentiment': row['sentiment_category'],
                'count': row['count'],
                'percentage': round(percentage, 1)
            })
        return jsonify({
            'success': True,
            'total': total,
            'distribution': distribution
        })
    except Exception as e:
        print(f"Error in journal sentiment distribution: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


#JOURNAL STATS DATES PANEL
@app.route('/analytics/journal-stats/<int:uid>', methods=['GET'])
def get_journal_stats(uid):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        seven_days_ago = datetime.now() - timedelta(days=7)
        thirty_days_ago = datetime.now() - timedelta(days=30)
        
        cursor.execute("""
            SELECT 
                COUNT(*) as total_entries,
                SUM(CASE WHEN time >= %s THEN 1 ELSE 0 END) as week_entries,
                SUM(CASE WHEN time >= %s THEN 1 ELSE 0 END) as month_entries
            FROM journals
            WHERE uid = %s
        """, (seven_days_ago, thirty_days_ago, uid))
        stats = cursor.fetchone()
        cursor.close()
        conn.close()
        return jsonify({
            'success': True,
            'stats': stats
        })
    except Exception as e:
        print(f"Error in journal stats dates: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


#CHAT STATS DATES PANEL
@app.route('/analytics/chat-stats/<int:uid>', methods=['GET'])
def get_chat_stats(uid):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        seven_days_ago = datetime.now() - timedelta(days=7)
        cursor.execute("""
            SELECT 
                COUNT(DISTINCT cs.chatID) as total_sessions,
                COUNT(cm.messageID) as total_messages,
                SUM(CASE WHEN cm.created_at >= %s THEN 1 ELSE 0 END) as week_messages
            FROM chat_sessions cs
            LEFT JOIN chat_messages cm ON cs.chatID = cm.chatID
            WHERE cs.uid = %s
        """, (seven_days_ago, uid))
        stats = cursor.fetchone()
        cursor.close()
        conn.close()
        return jsonify({
            'success': True,
            'stats': stats
        })
    except Exception as e:
        print(f"Error in chat stats dates: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


#RECENT ACTIVITY PANEL
@app.route('/analytics/recent-activity/<int:uid>', methods=['GET'])
def get_recent_activity(uid):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        thirty_days_ago = datetime.now() - timedelta(days=30)
        cursor.execute("""
            SELECT 
                DATE(time) as entry_date,
                COUNT(*) as count
            FROM journals
            WHERE uid = %s AND time >= %s
            GROUP BY DATE(time)
            ORDER BY entry_date DESC
        """, (uid, thirty_days_ago))
        activity = cursor.fetchall()
        cursor.close()
        conn.close()
        # Formating dates
        for entry in activity:
            entry['entry_date'] = entry['entry_date'].strftime('%Y-%m-%d')
        return jsonify({
            'success': True,
            'activity': activity
        })
    except Exception as e:
        print(f"Error in recent activity stats: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


#MOOD TRACKING PANEL
@app.route('/analytics/mood-tracking/<int:uid>', methods=['GET'])
def get_mood_tracking(uid):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        fourteen_days_ago = datetime.now() - timedelta(days=14)
        cursor.execute("""
            SELECT 
                DATE(time) as entry_date,
                data as mood_data,
                userGivenMood
            FROM journals
            WHERE uid = %s AND time >= %s
            ORDER BY time ASC
        """, (uid, fourteen_days_ago))
        moods = cursor.fetchall()
        cursor.close()
        conn.close()
        # Format dates
        for entry in moods:
            entry['entry_date'] = entry['entry_date'].strftime('%Y-%m-%d')
        return jsonify({
            'success': True,
            'moods': moods
        })
    except Exception as e:
        print(f"Error in mood tracking panel: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


#TOP TAGS PANEL
@app.route('/analytics/top-tags/<int:uid>', methods=['GET'])
def get_top_tags(uid):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT tags
            FROM journals
            WHERE uid = %s AND tags IS NOT NULL AND tags != ''
            LIMIT 100
        """, (uid,))
        
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True,
            'tags': results
        })
    except Exception as e:
        print(f"Error in top tags panel: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


#ENGAGEMENT PATTERNS PANEL
@app.route('/analytics/engagement-patterns/<int:uid>', methods=['GET'])
def get_engagement_patterns(uid):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Query journal entries and chat messages grouped by time of day
        cursor.execute("""
            SELECT 
                CASE 
                    WHEN HOUR(time) >= 5 AND HOUR(time) < 12 THEN 'morning'
                    WHEN HOUR(time) >= 12 AND HOUR(time) < 18 THEN 'afternoon'
                    ELSE 'evening'
                END as time_of_day,
                COUNT(*) as count
            FROM journals
            WHERE uid = %s
            GROUP BY time_of_day
        """, (uid,))
        
        journal_results = cursor.fetchall()
        
        # Also get chat activity patterns
        cursor.execute("""
            SELECT 
                CASE 
                    WHEN HOUR(cm.created_at) >= 5 AND HOUR(cm.created_at) < 12 THEN 'morning'
                    WHEN HOUR(cm.created_at) >= 12 AND HOUR(cm.created_at) < 18 THEN 'afternoon'
                    ELSE 'evening'
                END as time_of_day,
                COUNT(*) as count
            FROM chat_messages cm
            INNER JOIN chat_sessions cs ON cm.chatID = cs.chatID
            WHERE cs.uid = %s AND cm.role = 'user'
            GROUP BY time_of_day
        """, (uid,))
        
        chat_results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        # Combine journal and chat activity
        combined = {'morning': 0, 'afternoon': 0, 'evening': 0}
        
        for row in journal_results:
            combined[row['time_of_day']] += row['count']
        
        for row in chat_results:
            combined[row['time_of_day']] += row['count']
        
        # Calculate percentages
        total = sum(combined.values())
        patterns = {}
        
        if total > 0:
            for period, count in combined.items():
                patterns[period] = {
                    'count': count,
                    'percentage': round((count * 100) / total, 1)
                }
        else:
            # Default if no data
            patterns = {
                'morning': {'count': 0, 'percentage': 0},
                'afternoon': {'count': 0, 'percentage': 0},
                'evening': {'count': 0, 'percentage': 0}
            }
        
        return jsonify({
            'success': True,
            'patterns': patterns,
            'total_activities': total
        })
    except Exception as e:
        print(f"Error in engagement patterns: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


#EMOTIONAL TRENDS OVER TIME (COMBINED JOURNAL + CHAT)
@app.route('/analytics/emotion-trends/<int:uid>', methods=['GET'])
def get_emotion_trends(uid):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        thirty_days_ago = datetime.now() - timedelta(days=30)
        
        # Get dominant emotions from chat messages grouped by date
        cursor.execute("""
            SELECT 
                DATE(cm.created_at) as trend_date,
                cm.dominantEmotion as emotion,
                COUNT(*) as count
            FROM chat_messages cm
            INNER JOIN chat_sessions cs ON cm.chatID = cs.chatID
            WHERE cs.uid = %s 
              AND cm.created_at >= %s
              AND cm.dominantEmotion IS NOT NULL 
              AND cm.dominantEmotion != ''
              AND cm.role = 'user'
            GROUP BY DATE(cm.created_at), cm.dominantEmotion
            ORDER BY trend_date ASC
        """, (uid, thirty_days_ago))
        
        chat_results = cursor.fetchall()
        
        # Get journal sentiment and convert to emotion categories
        cursor.execute("""
            SELECT 
                DATE(time) as trend_date,
                CASE 
                    WHEN sentiment >= 0.7 THEN 'happy'
                    WHEN sentiment <= 0.3 THEN 'sad'
                    ELSE 'neutral'
                END as emotion,
                COUNT(*) as count
            FROM journals
            WHERE uid = %s 
              AND time >= %s
              AND sentiment IS NOT NULL
            GROUP BY DATE(time), emotion
            ORDER BY trend_date ASC
        """, (uid, thirty_days_ago))
        
        journal_results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        # Combine chat and journal data
        trends_by_date = {}
        all_emotions = set()
        
        # Process chat emotions
        for row in chat_results:
            date_str = row['trend_date'].strftime('%Y-%m-%d')
            emotion = row['emotion'].lower() if row['emotion'] else 'neutral'
            count = row['count']
            
            if date_str not in trends_by_date:
                trends_by_date[date_str] = {}
            
            if emotion not in trends_by_date[date_str]:
                trends_by_date[date_str][emotion] = 0
            
            trends_by_date[date_str][emotion] += count
            all_emotions.add(emotion)
        
        # Process journal sentiments
        for row in journal_results:
            date_str = row['trend_date'].strftime('%Y-%m-%d')
            emotion = row['emotion'].lower() if row['emotion'] else 'neutral'
            count = row['count']
            
            if date_str not in trends_by_date:
                trends_by_date[date_str] = {}
            
            if emotion not in trends_by_date[date_str]:
                trends_by_date[date_str][emotion] = 0
            
            trends_by_date[date_str][emotion] += count
            all_emotions.add(emotion)
        
        # Convert to array format for charting
        dates = sorted(trends_by_date.keys())
        emotion_series = {}
        
        for emotion in all_emotions:
            emotion_series[emotion] = []
            for date in dates:
                count = trends_by_date[date].get(emotion, 0)
                emotion_series[emotion].append(count)
        
        return jsonify({
            'success': True,
            'dates': dates,
            'emotions': list(all_emotions),
            'series': emotion_series
        })
    except Exception as e:
        print(f"Error in emotion trends: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5003, debug=True)
