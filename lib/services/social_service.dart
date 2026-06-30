import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../services/profile_service.dart';
import 'dart:io';

class SocialService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();

  // Create a post
  Future<Post> createPost({
    required String userId,
    required String username,
    required String content,
    String? imageUrl,
    String? roadmapId,
    String? topicTitle,
  }) async {
    try {
      // Ensure user profile exists before creating post
      await _profileService.ensureUserProfile(userId, username);

      final data = {
        'user_id': userId,
        'username': username,
        'content': content,
        if (imageUrl != null) 'image_url': imageUrl,
        if (roadmapId != null) 'roadmap_id': roadmapId,
        if (topicTitle != null) 'topic_title': topicTitle,
      };

      final response = await _supabase
          .from('posts')
          .insert(data)
          .select()
          .single();

      return Post.fromJson(response);
    } catch (e) {
      print('Failed to create post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  // Get all posts with pagination
  Future<List<Post>> getPosts({int limit = 20, String? userId}) async {
    try {
      var query = _supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      // Fix: Use the correct method chain for filtering
      if (userId != null) {
        query = _supabase
            .from('posts')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);
      }

      final response = await query;

      // Get current user's liked posts
      final currentUser = _supabase.auth.currentUser;
      List<String> likedPostIds = [];

      if (currentUser != null) {
        final likesResponse = await _supabase
            .from('reactions')
            .select('post_id')
            .eq('user_id', currentUser.id);

        likedPostIds = likesResponse
            .map((e) => e['post_id'] as String)
            .toList();
      }

      return (response as List).map((json) {
        final isLiked = likedPostIds.contains(json['id']);
        return Post.fromJson(json, isLiked: isLiked);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get posts: $e');
    }
  }

  // Toggle like on a post
  Future<void> toggleLike(String postId, String userId) async {
    try {
      // Check if already liked
      final existingLike = await _supabase
          .from('reactions')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike: Delete reaction and decrement count
        await _supabase
            .from('reactions')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);

        await _supabase.rpc(
          'decrement_post_likes',
          params: {'post_id_input': postId},
        );
      } else {
        // Like: Add reaction and increment count
        await _supabase.from('reactions').insert({
          'post_id': postId,
          'user_id': userId,
        });

        await _supabase.rpc(
          'increment_post_likes',
          params: {'post_id_input': postId},
        );
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  // Get comments for a post
  Future<List<Comment>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List).map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get comments: $e');
    }
  }

  // Add comment to a post
  Future<Comment> addComment({
    required String postId,
    required String userId,
    required String username,
    required String content,
  }) async {
    try {
      final data = {
        'post_id': postId,
        'user_id': userId,
        'username': username,
        'content': content,
      };

      final response = await _supabase
          .from('comments')
          .insert(data)
          .select()
          .single();

      // Increment comments count
      await _supabase.rpc(
        'increment_post_comments',
        params: {'post_id_input': postId},
      );

      return Comment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Delete a post
  Future<void> deletePost(String postId, String userId) async {
    try {
      await _supabase
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Upload image to Supabase Storage
  Future<String?> uploadImage(String userId, String filePath) async {
    try {
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileBytes = await File(filePath).readAsBytes();
      await _supabase.storage
          .from('post_images')
          .uploadBinary(fileName, fileBytes);

      final publicUrl = _supabase.storage
          .from('post_images')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Failed to upload image: $e');
      return null;
    }
  }
}
