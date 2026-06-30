import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/learning.dart';
import '../models/learning_category.dart';
import 'profile_service.dart';
import 'ai_learning_service.dart';

class LearningTrackerService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();
  final AiLearningService _aiLearningService = AiLearningService();

  // Add daily learning log with AI categorization
  Future<DailyLearningLog> addDailyLog({
    required String userId,
    required String topic,
    String? description,
    int timeSpentMinutes = 30,
    String difficultyLevel = 'medium',
    List<String> resourcesUsed = const [],
    String? codeSnippets,
  }) async {
    try {
      await _profileService.ensureUserProfile(userId, 'User');

      // Get AI analysis of the learning topic
      final aiAnalysis = await _aiLearningService.analyzeLearningTopic(topic, description);

      final data = {
        'user_id': userId,
        'date': DateTime.now().toIso8601String().split('T').first,
        'topic': topic,
        'description': description,
        'time_spent_minutes': timeSpentMinutes,
        'difficulty_level': difficultyLevel,
        'resources_used': resourcesUsed,
        'code_snippets': codeSnippets,
        'category': aiAnalysis.category,
        'subcategory': aiAnalysis.subcategory,
        'ai_analysis': aiAnalysis.toJson(),
      };

      final response = await _supabase
          .from('daily_learning_logs')
          .insert(data)
          .select()
          .single();

      // Generate recommendations and update learning path
      await _generateRecommendations(userId, topic, aiAnalysis);
      await _updateLearningPath(userId, aiAnalysis);
      await _updateLearningStats(userId);

      return DailyLearningLog.fromJson(response);
    } catch (e) {
      print('Error adding daily log: $e');
      throw Exception('Failed to add learning log: $e');
    }
  }

  // Update learning path based on AI analysis
  Future<void> _updateLearningPath(String userId, AIAnalysis analysis) async {
    try {
      final existingPath = await _supabase
          .from('learning_paths')
          .select()
          .eq('user_id', userId)
          .eq('category', analysis.category)
          .maybeSingle();

      final categoryLogs = await _supabase
          .from('daily_learning_logs')
          .select()
          .eq('user_id', userId)
          .eq('category', analysis.category);

      final topics = categoryLogs.map((log) => log['topic'] as String).toList();
      final progress = topics.length / 10;

      if (existingPath == null) {
        await _supabase.from('learning_paths').insert({
          'user_id': userId,
          'category': analysis.category,
          'recommended_topics': analysis.nextRecommendations,
          'prerequisites': analysis.prerequisites,
          'next_steps': analysis.nextRecommendations,
          'progress': progress > 1.0 ? 1.0 : progress,
        });
      } else {
        final existingRecommendations = (existingPath['recommended_topics'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final newRecommendations = [...existingRecommendations, ...analysis.nextRecommendations].toSet().toList();

        await _supabase
            .from('learning_paths')
            .update({
          'recommended_topics': newRecommendations,
          'prerequisites': analysis.prerequisites,
          'next_steps': newRecommendations.take(5).toList(),
          'progress': progress > 1.0 ? 1.0 : progress,
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('id', existingPath['id']);
      }
    } catch (e) {
      print('Error updating learning path: $e');
    }
  }

  // Get all logs for a user
  Future<List<DailyLearningLog>> getDailyLogs(String userId) async {
    try {
      final response = await _supabase
          .from('daily_learning_logs')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => DailyLearningLog.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting daily logs: $e');
      throw Exception('Failed to get learning logs: $e');
    }
  }

  // Get logs for a specific date range
  Future<List<DailyLearningLog>> getLogsByDateRange(
      String userId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final response = await _supabase
          .from('daily_learning_logs')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T').first)
          .lte('date', endDate.toIso8601String().split('T').first)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => DailyLearningLog.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting logs by date range: $e');
      throw Exception('Failed to get learning logs: $e');
    }
  }

  // Generate recommendations based on learning history
  Future<void> _generateRecommendations(
      String userId,
      String topic,
      AIAnalysis analysis,
      ) async {
    try {
      final logs = await getDailyLogs(userId);
      final topics = logs.map((log) => log.topic).toList();
      final topicFrequency = <String, int>{};

      for (var t in topics) {
        topicFrequency[t] = (topicFrequency[t] ?? 0) + 1;
      }

      final recommendations = <Map<String, dynamic>>[];

      // Use AI recommendations
      for (var rec in analysis.nextRecommendations) {
        recommendations.add({
          'user_id': userId,
          'topic': rec,
          'reason': 'Based on your interest in ${analysis.category}',
          'priority': 'high',
        });
      }

      // Add related topics
      for (var related in analysis.relatedTopics) {
        recommendations.add({
          'user_id': userId,
          'topic': related,
          'reason': 'Related to ${analysis.subcategory}',
          'priority': 'medium',
        });
      }

      // Add prerequisites
      for (var prereq in analysis.prerequisites) {
        recommendations.add({
          'user_id': userId,
          'topic': prereq,
          'reason': 'Prerequisite for ${analysis.subcategory}',
          'priority': 'high',
        });
      }

      // Add frequency-based recommendations
      if (topicFrequency.values.any((freq) => freq >= 3)) {
        final mostLearnedTopic = topicFrequency.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        if (mostLearnedTopic != topic) {
          recommendations.add({
            'user_id': userId,
            'topic': 'Deep Dive: $mostLearnedTopic',
            'reason': 'You\'ve been learning about $mostLearnedTopic frequently. Time to master it!',
            'priority': 'medium',
          });
        }
      }

      for (var rec in recommendations) {
        try {
          await _supabase.from('learning_recommendations').insert(rec);
        } catch (e) {
          print('Recommendation already exists or error: $e');
        }
      }
    } catch (e) {
      print('Error generating recommendations: $e');
    }
  }

  // Get recommendations for a user
  Future<List<LearningRecommendation>> getRecommendations(
      String userId, {
        bool includeCompleted = false,
      }) async {
    try {
      final query = _supabase
          .from('learning_recommendations')
          .select('*')
          .eq('user_id', userId)
          .order('priority', ascending: false);

      final response = await query;

      List<Map<String, dynamic>> filteredResponse =
      List<Map<String, dynamic>>.from(response);

      if (!includeCompleted) {
        filteredResponse = filteredResponse
            .where((rec) => rec['is_completed'] == false)
            .toList();
      }

      return filteredResponse
          .map((json) => LearningRecommendation.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting recommendations: $e');
      throw Exception('Failed to get recommendations: $e');
    }
  }

  // Mark recommendation as completed
  Future<void> completeRecommendation(String recommendationId) async {
    try {
      await _supabase
          .from('learning_recommendations')
          .update({'is_completed': true})
          .eq('id', recommendationId);
    } catch (e) {
      print('Error completing recommendation: $e');
      throw Exception('Failed to complete recommendation: $e');
    }
  }

  // Update learning stats
  Future<void> _updateLearningStats(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final todayLogs = await _supabase
          .from('daily_learning_logs')
          .select()
          .eq('user_id', userId)
          .eq('date', today);

      final totalTopics = todayLogs.length;
      final totalTime = todayLogs.fold<int>(
        0,
            (sum, log) => sum + (log['time_spent_minutes'] as int? ?? 0),
      );
      final topics = todayLogs.map((log) => log['topic'] as String).toList();

      final monthStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        1,
      ).toIso8601String().split('T').first;

      final monthlyLogs = await _supabase
          .from('daily_learning_logs')
          .select('date')
          .eq('user_id', userId)
          .gte('date', monthStart);

      final uniqueDays = monthlyLogs
          .map((log) => log['date'] as String)
          .toSet()
          .length;

      final daysInMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month + 1,
        0,
      ).day;
      final consistencyScore = uniqueDays / daysInMonth;

      await _supabase.from('learning_stats').upsert({
        'user_id': userId,
        'date': today,
        'total_topics_learned': totalTopics,
        'total_time_spent': totalTime,
        'topics': topics,
        'consistency_score': consistencyScore,
      });
    } catch (e) {
      print('Error updating learning stats: $e');
    }
  }

  // Get learning stats
  Future<List<LearningStats>> getLearningStats(String userId) async {
    try {
      final response = await _supabase
          .from('learning_stats')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(30);

      return (response as List)
          .map((json) => LearningStats.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting learning stats: $e');
      throw Exception('Failed to get learning stats: $e');
    }
  }

  // Get learning paths
  Future<List<LearningPath>> getLearningPaths(String userId) async {
    try {
      final response = await _supabase
          .from('learning_paths')
          .select()
          .eq('user_id', userId)
          .order('progress', ascending: false);

      return (response as List)
          .map((json) => LearningPath.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting learning paths: $e');
      throw Exception('Failed to get learning paths: $e');
    }
  }

  // Get learning path by category
  Future<LearningPath?> getLearningPathByCategory(String userId, String category) async {
    try {
      final response = await _supabase
          .from('learning_paths')
          .select()
          .eq('user_id', userId)
          .eq('category', category)
          .maybeSingle();

      if (response == null) return null;
      return LearningPath.fromJson(response);
    } catch (e) {
      print('Error getting learning path by category: $e');
      return null;
    }
  }

  // Get learning categories
  Future<List<LearningCategory>> getCategories() async {
    try {
      final response = await _supabase
          .from('learning_categories')
          .select()
          .order('name');

      return (response as List)
          .map((json) => LearningCategory.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Get logs by category
  Future<List<DailyLearningLog>> getLogsByCategory(String userId, String category) async {
    try {
      final response = await _supabase
          .from('daily_learning_logs')
          .select()
          .eq('user_id', userId)
          .eq('category', category)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => DailyLearningLog.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting logs by category: $e');
      throw Exception('Failed to get logs by category: $e');
    }
  }

  // Get category summary
  Future<Map<String, dynamic>> getCategorySummary(String userId) async {
    try {
      final logs = await getDailyLogs(userId);
      final categories = <String, int>{};
      final timePerCategory = <String, int>{};
      final difficultyPerCategory = <String, List<String>>{};

      for (var log in logs) {
        final category = log.category ?? 'Other';
        categories[category] = (categories[category] ?? 0) + 1;
        timePerCategory[category] = (timePerCategory[category] ?? 0) + log.timeSpentMinutes;

        if (!difficultyPerCategory.containsKey(category)) {
          difficultyPerCategory[category] = [];
        }
        difficultyPerCategory[category]!.add(log.difficultyLevel);
      }

      return {
        'categories': categories,
        'timePerCategory': timePerCategory,
        'difficultyPerCategory': difficultyPerCategory,
        'totalLogs': logs.length,
        'totalTime': logs.fold<int>(0, (sum, log) => sum + log.timeSpentMinutes),
      };
    } catch (e) {
      print('Error getting category summary: $e');
      throw Exception('Failed to get category summary: $e');
    }
  }

  // Get learning insights
  Future<Map<String, dynamic>> getLearningInsights(String userId) async {
    try {
      final logs = await getDailyLogs(userId);
      final stats = await getLearningStats(userId);
      final recommendations = await getRecommendations(userId);

      if (logs.isEmpty) {
        return {
          'totalDaysLearned': 0,
          'totalTopicsLearned': 0,
          'totalTimeSpent': 0,
          'streakDays': 0,
          'consistencyScore': 0.0,
          'mostLearnedTopic': 'N/A',
          'weeklyProgress': {},
          'recommendations': [],
          'insights': [],
        };
      }

      int streakDays = 0;
      final dates = logs.map((log) => log.date).toSet().toList()..sort();

      if (dates.isNotEmpty) {
        var currentDate = DateTime.now();
        for (var i = dates.length - 1; i >= 0; i--) {
          final date = dates[i];
          if (date.year == currentDate.year &&
              date.month == currentDate.month &&
              date.day == currentDate.day) {
            streakDays++;
            currentDate = currentDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }
      }

      final topicFrequency = <String, int>{};
      for (var log in logs) {
        topicFrequency[log.topic] = (topicFrequency[log.topic] ?? 0) + 1;
      }
      final mostLearnedTopic = topicFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      final weeklyProgress = <String, double>{};
      for (var i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateStr = date.toIso8601String().split('T').first;
        final dayLogs = logs
            .where(
              (log) =>
          log.date.year == date.year &&
              log.date.month == date.month &&
              log.date.day == date.day,
        )
            .toList();
        weeklyProgress[dateStr] = dayLogs.length.toDouble();
      }

      final insights = <LearningInsight>[];

      final avgConsistency = stats.isEmpty
          ? 0.0
          : stats.fold<double>(0, (sum, stat) => sum + stat.consistencyScore) /
          stats.length;

      if (avgConsistency > 0.7) {
        insights.add(
          LearningInsight(
            title: '🌟 Great Consistency!',
            description: 'You\'re consistently learning every day. Keep up the momentum!',
            type: 'positive',
            icon: '🌟',
            value: avgConsistency,
          ),
        );
      } else if (avgConsistency > 0.4) {
        insights.add(
          LearningInsight(
            title: '📈 Good Progress!',
            description: 'You\'re on the right track. Try to learn a bit more consistently.',
            type: 'warning',
            icon: '📈',
            value: avgConsistency,
          ),
        );
      } else {
        insights.add(
          LearningInsight(
            title: '💪 Keep Going!',
            description: 'Every day you learn is a step forward. Stay consistent!',
            type: 'improvement',
            icon: '💪',
            value: avgConsistency,
          ),
        );
      }

      final uniqueTopics = logs.map((log) => log.topic).toSet().length;
      if (uniqueTopics > 5) {
        insights.add(
          LearningInsight(
            title: '🎯 Broad Knowledge Base',
            description: 'You\'re exploring a wide range of topics. Great for becoming a well-rounded developer!',
            type: 'positive',
            icon: '🎯',
            value: uniqueTopics.toDouble(),
          ),
        );
      } else if (uniqueTopics > 2) {
        insights.add(
          LearningInsight(
            title: '📚 Explore More Topics',
            description: 'Try learning about different areas to expand your knowledge.',
            type: 'warning',
            icon: '📚',
            value: uniqueTopics.toDouble(),
          ),
        );
      }

      final totalTime = logs.fold<int>(
        0,
            (sum, log) => sum + log.timeSpentMinutes,
      );
      final avgTime = logs.isEmpty ? 0.0 : totalTime / logs.length;
      if (avgTime > 45) {
        insights.add(
          LearningInsight(
            title: '⏰ Dedicated Learner',
            description: 'You spend significant time learning each session. That\'s impressive!',
            type: 'positive',
            icon: '⏰',
            value: avgTime,
          ),
        );
      }

      return {
        'totalDaysLearned': dates.length,
        'totalTopicsLearned': uniqueTopics,
        'totalTimeSpent': totalTime,
        'streakDays': streakDays,
        'consistencyScore': avgConsistency,
        'mostLearnedTopic': mostLearnedTopic,
        'weeklyProgress': weeklyProgress,
        'recommendations': recommendations,
        'insights': insights,
      };
    } catch (e) {
      print('Error getting learning insights: $e');
      throw Exception('Failed to get learning insights: $e');
    }
  }

  // Delete a learning log
  Future<void> deleteLog(String logId, String userId) async {
    try {
      await _supabase
          .from('daily_learning_logs')
          .delete()
          .eq('id', logId)
          .eq('user_id', userId);

      await _updateLearningStats(userId);
    } catch (e) {
      print('Error deleting log: $e');
      throw Exception('Failed to delete log: $e');
    }
  }
}