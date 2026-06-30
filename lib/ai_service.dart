import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AiService {
  final String _apiKey =
      "castai_v1_d06feaf069aa58e49a1fa27224d3ccdfda322a50caddfd09a045b08446f66ce3_87046d43";
  final String _endpoint = "https://llm.kimchi.dev/openai/v1/chat/completions";

  /// Core Generation Call: Builds the structured curriculum skeleton mapping
  Future<Map<String, dynamic>> generateRoadmap(
    String goal,
    String level,
  ) async {
    try {
      print('🔄 Generating roadmap for: $goal (Level: $level)');

      // Check authentication first
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please sign in again.');
      }

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
                      "You are an elite educational curriculum engineer. Respond ONLY with a valid JSON object matching this schema exactly with no markdown decorations outside it: {\"roadmap_title\": \"String\", \"difficulty\": \"String\", \"modules\": [ {\"module_number\": 1, \"module_title\": \"String\", \"module_objective\": \"String\", \"topics\": [ {\"topic_title\": \"String\", \"core_concept_summary\": \"String\"} ], \"capstone_project\": {\"project_title\": \"String\", \"project_requirements\": [\"String\"], \"submission_guidelines\": \"String\"} } ]}",
                },
                {
                  "role": "user",
                  "content":
                      "Generate a detailed, step-by-step module roadmap to learn: $goal. Level: $level.",
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 60));

      print('📡 Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = jsonDecode(response.body);
        final String rawAiJsonString =
            decodedBody['choices'][0]['message']['content'];
        print('✅ Successfully parsed AI response');
        return jsonDecode(rawAiJsonString);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Authentication failed. Please check your API key.');
      } else {
        print('❌ API Error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception(
          "Failed to generate roadmap. Server returned code: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('❌ Exception in generateRoadmap: $e');
      if (e is http.ClientException) {
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      } else if (e.toString().contains('Timeout')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Interactive Help Call: Spawns micro-lessons on demand
  Future<Map<String, dynamic>> fetchTopicLesson(
    String topicTitle,
    String courseContext,
  ) async {
    try {
      print('🔄 Fetching lesson for topic: $topicTitle');

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
                      "You are a master technical instructor teaching someone who knows absolutely nothing. Explain concepts using extremely simple everyday analogies. Respond ONLY with a valid JSON object matching this schema exactly: {\"conceptual_explanation\": \"String\", \"analogy\": \"String\", \"step_by_step_walkthrough\": [\"String\"], \"demo_code_snippet\": \"String\", \"practice_exercise_prompt\": \"String\"}",
                },
                {
                  "role": "user",
                  "content":
                      "Teach me the topic: '$topicTitle' within the course context of '$courseContext'. Provide interactive code setups.",
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 45));

      print('📡 Lesson response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = jsonDecode(response.body);
        final String rawContent =
            decodedBody['choices'][0]['message']['content'];
        print('✅ Successfully fetched lesson');
        return jsonDecode(rawContent);
      } else {
        print('❌ Lesson API Error: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        throw Exception(
          "Failed to fetch lesson. Server returned code: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('❌ Exception in fetchTopicLesson: $e');
      rethrow;
    }
  }

  /// Core Evaluation Pipeline: Validates codebase submissions against strict parsing rules
  Future<Map<String, dynamic>> evaluateProjectSubmission(
    String projectTitle,
    String sourceCode,
  ) async {
    try {
      print('🔄 Evaluating project: $projectTitle');

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
                      "You are an automated structural unit tester and security review engine. Analyze the code provided. If there are any bugs, security gaps, logical flaws, or unoptimized complexity blocks, mark status as 'has_issues'. If the code meets requirements perfectly and securely, mark status as 'perfect'. Respond ONLY with this JSON schema: {\"status\": \"perfect/has_issues\", \"critique_summary\": \"String\", \"identified_issues\": [\"String\"], \"remedial_steps\": \"String\"}",
                },
                {
                  "role": "user",
                  "content":
                      "Project Context: $projectTitle\nUser Submission Content:\n$sourceCode",
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
        throw Exception(
          "Verification server error. Code: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('❌ Exception in evaluateProjectSubmission: $e');
      rethrow;
    }
  }

  // Test method to check if the API is working
  Future<bool> testApiConnection() async {
    try {
      print('🔍 Testing API connection...');
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
              "messages": [
                {"role": "system", "content": "You are a helpful assistant."},
                {
                  "role": "user",
                  "content": "Say 'API is working' in exactly 3 words.",
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('🔍 Test response: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('✅ API is working!');
        return true;
      } else {
        print('❌ API test failed: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ API test exception: $e');
      return false;
    }
  }
}
