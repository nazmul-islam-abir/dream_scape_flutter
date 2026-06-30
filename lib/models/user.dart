class UserProfile {
  final String id;
  final String userId;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final List<String> interests;
  final bool isPublic;
  final int followersCount;
  final int followingCount;
  final String? vision;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.interests = const [],
    this.isPublic = true,
    this.followersCount = 0,
    this.followingCount = 0,
    this.vision,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      interests: (json['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isPublic: json['is_public'] as bool? ?? true,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      vision: json['vision'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Add copyWith method
  UserProfile copyWith({
    String? id,
    String? userId,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    List<String>? interests,
    bool? isPublic,
    int? followersCount,
    int? followingCount,
    String? vision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      isPublic: isPublic ?? this.isPublic,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      vision: vision ?? this.vision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'interests': interests,
      'is_public': isPublic,
      'followers_count': followersCount,
      'following_count': followingCount,
      'vision': vision,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class UserRecommendation {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final List<String> interests;
  final int mutualTopics;
  final bool isFollowing;

  UserRecommendation({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.interests = const [],
    this.mutualTopics = 0,
    this.isFollowing = false,
  });

  // Add copyWith for UserRecommendation
  UserRecommendation copyWith({
    String? userId,
    String? username,
    String? avatarUrl,
    String? bio,
    List<String>? interests,
    int? mutualTopics,
    bool? isFollowing,
  }) {
    return UserRecommendation(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      mutualTopics: mutualTopics ?? this.mutualTopics,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}