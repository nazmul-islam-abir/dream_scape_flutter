import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/firebase_auth_service.dart';
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
  String _loadingMessage = '';
  bool _isCancelled = false;

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
      _loadingMessage = 'Starting roadmap generation...';
    });

    // Show the loading dialog
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
      // Generate the roadmap
      final parsedJson = await AiService().generateRoadmap(
        _goalController.text.trim(),
        _selectedLevel,
      );

      // Check if generation was cancelled
      if (_isCancelled || !mounted) {
        return;
      }

      // Save to Supabase
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

      // Close loading dialog
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }

      // Show success and navigate
      if (mounted) {
        _showSnackBar('✅ Roadmap generated successfully!', Colors.green);

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
      // Check if it's a cancellation
      if (e.toString().contains('cancelled')) {
        _isCancelled = true;
        if (mounted) {
          try {
            Navigator.pop(context);
          } catch (_) {}
        }
        return;
      }

      // Close loading dialog if open
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
          _loadingMessage = '';
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "What do you want to learn today?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Enter your goal and we'll build a custom roadmap",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _goalController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: "e.g., Cross-Platform Flutter Basics",
                prefixIcon: const Icon(Icons.flag_outlined),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onSubmitted: (_) => _submitData(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLevel,
              items: ['Beginner', 'Intermediate', 'Advanced']
                  .map(
                    (lvl) => DropdownMenuItem(
                      value: lvl,
                      child: Row(
                        children: [
                          Icon(
                            _getLevelIcon(lvl),
                            color: _getLevelColor(lvl),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(lvl),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedLevel = val!),
              decoration: InputDecoration(
                labelText: "Your experience level",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(_loadingMessage),
                  ] else ...[
                    const Icon(Icons.auto_awesome),
                    const SizedBox(width: 12),
                    const Text(
                      "Build Curriculum Roadmap",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _switchToMyRoadmaps,
              icon: const Icon(Icons.folder_outlined),
              label: const Text(
                'View My Saved Roadmaps',
                style: TextStyle(fontSize: 14),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ],
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
        return Colors.blue;
    }
  }
}

// ===================== LOADING DIALOG WIDGET =====================

class _LoadingDialog extends StatefulWidget {
  final String goal;
  final VoidCallback onCancel;

  const _LoadingDialog({required this.goal, required this.onCancel});

  @override
  State<_LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<_LoadingDialog>
    with TickerProviderStateMixin {
  // Fixed: Using TickerProviderStateMixin instead of SingleTickerProviderStateMixin
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

    // Pulse animation for the icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Progress animation
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

    return WillPopScope(
      onWillPop: () async {
        widget.onCancel();
        return false;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        currentStep.icon,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Generating Your Roadmap',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              // Goal
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  '"${widget.goal}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 20),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(_progressValue * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progressValue,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Current Step
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_right_alt_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentStep.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Text(
                        currentStep.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Estimated time
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Estimated time: 15-30 seconds',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: widget.onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
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
