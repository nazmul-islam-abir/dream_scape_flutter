import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';

class TopicLearningScreen extends StatefulWidget {
  final String topicTitle;
  final String courseContext;

  const TopicLearningScreen({
    super.key,
    required this.topicTitle,
    required this.courseContext,
  });

  @override
  State<TopicLearningScreen> createState() => _TopicLearningScreenState();
}

class _TopicLearningScreenState extends State<TopicLearningScreen> {
  final _supabase = Supabase.instance.client;
  final _aiService = AiService();

  bool _isLoading = true;
  Map<String, dynamic>? _lessonData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadLessonLifecycle();
  }

  Future<void> _loadLessonLifecycle() async {
    try {
      final response = await _supabase
          .from('cached_lessons')
          .select('lesson_data')
          .eq('topic_title', widget.topicTitle)
          .maybeSingle();

      if (response != null && response['lesson_data'] != null) {
        setState(() {
          _lessonData = response['lesson_data'] as Map<String, dynamic>;
          _isLoading = false;
        });
        return;
      }

      final freshLesson = await _aiService.fetchTopicLesson(
        widget.topicTitle,
        widget.courseContext,
      );

      await _supabase.from('cached_lessons').insert({
        'topic_title': widget.topicTitle,
        'lesson_data': freshLesson,
      });

      setState(() {
        _lessonData = freshLesson;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(body: Center(child: Text("Sync Error: $_errorMessage")));
    }

    final walkthrough = _lessonData!['step_by_step_walkthrough'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(widget.topicTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.15),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Conceptual Theory",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(_lessonData!['conceptual_explanation'] ?? ''),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Everyday Analogy",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            _lessonData!['analogy'] ?? '',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          const Divider(height: 32),
          const Text(
            "Execution Roadmap",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          ...walkthrough.map((step) => Text("• ${step.toString()}")),
          const Divider(height: 32),
          const Text(
            "Reference Code Architecture",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade900,
            child: Text(
              _lessonData!['demo_code_snippet'] ?? '',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Practice Challenge",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(_lessonData!['practice_exercise_prompt'] ?? ''),
        ],
      ),
    );
  }
}
