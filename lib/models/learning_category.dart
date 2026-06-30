class LearningCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;

  LearningCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  factory LearningCategory.fromJson(Map<String, dynamic> json) {
    return LearningCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '📌',
      color: json['color'] as String? ?? '#95A5A6',
    );
  }
}

class LearningPath {
  final String id;
  final String userId;
  final String category;
  final List<String> recommendedTopics;
  final List<String> prerequisites;
  final List<String> nextSteps;
  final double progress;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LearningPath({
    required this.id,
    required this.userId,
    required this.category,
    this.recommendedTopics = const [],
    this.prerequisites = const [],
    this.nextSteps = const [],
    this.progress = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  factory LearningPath.fromJson(Map<String, dynamic> json) {
    return LearningPath(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      recommendedTopics: (json['recommended_topics'] as List?)?.map((e) => e.toString()).toList() ?? [],
      prerequisites: (json['prerequisites'] as List?)?.map((e) => e.toString()).toList() ?? [],
      nextSteps: (json['next_steps'] as List?)?.map((e) => e.toString()).toList() ?? [],
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

class AIAnalysis {
  final String category;
  final String subcategory;
  final List<String> relatedTopics;
  final List<String> prerequisites;
  final List<String> nextRecommendations;
  final String difficultyLevel;
  final double confidence;

  AIAnalysis({
    required this.category,
    required this.subcategory,
    this.relatedTopics = const [],
    this.prerequisites = const [],
    this.nextRecommendations = const [],
    this.difficultyLevel = 'intermediate',
    this.confidence = 0.0,
  });

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      category: json['category'] as String? ?? 'Other',
      subcategory: json['subcategory'] as String? ?? '',
      relatedTopics: (json['related_topics'] as List?)?.map((e) => e.toString()).toList() ?? [],
      prerequisites: (json['prerequisites'] as List?)?.map((e) => e.toString()).toList() ?? [],
      nextRecommendations: (json['next_recommendations'] as List?)?.map((e) => e.toString()).toList() ?? [],
      difficultyLevel: json['difficulty_level'] as String? ?? 'intermediate',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'subcategory': subcategory,
      'related_topics': relatedTopics,
      'prerequisites': prerequisites,
      'next_recommendations': nextRecommendations,
      'difficulty_level': difficultyLevel,
      'confidence': confidence,
    };
  }
}