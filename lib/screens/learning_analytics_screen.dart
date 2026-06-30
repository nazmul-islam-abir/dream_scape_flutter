import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/learning_tracker_service.dart';
import '../screens/auth/firebase_auth_service.dart';
import '../models/learning.dart';
import '../theme/app_theme.dart';
import '../main.dart';

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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textSecondary),
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
      // Floating button to log learning - navigates to Log tab
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate back to Log tab
          Navigator.pop(context);
          final state = mainNavigationKey.currentState;
          if (state != null) {
            state.switchToTab(3); // Log tab index
          }
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
    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppTheme.textLight,
            ),
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
              'Start logging your daily learning to see analytics!',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final state = mainNavigationKey.currentState;
                if (state != null) {
                  state.switchToTab(3);
                }
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
            const SizedBox(height: 80),
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

    return Row(
      children: [
        Expanded(
          child: _buildStatCard('📚', '$totalDays', 'Days', Colors.blue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard('🔥', '$streakDays', 'Streak', Colors.orange),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard('📝', '$totalTopics', 'Topics', Colors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard('⏰', '${totalTime ~/ 60}h', 'Time', Colors.purple),
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressChart() {
    final weeklyProgress =
        _insights['weeklyProgress'] as Map<String, double>? ?? {};

    if (weeklyProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = weeklyProgress.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final data = sortedEntries.map((entry) {
      final date = DateTime.parse(entry.key);
      return WeeklyProgressData(
        day: '${date.day}/${date.month}',
        value: entry.value,
      );
    }).toList();

    final maxValue = data.isEmpty
        ? 2.0
        : data.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Weekly Progress',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
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
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppTheme.textLight,
                            ),
                          );
                        },
                        reservedSize: 28,
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
                        color: AppTheme.borderColor,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderColor, width: 1),
                      left: BorderSide(color: AppTheme.borderColor, width: 1),
                      right: const BorderSide(color: Colors.transparent),
                      top: const BorderSide(color: Colors.transparent),
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
                          color: AppTheme.primaryColor,
                          width: 24,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 0,
                            color: AppTheme.borderColor,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💡 Learning Insights',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...insights.map(
                  (insight) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getInsightColor(insight.type).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getInsightColor(insight.type).withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      insight.icon,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _getInsightColor(insight.type),
                            ),
                          ),
                          Text(
                            insight.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 Recommended Next Steps',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...incompleteRecommendations.take(3).map(
                  (rec) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPriorityColor(rec.priority).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getPriorityColor(rec.priority).withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: _getPriorityColor(rec.priority),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.topic,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            rec.reason,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(rec.priority),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        rec.priority.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9,
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
                onPressed: _showAllRecommendationsDialog,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'All Recommendations',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
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
                title: Text(
                  rec.topic,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  rec.reason,
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(rec.priority),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rec.priority.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 9,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📝 Recent Learning Logs',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...recentLogs.map(
                  (log) => ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: _getDifficultyColor(log.difficultyLevel)
                      .withOpacity(0.15),
                  child: Text(
                    log.difficultyLevel.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                      color: _getDifficultyColor(log.difficultyLevel),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                title: Text(
                  log.topic,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${log.timeSpentMinutes} min • ${_formatDate(log.date)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
                trailing: Text(
                  '${log.timeSpentMinutes}m',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                  ),
                ),
                onTap: () => _showLogDetailsDialog(log),
                dense: true,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          log.topic,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (log.category != null)
              Text(
                '📂 Category: ${log.category}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            if (log.subcategory != null)
              Text(
                '📌 Subcategory: ${log.subcategory}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            const SizedBox(height: 8),
            if (log.description != null) ...[
              Text(
                'Description:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                log.description!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  '${log.timeSpentMinutes} minutes',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.assessment, size: 16, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  log.difficultyLevel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            if (log.resourcesUsed.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Resources:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              ...log.resourcesUsed.map(
                    (resource) => Text(
                  '• $resource',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
            if (log.codeSnippets != null) ...[
              const SizedBox(height: 8),
              Text(
                'Code Snippet:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: SelectableText(
                  log.codeSnippets!,
                  style: GoogleFonts.inter(

                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '📅 ${_formatDate(log.date)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textLight,
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