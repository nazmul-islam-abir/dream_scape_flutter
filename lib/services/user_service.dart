import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/learning.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user profile
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Get user by username
  Future<UserProfile> getUserByUsername(String username) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('username', username)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to find user: $e');
    }
  }

  // Get user's interests from their learning logs
  Future<List<String>> getUserInterests(String userId) async {
    try {
      final response = await _supabase
          .from('daily_learning_logs')
          .select('topic, category')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      final topics = <String>[];
      for (var log in response) {
        final topic = log['topic'] as String;
        final category = log['category'] as String?;
        if (category != null && !topics.contains(category)) {
          topics.add(category);
        }
        if (!topics.contains(topic)) {
          topics.add(topic);
        }
      }
      return topics.take(10).toList();
    } catch (e) {
      print('Error getting user interests: $e');
      return [];
    }
  }

  // Get user recommendations based on matching interests
  Future<List<UserRecommendation>> getRecommendations(
      String currentUserId, {
        int limit = 20,
      }) async {
    try {
      // Get current user's interests
      final myInterests = await getUserInterests(currentUserId);

      // Get all other users
      final allUsers = await _supabase
          .from('user_profiles')
          .select()
          .neq('user_id', currentUserId)
          .eq('is_public', true)
          .limit(50);

      // Get users I follow
      final following = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId);

      final followingIds = following
          .map((f) => f['following_id'] as String)
          .toSet();

      final recommendations = <UserRecommendation>[];

      for (var user in allUsers) {
        final userId = user['user_id'] as String;
        final userInterests = await getUserInterests(userId);

        // Calculate mutual topics
        int mutualTopics = 0;
        for (var interest in myInterests) {
          for (var userInterest in userInterests) {
            if (interest.toLowerCase().contains(userInterest.toLowerCase()) ||
                userInterest.toLowerCase().contains(interest.toLowerCase())) {
              mutualTopics++;
              break;
            }
          }
        }

        recommendations.add(
          UserRecommendation(
            userId: userId,
            username: user['username'] as String,
            avatarUrl: user['avatar_url'] as String?,
            bio: user['bio'] as String?,
            interests: userInterests,
            mutualTopics: mutualTopics,
            isFollowing: followingIds.contains(userId),
          ),
        );
      }

      // Sort by mutual topics (highest first)
      recommendations.sort((a, b) => b.mutualTopics.compareTo(a.mutualTopics));

      return recommendations.take(limit).toList();
    } catch (e) {
      print('Error getting recommendations: $e');
      return [];
    }
  }

  // Follow a user
  Future<void> followUser(String followerId, String followingId) async {
    try {
      // Add follow relationship
      await _supabase.from('follows').insert({
        'follower_id': followerId,
        'following_id': followingId,
      });

      // Update follower count - get current count and increment
      final followerProfile = await _supabase
          .from('user_profiles')
          .select('followers_count')
          .eq('user_id', followingId)
          .single();

      final currentFollowers = (followerProfile['followers_count'] as int?) ?? 0;
      await _supabase
          .from('user_profiles')
          .update({'followers_count': currentFollowers + 1})
          .eq('user_id', followingId);

      // Update following count
      final followingProfile = await _supabase
          .from('user_profiles')
          .select('following_count')
          .eq('user_id', followerId)
          .single();

      final currentFollowing = (followingProfile['following_count'] as int?) ?? 0;
      await _supabase
          .from('user_profiles')
          .update({'following_count': currentFollowing + 1})
          .eq('user_id', followerId);
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      // Remove follow relationship
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);

      // Update follower count - get current count and decrement
      final followerProfile = await _supabase
          .from('user_profiles')
          .select('followers_count')
          .eq('user_id', followingId)
          .single();

      final currentFollowers = (followerProfile['followers_count'] as int?) ?? 0;
      await _supabase
          .from('user_profiles')
          .update({'followers_count': currentFollowers > 0 ? currentFollowers - 1 : 0})
          .eq('user_id', followingId);

      // Update following count
      final followingProfile = await _supabase
          .from('user_profiles')
          .select('following_count')
          .eq('user_id', followerId)
          .single();

      final currentFollowing = (followingProfile['following_count'] as int?) ?? 0;
      await _supabase
          .from('user_profiles')
          .update({'following_count': currentFollowing > 0 ? currentFollowing - 1 : 0})
          .eq('user_id', followerId);
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  // Check if user is following another user
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get user's followers
  Future<List<UserProfile>> getFollowers(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);

      final followerIds = response
          .map((f) => f['follower_id'] as String)
          .toList();

      if (followerIds.isEmpty) return [];

      final profiles = await _supabase
          .from('user_profiles')
          .select()
          .inFilter('user_id', followerIds);

      return (profiles as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  // Get users that a user is following
  Future<List<UserProfile>> getFollowing(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      final followingIds = response
          .map((f) => f['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

      final profiles = await _supabase
          .from('user_profiles')
          .select()
          .inFilter('user_id', followingIds);

      return (profiles as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    String? username,
    String? bio,
    List<String>? interests,
    bool? isPublic,
  }) async {
    try {
      final data = {
        if (username != null) 'username': username,
        if (bio != null) 'bio': bio,
        if (interests != null) 'interests': interests,
        if (isPublic != null) 'is_public': isPublic,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('user_profiles')
          .update(data)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}