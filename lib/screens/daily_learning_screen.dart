import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/learning_tracker_service.dart';
import '../screens/auth/firebase_auth_service.dart';
import 'learning_analytics_screen.dart';

class DailyLearningScreen extends StatefulWidget {
  const DailyLearningScreen({super.key});

  @override
  State<DailyLearningScreen> createState() => _DailyLearningScreenState();
}

class _DailyLearningScreenState extends State<DailyLearningScreen> {
  final LearningTrackerService _learningService = LearningTrackerService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _resourcesController = TextEditingController();

  int _timeSpentMinutes = 30;
  String _difficultyLevel = 'medium';
  bool _isLoading = false;
  String? _userId;

  final List<String> _difficultyLevels = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    _userId = _authService.getUserId();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    _resourcesController.dispose();
    super.dispose();
  }

  Future<void> _submitLearningLog() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter what you learned'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String resourcesText = _resourcesController.text.trim();
      List<String> resources = [];
      if (resourcesText.isNotEmpty) {
        resources = resourcesText
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      await _learningService.addDailyLog(
        userId: _userId!,
        topic: topic,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        timeSpentMinutes: _timeSpentMinutes,
        difficultyLevel: _difficultyLevel,
        resourcesUsed: resources,
        codeSnippets: _codeController.text.trim().isNotEmpty
            ? _codeController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Learning log saved!'),
            backgroundColor: Colors.green,
          ),
        );

        _topicController.clear();
        _descriptionController.clear();
        _codeController.clear();
        _resourcesController.clear();
        setState(() {
          _timeSpentMinutes = 30;
          _difficultyLevel = 'medium';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Learning Log'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LearningAnalyticsScreen(),
                ),
              );
            },
            tooltip: 'View Analytics',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'What did you learn today?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateTime.now().toString().split(' ').first,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Topic Input
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: 'What did you learn? *',
                hintText: 'e.g., Flutter Provider Pattern',
                prefixIcon: const Icon(Icons.bolt_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),

            // Description Input
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What did you learn and how does it work?',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Time Spent Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Time Spent',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _timeSpentMinutes.toDouble(),
                            min: 5,
                            max: 180,
                            divisions: 35,
                            label: '$_timeSpentMinutes min',
                            onChanged: (value) {
                              setState(() {
                                _timeSpentMinutes = value.round();
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_timeSpentMinutes min',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Difficulty Level Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assessment_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Difficulty Level',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _difficultyLevels.map((level) {
                        final isSelected = _difficultyLevel == level;
                        Color getColor() {
                          switch (level) {
                            case 'easy':
                              return Colors.green;
                            case 'medium':
                              return Colors.orange;
                            case 'hard':
                              return Colors.red;
                            default:
                              return Colors.grey;
                          }
                        }

                        return ChoiceChip(
                          label: Text(
                            level.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : getColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _difficultyLevel = level;
                            });
                          },
                          backgroundColor: getColor().withOpacity(0.1),
                          selectedColor: getColor(),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Code Snippets Input
            TextField(
              controller: _codeController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Code Snippets (optional)',
                hintText: 'Paste any code you wrote or learned',
                prefixIcon: const Icon(Icons.code_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Resources Input
            TextField(
              controller: _resourcesController,
              decoration: InputDecoration(
                labelText: 'Resources Used (optional)',
                hintText: 'e.g., YouTube, Documentation, Course (comma separated)',
                prefixIcon: const Icon(Icons.link_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitLearningLog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined),
                  SizedBox(width: 12),
                  Text(
                    'Save Learning Log',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Analytics Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LearningAnalyticsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('View Analytics'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}