// ============== home_screen.dart ==============
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/auth/firebase_auth_service.dart';
import '../theme/app_theme.dart';
import 'ai_service.dart';
import 'roadmap_explorer_screen.dart';
import 'main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _goalController = TextEditingController();
  String _selectedLevel = 'Beginner';
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;
  final _authService = FirebaseAuthService();
  bool _isCancelled = false;

  final List<Map<String, dynamic>> _exampleGoals = [
    {'icon': Icons.flutter_dash, 'label': 'Flutter Development'},
    {'icon': Icons.code, 'label': 'Python Programming'},
    {'icon': Icons.data_usage, 'label': 'Machine Learning'},
    {'icon': Icons.web, 'label': 'Web Development'},
    {'icon': Icons.cloud, 'label': 'Cloud Computing'},
    {'icon': Icons.security, 'label': 'Cybersecurity'},
  ];

  Future<void> _submitData() async {
    if (_goalController.text.trim().isEmpty) {
      _showSnackBar('Please enter a learning goal', Colors.orange);
      return;
    }

    final userId = _authService.getUserId();
    if (userId == null) {
      _showSnackBar('Please sign in first', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _isCancelled = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoadingDialog(
        goal: _goalController.text.trim(),
        onCancel: () {
          _isCancelled = true;
          Navigator.pop(context);
        },
      ),
    );

    try {
      final parsedJson = await AiService().generateRoadmap(
        _goalController.text.trim(),
        _selectedLevel,
      );

      if (_isCancelled || !mounted) {
        return;
      }

      final roadMapData = {
        'user_id': userId,
        'user_goal': _goalController.text.trim(),
        'difficulty': _selectedLevel,
        'full_data': parsedJson,
        'progress': 0.0,
      };

      final response = await _supabase
          .from('user_roadmaps')
          .insert(roadMapData)
          .select()
          .single();

      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }

      if (mounted) {
        _showSnackBar('✨ Roadmap generated successfully!', AppTheme.secondaryColor);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoadmapExplorerScreen(
              rawRoadmapData: parsedJson,
              roadmapId: response['id'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }

      String errorMessage = _getUserFriendlyError(e);
      _showSnackBar('❌ $errorMessage', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getUserFriendlyError(dynamic error) {
    String errorMessage = error.toString();
    if (errorMessage.contains('401') || errorMessage.contains('403')) {
      return 'Authentication error. Please sign out and sign in again.';
    } else if (errorMessage.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorMessage.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorMessage.contains('cancelled')) {
      return 'Generation cancelled.';
    }
    return errorMessage.replaceFirst('Exception: ', '');
  }

  void _switchToMyRoadmaps() {
    final state = mainNavigationKey.currentState;
    if (state != null) {
      state.switchToTab(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create Your Learning Path",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          "Tell us what you want to learn",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Goal Input
              TextField(
                controller: _goalController,
                decoration: const InputDecoration(
                  labelText: 'What do you want to learn?',
                  hintText: 'e.g., Flutter, Python, Machine Learning',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                onSubmitted: (_) => _submitData(),
              ),
              const SizedBox(height: 16),

              // Example Goals
              Text(
                'Quick Start',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _exampleGoals.map((goal) {
                  return ActionChip(
                    label: Text(
                      goal['label'],
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    avatar: Icon(goal['icon'], size: 14),
                    onPressed: () {
                      setState(() {
                        _goalController.text = goal['label'];
                      });
                    },
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Difficulty Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedLevel,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    prefixIcon: Icon(Icons.signal_cellular_alt),
                  ),
                  items: ['Beginner', 'Intermediate', 'Advanced']
                      .map(
                        (lvl) => DropdownMenuItem(
                      value: lvl,
                      child: Row(
                        children: [
                          Icon(
                            _getLevelIcon(lvl),
                            color: _getLevelColor(lvl),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lvl,
                            style: GoogleFonts.inter(),
                          ),
                        ],
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedLevel = val!),
                  dropdownColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                      const Icon(Icons.auto_awesome, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Generate Roadmap',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.borderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: GoogleFonts.inter(
                        color: AppTheme.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppTheme.borderColor)),
                ],
              ),
              const SizedBox(height: 16),

              // View Roadmaps Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _switchToMyRoadmaps,
                  icon: const Icon(Icons.folder_outlined, size: 18),
                  label: Text(
                    'View My Roadmaps',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'Beginner':
        return Icons.star_outline;
      case 'Intermediate':
        return Icons.star_half;
      case 'Advanced':
        return Icons.star;
      default:
        return Icons.school;
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }
}

// ============== Loading Dialog ==============
class _LoadingDialog extends StatefulWidget {
  final String goal;
  final VoidCallback onCancel;

  const _LoadingDialog({required this.goal, required this.onCancel});

  @override
  State<_LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<_LoadingDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  int _currentStep = 0;
  double _progressValue = 0.0;

  final List<LoadingStep> _steps = [
    LoadingStep(
      icon: Icons.psychology_rounded,
      title: 'Understanding Your Goal',
      description: 'Analyzing learning objectives and skill requirements...',
    ),
    LoadingStep(
      icon: Icons.account_tree_rounded,
      title: 'Structuring Curriculum',
      description: 'Building optimal learning path and module hierarchy...',
    ),
    LoadingStep(
      icon: Icons.article_rounded,
      title: 'Creating Content',
      description: 'Generating lessons, examples, and practice exercises...',
    ),
    LoadingStep(
      icon: Icons.build_rounded,
      title: 'Adding Projects',
      description: 'Designing real-world capstone projects...',
    ),
    LoadingStep(
      icon: Icons.check_circle_rounded,
      title: 'Finalizing Roadmap',
      description: 'Polishing and preparing your personalized roadmap...',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.95).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _progressController.addListener(() {
      setState(() {
        _progressValue = _progressAnimation.value;
        _updateStep();
      });
    });

    _progressController.forward();
  }

  void _updateStep() {
    final stepIndex = (_progressValue * _steps.length).floor();
    if (stepIndex < _steps.length && stepIndex != _currentStep) {
      setState(() {
        _currentStep = stepIndex;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentStep.clamp(0, _steps.length - 1)];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.25),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      currentStep.icon,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),

            Text(
              'Generating Your Roadmap',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                '"${widget.goal}"',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 18),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(_progressValue * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _progressValue,
                    minHeight: 4,
                    backgroundColor: AppTheme.borderColor,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_right_alt_rounded,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currentStep.title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      currentStep.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 13,
                  color: AppTheme.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Estimated time: 15-30 seconds',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: widget.onCancel,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingStep {
  final IconData icon;
  final String title;
  final String description;

  LoadingStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}