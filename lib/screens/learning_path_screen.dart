import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/learning_tracker_service.dart';
import '../screens/auth/firebase_auth_service.dart';
import '../models/learning.dart';
import '../models/learning_category.dart';
import 'daily_learning_screen.dart';
import 'learning_analytics_screen.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  final LearningTrackerService _learningService = LearningTrackerService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  bool _isLoading = true;
  List<LearningPath> _learningPaths = [];
  List<LearningCategory> _categories = [];
  Map<String, dynamic> _categorySummary = {};
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = _authService.getUserId();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final paths = await _learningService.getLearningPaths(_userId!);
      final categories = await _learningService.getCategories();
      final summary = await _learningService.getCategorySummary(_userId!);

      setState(() {
        _learningPaths = paths;
        _categories = categories;
        _categorySummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Path'),
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
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your learning path...'),
          ],
        ),
      )
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DailyLearningScreen(),
            ),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add),
        label: const Text('Log Learning'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody() {
    if (_learningPaths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Learning Path Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your daily learning to build your path!',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DailyLearningScreen(),
                  ),
                );
              },
              child: const Text('Log Today\'s Learning'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverallProgress(),
          const SizedBox(height: 16),
          ..._learningPaths.map((path) => _buildLearningPathCard(path)).toList(),
          const SizedBox(height: 16),
          _buildCategoryDistribution(),
          const SizedBox(height: 16),
          _buildSummaryStats(),
        ],
      ),
    );
  }

  Widget _buildOverallProgress() {
    final totalProgress = _learningPaths.isEmpty
        ? 0.0
        : _learningPaths.fold<double>(0, (sum, path) => sum + path.progress) /
        _learningPaths.length;

    final totalLogs = _categorySummary['totalLogs'] ?? 0;
    final totalTime = _categorySummary['totalTime'] ?? 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Overall Progress',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Completion',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(totalProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Topics Learned',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalLogs',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalTime ~/ 60}h ${totalTime % 60}m',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalProgress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningPathCard(LearningPath path) {
    final category = _categories.firstWhere(
          (c) => c.name == path.category,
      orElse: () => LearningCategory(
        id: '',
        name: path.category,
        description: '',
        icon: '📌',
        color: '#95A5A6',
      ),
    );

    final progress = path.progress;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(int.parse(category.color.substring(1, 7), radix: 16))
                .withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              category.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(0)}% complete',
              style: TextStyle(
                fontSize: 12,
                color: progress >= 0.8 ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.grey.shade200,
                color: progress >= 0.8 ? Colors.green : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (path.prerequisites.isNotEmpty) ...[
                  const Text(
                    '📋 Prerequisites:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...path.prerequisites.map(
                        (prereq) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Row(
                        children: [
                          const Text('• '),
                          Expanded(child: Text(prereq)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (path.recommendedTopics.isNotEmpty) ...[
                  const Text(
                    '🎯 Recommended Topics:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...path.recommendedTopics.take(5).map(
                        (topic) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right, size: 16),
                          Expanded(child: Text(topic)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (path.nextSteps.isNotEmpty) ...[
                  const Text(
                    '🚀 Next Steps:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...path.nextSteps.take(3).map(
                        (step) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          Expanded(child: Text(step)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution() {
    final categories = _categorySummary['categories'] as Map<String, int>? ?? {};

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Learning Distribution',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...sortedEntries.map(
                  (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${entry.value} topics',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    final totalLogs = _categorySummary['totalLogs'] ?? 0;
    final totalTime = _categorySummary['totalTime'] ?? 0;
    final categories = (_categorySummary['categories'] as Map<String, int>?)?.length ?? 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Learning Summary',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '📚',
                    '$totalLogs',
                    'Total Topics',
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '⏰',
                    '${totalTime ~/ 60}h ${totalTime % 60}m',
                    'Total Time',
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '📁',
                    '$categories',
                    'Categories',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    final matched = _categories.firstWhere(
          (c) => c.name == category,
      orElse: () => LearningCategory(
        id: '',
        name: category,
        description: '',
        icon: '📌',
        color: '#95A5A6',
      ),
    );
    return Color(int.parse(matched.color.substring(1, 7), radix: 16));
  }
}