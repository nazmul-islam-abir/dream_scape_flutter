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
  bool _isGenerating = false;
  Map<String, dynamic>? _lessonData;
  String _errorMessage = '';
  String _loadingMessage = 'Loading lesson...';
  int _currentLoadingStep = 0;

  final List<String> _loadingMessages = [
    '📚 Retrieving cached lesson content...',
    '🤖 Preparing interactive learning materials...',
    '🧠 Analyzing topic structure...',
    '📝 Generating personalized explanations...',
    '💡 Creating real-world examples...',
    '✨ Finalizing your lesson...',
  ];

  @override
  void initState() {
    super.initState();
    _loadLessonLifecycle();
    _startLoadingAnimation();
  }

  void _startLoadingAnimation() {
    // Animate through loading messages
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isLoading) {
        setState(() {
          _currentLoadingStep = (_currentLoadingStep + 1) % _loadingMessages.length;
          _loadingMessage = _loadingMessages[_currentLoadingStep];
        });
        _startLoadingAnimation();
      }
    });
  }

  Future<void> _loadLessonLifecycle() async {
    try {
      // Check cache first
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

      // Not in cache - generate new lesson
      setState(() {
        _isGenerating = true;
        _loadingMessage = '🤖 Generating new lesson content...';
      });

      final freshLesson = await _aiService.fetchTopicLesson(
        widget.topicTitle,
        widget.courseContext,
      );

      // Save to cache
      await _supabase.from('cached_lessons').insert({
        'topic_title': widget.topicTitle,
        'lesson_data': freshLesson,
      });

      setState(() {
        _lessonData = freshLesson;
        _isLoading = false;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isGenerating = false;
      });
    }
  }

  void _retryLoading() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _loadingMessage = 'Retrying...';
    });
    _loadLessonLifecycle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading State with Animation
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Icon
                TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 2),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.5 + (0.5 * value),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary
                                .withOpacity(0.1),
                          ),
                          child: Icon(
                            _isGenerating
                                ? Icons.auto_awesome
                                : Icons.school_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                // Loading Title
                Text(
                  _isGenerating ? 'Creating Your Lesson' : 'Loading Lesson',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Animated Loading Message
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Text(
                    _loadingMessage,
                    key: ValueKey(_loadingMessage),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                // Progress Indicator
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _isGenerating ? null : 0.5,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isGenerating)
                        Text(
                          'This may take a few seconds...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Fun facts or tips
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getRandomTip(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Error State
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade50,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _retryLoading,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Lesson Content
    final walkthrough = _lessonData!['step_by_step_walkthrough'] as List? ?? [];
    final codeSnippet = _lessonData!['demo_code_snippet'] ?? '';
    final practiceExercise = _lessonData!['practice_exercise_prompt'] ?? '';

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Conceptual Explanation Card
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Conceptual Theory",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _lessonData!['conceptual_explanation'] ?? '',
                  style: const TextStyle(height: 1.6, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Analogy Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.compare_arrows, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    "Everyday Analogy",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _lessonData!['analogy'] ?? '',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue.shade800,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Step-by-Step Walkthrough
        const Text(
          "📋 Execution Roadmap",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        ...walkthrough.asMap().entries.map(
              (entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Center(
                    child: Text(
                      "${entry.key + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Code Snippet
        if (codeSnippet.isNotEmpty) ...[
          const Text(
            "💻 Reference Code Architecture",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                codeSnippet,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Practice Exercise
        if (practiceExercise.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      "🎯 Practice Challenge",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  practiceExercise,
                  style: TextStyle(
                    color: Colors.green.shade800,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Roadmap'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getRandomTip() {
    final tips = [
      '💡 Practice makes perfect! Try the code examples yourself.',
      '🎯 Focus on understanding the core concept before moving on.',
      '📝 Take notes while learning for better retention.',
      '🔁 Review the analogy if you get stuck on a concept.',
      '🚀 Apply what you learn by modifying the example code.',
      '🧠 Connect new concepts to what you already know.',
      '💪 Don\'t rush - understanding takes time!',
      '🌟 Every expert was once a beginner.',
    ];
    return tips[_currentLoadingStep % tips.length];
  }
}