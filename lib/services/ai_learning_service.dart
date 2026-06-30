import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/learning_category.dart';

class AiLearningService {
  final String _apiKey =
      "castai_v1_d06feaf069aa58e49a1fa27224d3ccdfda322a50caddfd09a045b08446f66ce3_87046d43";
  final String _endpoint = "https://llm.kimchi.dev/openai/v1/chat/completions";

  // Analyze learning topic with AI
  Future<AIAnalysis> analyzeLearningTopic(String topic, String? description) async {
    try {
      print('🤖 Analyzing learning topic: $topic');

      final response = await http
          .post(
        Uri.parse(_endpoint),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "model": "deepseek-v4-flash",
          "response_format": {"type": "json_object"},
          "messages": [
            {
              "role": "system",
              "content":
              "You are an expert educational analyst. Analyze the learning topic and respond with a valid JSON object exactly matching this schema: {\"category\": \"One of: Frontend Development, Backend Development, Mobile Development, Database, DevOps, Machine Learning, UI/UX Design, Programming Languages, Web Development, Other\", \"subcategory\": \"String (more specific area like React, Node.js, Flutter, etc.)\", \"related_topics\": [\"String\"], \"prerequisites\": [\"String\"], \"next_recommendations\": [\"String (what to learn next in this category)\"], \"difficulty_level\": \"One of: beginner, intermediate, advanced\", \"confidence\": 0.0-1.0 (confidence in categorization)"
            },
            {
              "role": "user",
              "content":
              "Topic: '$topic'\nDescription: '${description ?? "No description provided"}'\nAnalyze and categorize this learning topic.",
            },
          ],
        }),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = jsonDecode(response.body);
        final String rawContent =
        decodedBody['choices'][0]['message']['content'];
        final Map<String, dynamic> analysis = jsonDecode(rawContent);

        print('✅ AI Analysis complete: ${analysis['category']} -> ${analysis['subcategory']}');

        return AIAnalysis(
          category: analysis['category'] ?? 'Other',
          subcategory: analysis['subcategory'] ?? '',
          relatedTopics: List<String>.from(analysis['related_topics'] ?? []),
          prerequisites: List<String>.from(analysis['prerequisites'] ?? []),
          nextRecommendations: List<String>.from(analysis['next_recommendations'] ?? []),
          difficultyLevel: analysis['difficulty_level'] ?? 'intermediate',
          confidence: (analysis['confidence'] as num?)?.toDouble() ?? 0.0,
        );
      } else {
        print('❌ AI analysis failed: ${response.statusCode}');
        return AIAnalysis(
          category: 'Other',
          subcategory: 'General',
          relatedTopics: [],
          prerequisites: [],
          nextRecommendations: ['Continue learning $topic'],
          difficultyLevel: 'intermediate',
          confidence: 0.0,
        );
      }
    } catch (e) {
      print('❌ AI analysis error: $e');
      return AIAnalysis(
        category: 'Other',
        subcategory: 'General',
        relatedTopics: [],
        prerequisites: [],
        nextRecommendations: ['Continue learning $topic'],
        difficultyLevel: 'intermediate',
        confidence: 0.0,
      );
    }
  }

  // Generate personalized learning plan
  Future<Map<String, dynamic>> generateLearningPlan(
      String userId,
      List<AIAnalysis> analyses,
      ) async {
    try {
      print('🤖 Generating learning plan for user: $userId');

      final categories = analyses.map((a) => a.category).toList();
      final topics = analyses.map((a) => a.subcategory).toList();

      final response = await http
          .post(
        Uri.parse(_endpoint),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "model": "deepseek-v4-flash",
          "response_format": {"type": "json_object"},
          "messages": [
            {
              "role": "system",
              "content":
              "You are an expert learning path architect. Based on the user's learning history, generate a personalized learning plan. Respond with a valid JSON object: {\"focus_areas\": [\"String\"], \"recommended_learning_path\": {\"step\": \"String\", \"action\": \"String\"}, \"estimated_time\": \"String\", \"skill_gaps\": [\"String\"], \"recommended_resources\": [\"String\"]}"
            },
            {
              "role": "user",
              "content":
              "User has been learning these topics: $topics\nCategories: $categories\nGenerate a personalized learning plan.",
            },
          ],
        }),
      )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = jsonDecode(response.body);
        final String rawContent =
        decodedBody['choices'][0]['message']['content'];
        return jsonDecode(rawContent);
      } else {
        return {
          'focus_areas': ['Continue your current learning path'],
          'recommended_learning_path': {'step': '1', 'action': 'Review what you\'ve learned'},
          'estimated_time': '30 minutes',
          'skill_gaps': ['Keep exploring different topics'],
          'recommended_resources': ['Documentation', 'Online courses'],
        };
      }
    } catch (e) {
      print('❌ Learning plan generation error: $e');
      return {
        'focus_areas': ['Continue your current learning path'],
        'recommended_learning_path': {'step': '1', 'action': 'Keep learning and logging'},
        'estimated_time': '30 minutes',
        'skill_gaps': ['Explore more topics in your area of interest'],
        'recommended_resources': ['Documentation', 'Practice exercises'],
      };
    }
  }
}