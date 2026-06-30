class Post {
  final String id;
  final String userId;
  final String username;
  final String content;
  final String? imageUrl;
  final String? roadmapId;
  final String? topicTitle;
  final int likesCount;
  int commentsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  bool isLikedByUser;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    this.imageUrl,
    this.roadmapId,
    this.topicTitle,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isLikedByUser = false,
  });

  factory Post.fromJson(Map<String, dynamic> json, {bool isLiked = false}) {
    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] ?? 'User',
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      roadmapId: json['roadmap_id'] as String?,
      topicTitle: json['topic_title'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isLikedByUser: isLiked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'content': content,
      'image_url': imageUrl,
      'roadmap_id': roadmapId,
      'topic_title': topicTitle,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? content,
    String? imageUrl,
    String? roadmapId,
    String? topicTitle,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLikedByUser,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      roadmapId: roadmapId ?? this.roadmapId,
      topicTitle: topicTitle ?? this.topicTitle,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
    );
  }
}

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] ?? 'User',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
