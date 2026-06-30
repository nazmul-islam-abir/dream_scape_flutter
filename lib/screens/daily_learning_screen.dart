import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/learning_tracker_service.dart';
import '../screens/auth/firebase_auth_service.dart';
import '../theme/app_theme.dart';
import 'learning_analytics_screen.dart';
import '../main.dart';
import '../widgets/bottom_nav_bar.dart';
import 'auth/profile_screen.dart';

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
      _showSnackBar('Please enter what you learned', Colors.orange);
      return;
    }

    if (_userId == null) {
      _showSnackBar('Please sign in first', Colors.orange);
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
        _showSnackBar('✅ Learning logged successfully!', AppTheme.secondaryColor);

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
        _showSnackBar('Error: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 5) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }
    final state = mainNavigationKey.currentState;
    if (state != null) {
      state.switchToTab(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Log Learning',
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
            icon: Icon(Icons.timeline_outlined, color: AppTheme.textSecondary),
            onPressed: () {
              final state = mainNavigationKey.currentState;
              if (state != null) {
                state.switchToTab(4);
              }
            },
            tooltip: 'View Progress',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'What did you learn today?',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Log your daily learning to track progress',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '📅 ${DateTime.now().toString().split(' ').first}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'What did you learn? *',
                hintText: 'e.g., Flutter Provider Pattern',
                prefixIcon: Icon(Icons.bolt_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What did you learn and how does it work?',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Time Spent',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
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
                            activeColor: AppTheme.primaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_timeSpentMinutes min',
                            style: GoogleFonts.inter(
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

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assessment_outlined, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Difficulty Level',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
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
                            style: GoogleFonts.inter(
                              color: isSelected ? Colors.white : getColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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

            TextField(
              controller: _codeController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Code Snippets (optional)',
                hintText: 'Paste any code you wrote or learned',
                prefixIcon: Icon(Icons.code_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _resourcesController,
              decoration: const InputDecoration(
                labelText: 'Resources Used (optional)',
                hintText: 'e.g., YouTube, Documentation, Course (comma separated)',
                prefixIcon: Icon(Icons.link_outlined),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitLearningLog,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_outlined),
                    const SizedBox(width: 10),
                    Text(
                      'Save Learning Log',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LearningAnalyticsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: Text(
                      'Analytics',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final state = mainNavigationKey.currentState;
                      if (state != null) {
                        state.switchToTab(4);
                      }
                    },
                    icon: const Icon(Icons.timeline_outlined, size: 18),
                    label: Text(
                      'Progress',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: _onNavTap,
      ),
    );
  }
}