import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/learning_tracker_service.dart';
import '../screens/auth/firebase_auth_service.dart';
import '../models/learning.dart';
import 'daily_learning_screen.dart';

class LearningAnalyticsScreen extends StatefulWidget {
  const LearningAnalyticsScreen({super.key});

  @override
  State<LearningAnalyticsScreen> createState() =>
      _LearningAnalyticsScreenState();
}

class _LearningAnalyticsScreenState extends State<LearningAnalyticsScreen> {
  final LearningTrackerService _learningService = LearningTrackerService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  bool _isLoading = true;
  Map<String, dynamic> _insights = {};
  List<DailyLearningLog> _logs = [];
  List<LearningRecommendation> _recommendations = [];
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
      final insights = await _learningService.getLearningInsights(_userId!);
      final logs = await _learningService.getDailyLogs(_userId!);
      final recommendations = await _learningService.getRecommendations(
        _userId!,
      );

      setState(() {
        _insights = insights;
        _logs = logs;
        _recommendations = recommendations;
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
        title: const Text('Learning Analytics'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
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
            Text('Loading your learning data...'),
          ],
        ),
      )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Learning Data Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your daily learning to see analytics!',
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCards(),
            const SizedBox(height: 16),
            _buildWeeklyProgressChart(),
            const SizedBox(height: 16),
            _buildInsights(),
            const SizedBox(height: 16),
            _buildRecommendations(),
            const SizedBox(height: 16),
            _buildRecentLogs(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalDays = _insights['totalDaysLearned'] ?? 0;
    final streakDays = _insights['streakDays'] ?? 0;
    final totalTopics = _insights['totalTopicsLearned'] ?? 0;
    final totalTime = _insights['totalTimeSpent'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          '📚',
          '$totalDays',
          'Days Learning',
          Colors.blue.shade700,
        ),
        _buildStatCard(
          '🔥',
          '$streakDays',
          'Day Streak',
          Colors.orange.shade700,
        ),
        _buildStatCard(
          '📝',
          '$totalTopics',
          'Topics Learned',
          Colors.green.shade700,
        ),
        _buildStatCard(
          '⏰',
          '${totalTime ~/ 60}h ${totalTime % 60}m',
          'Total Time',
          Colors.purple.shade700,
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), Colors.white],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressChart() {
    final weeklyProgress =
        _insights['weeklyProgress'] as Map<String, double>? ?? {};

    if (weeklyProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort entries by date
    final sortedEntries = weeklyProgress.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final data = sortedEntries.map((entry) {
      final date = DateTime.parse(entry.key);
      return WeeklyProgressData(
        day: '${date.day}/${date.month}',
        value: entry.value,
      );
    }).toList();

    // Calculate max value for chart
    final maxValue = data.isEmpty
        ? 2.0
        : data.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Weekly Progress',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${data[group.x].day}\nTopics: ${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                data[index].day,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      left: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      right: BorderSide(
                        color: Colors.transparent,
                      ),
                      top: BorderSide(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  barGroups: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: item.value,
                          color: Theme.of(context).colorScheme.primary,
                          width: 28,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 0,
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsights() {
    final insights = _insights['insights'] as List<LearningInsight>? ?? [];

    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 Learning Insights',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...insights.map(
                  (insight) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getInsightColor(insight.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getInsightColor(insight.type).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      insight.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getInsightColor(insight.type),
                            ),
                          ),
                          Text(
                            insight.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
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

  Color _getInsightColor(String type) {
    switch (type) {
      case 'positive':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'improvement':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecommendations() {
    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final incompleteRecommendations = _recommendations
        .where((rec) => !rec.isCompleted)
        .toList();

    if (incompleteRecommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Recommended Next Steps',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...incompleteRecommendations.take(3).map(
                  (rec) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPriorityColor(rec.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getPriorityColor(rec.priority).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: _getPriorityColor(rec.priority),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.topic,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            rec.reason,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(rec.priority),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        rec.priority.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (incompleteRecommendations.length > 3)
              TextButton(
                onPressed: () {
                  // Show all recommendations dialog
                  _showAllRecommendationsDialog();
                },
                child: const Text('View All Recommendations'),
              ),
          ],
        ),
      ),
    );
  }

  void _showAllRecommendationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Recommendations'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _recommendations.where((rec) => !rec.isCompleted).length,
            itemBuilder: (context, index) {
              final rec = _recommendations
                  .where((r) => !r.isCompleted)
                  .toList()[index];
              return ListTile(
                leading: Icon(
                  Icons.arrow_forward_rounded,
                  color: _getPriorityColor(rec.priority),
                ),
                title: Text(rec.topic),
                subtitle: Text(rec.reason),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(rec.priority),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rec.priority.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecentLogs() {
    final recentLogs = _logs.take(5).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 Recent Learning Logs',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...recentLogs.map(
                  (log) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getDifficultyColor(
                    log.difficultyLevel,
                  ).withOpacity(0.2),
                  child: Text(
                    log.difficultyLevel.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: _getDifficultyColor(log.difficultyLevel),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  log.topic,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${log.timeSpentMinutes} min • ${_formatDate(log.date)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                trailing: Text(
                  '${log.timeSpentMinutes}m',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  // Show log details
                  _showLogDetailsDialog(log);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogDetailsDialog(DailyLearningLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log.topic),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (log.category != null)
              Text(
                '📂 Category: ${log.category}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (log.subcategory != null)
              Text(
                '📌 Subcategory: ${log.subcategory}',
                style: const TextStyle(fontSize: 13),
              ),
            const SizedBox(height: 8),
            if (log.description != null) ...[
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(log.description!),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.timer, size: 16),
                const SizedBox(width: 4),
                Text('${log.timeSpentMinutes} minutes'),
                const SizedBox(width: 16),
                const Icon(Icons.assessment, size: 16),
                const SizedBox(width: 4),
                Text(log.difficultyLevel),
              ],
            ),
            if (log.resourcesUsed.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Resources:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...log.resourcesUsed.map(
                    (resource) => Text('• $resource'),
              ),
            ],
            if (log.codeSnippets != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Code Snippet:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  log.codeSnippets!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '📅 ${_formatDate(log.date)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class WeeklyProgressData {
  final String day;
  final double value;

  WeeklyProgressData({required this.day, required this.value});
}