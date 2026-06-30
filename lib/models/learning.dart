class DailyLearningLog {
  final String id;
  final String userId;
  final DateTime date;
  final String topic;
  final String? description;
  final int timeSpentMinutes;
  final String difficultyLevel;
  final List<String> resourcesUsed;
  final String? codeSnippets;
  final String? category;
  final String? subcategory;
  final Map<String, dynamic>? aiAnalysis;
  final String? userFeedback;
  final int? feedbackRating;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DailyLearningLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.topic,
    this.description,
    this.timeSpentMinutes = 30,
    this.difficultyLevel = 'medium',
    this.resourcesUsed = const [],
    this.codeSnippets,
    this.category,
    this.subcategory,
    this.aiAnalysis,
    this.userFeedback,
    this.feedbackRating,
    required this.createdAt,
    this.updatedAt,
  });

  factory DailyLearningLog.fromJson(Map<String, dynamic> json) {
    // Handle resources_used which comes as PostgreSQL array
    List<String> resources = [];
    if (json['resources_used'] != null) {
      if (json['resources_used'] is List) {
        resources = (json['resources_used'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (json['resources_used'] is String) {
        final str = json['resources_used'] as String;
        if (str.startsWith('{') && str.endsWith('}')) {
          resources = str
              .substring(1, str.length - 1)
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
    }

    // Handle ai_analysis which comes as JSON
    Map<String, dynamic>? aiAnalysis;
    if (json['ai_analysis'] != null) {
      if (json['ai_analysis'] is Map) {
        aiAnalysis = Map<String, dynamic>.from(json['ai_analysis']);
      }
    }

    return DailyLearningLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      topic: json['topic'] as String,
      description: json['description'] as String?,
      timeSpentMinutes: json['time_spent_minutes'] as int? ?? 30,
      difficultyLevel: json['difficulty_level'] as String? ?? 'medium',
      resourcesUsed: resources,
      codeSnippets: json['code_snippets'] as String?,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      aiAnalysis: aiAnalysis,
      userFeedback: json['user_feedback'] as String?,
      feedbackRating: json['feedback_rating'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      'topic': topic,
      'description': description,
      'time_spent_minutes': timeSpentMinutes,
      'difficulty_level': difficultyLevel,
      'resources_used': resourcesUsed,
      'code_snippets': codeSnippets,
      'category': category,
      'subcategory': subcategory,
      'ai_analysis': aiAnalysis,
      'user_feedback': userFeedback,
      'feedback_rating': feedbackRating,
    };
  }

  DailyLearningLog copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? topic,
    String? description,
    int? timeSpentMinutes,
    String? difficultyLevel,
    List<String>? resourcesUsed,
    String? codeSnippets,
    String? category,
    String? subcategory,
    Map<String, dynamic>? aiAnalysis,
    String? userFeedback,
    int? feedbackRating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyLearningLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      resourcesUsed: resourcesUsed ?? this.resourcesUsed,
      codeSnippets: codeSnippets ?? this.codeSnippets,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      userFeedback: userFeedback ?? this.userFeedback,
      feedbackRating: feedbackRating ?? this.feedbackRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LearningRecommendation {
  final String id;
  final String userId;
  final String topic;
  final String reason;
  final String priority;
  final String? roadmapId;
  bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LearningRecommendation({
    required this.id,
    required this.userId,
    required this.topic,
    required this.reason,
    required this.priority,
    this.roadmapId,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory LearningRecommendation.fromJson(Map<String, dynamic> json) {
    return LearningRecommendation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      topic: json['topic'] as String,
      reason: json['reason'] as String,
      priority: json['priority'] as String? ?? 'medium',
      roadmapId: json['roadmap_id'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

class LearningStats {
  final String id;
  final String userId;
  final DateTime date;
  final int totalTopicsLearned;
  final int totalTimeSpent;
  final List<String> topics;
  final double consistencyScore;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LearningStats({
    required this.id,
    required this.userId,
    required this.date,
    this.totalTopicsLearned = 0,
    this.totalTimeSpent = 0,
    this.topics = const [],
    this.consistencyScore = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  factory LearningStats.fromJson(Map<String, dynamic> json) {
    List<String> topics = [];
    if (json['topics'] != null) {
      if (json['topics'] is List) {
        topics = (json['topics'] as List).map((e) => e.toString()).toList();
      }
    }

    return LearningStats(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      totalTopicsLearned: json['total_topics_learned'] as int? ?? 0,
      totalTimeSpent: json['total_time_spent'] as int? ?? 0,
      topics: topics,
      consistencyScore: (json['consistency_score'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

class LearningInsight {
  final String title;
  final String description;
  final String type;
  final String icon;
  final double value;

  LearningInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
    required this.value,
  });
}

class WeeklyProgressData {
  final String day;
  final double value;

  WeeklyProgressData({required this.day, required this.value});
}