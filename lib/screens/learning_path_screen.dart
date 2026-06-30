// ============== learning_path_screen.dart ==============
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/learning_tracker_service.dart';
import '../screens/auth/firebase_auth_service.dart';
import '../models/learning.dart';
import '../models/learning_category.dart';
import '../theme/app_theme.dart';
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Progress',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics_outlined, color: AppTheme.textSecondary),
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
          IconButton(
            icon: Icon(Icons.add_box_outlined, color: AppTheme.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DailyLearningScreen(),
                ),
              );
            },
            tooltip: 'Log Learning',
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
            Text('Loading your progress...'),
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
        label: Text(
          'Log Learning',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_learningPaths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route_outlined, size: 48, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(
              'No Learning Data Yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your daily learning to track your progress!',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DailyLearningScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Log Today\'s Learning'),
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
          Text(
            'Your Learning Paths',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Overall Progress',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completion',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(totalProgress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Topics Learned',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalLogs',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Time',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalTime ~/ 60}h ${totalTime % 60}m',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: totalProgress,
                minHeight: 6,
                backgroundColor: AppTheme.borderColor,
                color: AppTheme.primaryColor,
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color(int.parse(category.color.substring(1, 7), radix: 16))
                .withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              category.icon,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(0)}% complete',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: progress >= 0.8 ? AppTheme.secondaryColor : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppTheme.borderColor,
                color: progress >= 0.8 ? AppTheme.secondaryColor : AppTheme.primaryColor,
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
                  Text(
                    '📋 Prerequisites:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...path.prerequisites.map(
                        (prereq) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Row(
                        children: [
                          const Text('• '),
                          Expanded(
                            child: Text(
                              prereq,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (path.recommendedTopics.isNotEmpty) ...[
                  Text(
                    '🎯 Recommended Topics:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...path.recommendedTopics.take(5).map(
                        (topic) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_right, size: 16, color: AppTheme.primaryColor),
                          Expanded(
                            child: Text(
                              topic,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (path.nextSteps.isNotEmpty) ...[
                  Text(
                    '🚀 Next Steps:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...path.nextSteps.take(3).map(
                        (step) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          Expanded(
                            child: Text(
                              step,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📈 Learning Distribution',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppTheme.textPrimary,
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
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value} topics',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textLight,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Learning Summary',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
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
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.textLight,
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