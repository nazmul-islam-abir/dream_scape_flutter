import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String _apiKey =
      "castai_v1_d06feaf069aa58e49a1fa27224d3ccdfda322a50caddfd09a045b08446f66ce3_87046d43";
  final String _endpoint = "https://llm.kimchi.dev/openai/v1/chat/completions";

  /// Core Generation Call: Builds the structured curriculum skeleton mapping
  Future<Map<String, dynamic>> generateRoadmap(
    String goal,
    String level,
  ) async {
    final response = await http.post(
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
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedBody = jsonDecode(response.body);
      final String rawAiJsonString =
          decodedBody['choices'][0]['message']['content'];
      return jsonDecode(rawAiJsonString);
    } else {
      throw Exception(
        "Failed to sync with Kimchi API. Server returned code: ${response.statusCode}",
      );
    }
  }

  /// Interactive Help Call: Spawns micro-lessons on demand
  Future<Map<String, dynamic>> fetchTopicLesson(
    String topicTitle,
    String courseContext,
  ) async {
    final response = await http.post(
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
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedBody = jsonDecode(response.body);
      final String rawContent = decodedBody['choices'][0]['message']['content'];
      return jsonDecode(rawContent);
    } else {
      throw Exception(
        "Failed to sync micro-lesson with Kimchi. Server returned code: ${response.statusCode}",
      );
    }
  }

  /// Core Evaluation Pipeline: Validates codebase submissions against strict parsing rules
  Future<Map<String, dynamic>> evaluateProjectSubmission(
    String projectTitle,
    String sourceCode,
  ) async {
    final response = await http.post(
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
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedBody = jsonDecode(response.body);
      final String rawContent = decodedBody['choices'][0]['message']['content'];
      return jsonDecode(rawContent);
    } else {
      throw Exception("Verification server down. Code: ${response.statusCode}");
    }
  }
}
