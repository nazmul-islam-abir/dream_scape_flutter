import 'package:flutter/material.dart';

class RoadmapSkeletonLoader extends StatefulWidget {
  final String userGoal;

  const RoadmapSkeletonLoader({super.key, required this.userGoal});

  @override
  State<RoadmapSkeletonLoader> createState() => _RoadmapSkeletonLoaderState();
}

class _RoadmapSkeletonLoaderState extends State<RoadmapSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  int _statusIndex = 0;
  final List<String> _loadingStatuses = [
    "Analyzing target domain dynamics...",
    "Breaking target architecture into optimized modules...",
    "Injecting real-world project specifications...",
    "Synthesizing step-by-step documentation paradigms...",
    "Finalizing structural roadmap schema...",
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_shimmerController);
    _rotateStatusText();
  }

  void _rotateStatusText() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 2800));
      if (mounted && _statusIndex < _loadingStatuses.length - 1) {
        setState(() {
          _statusIndex++;
        });
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Synthesizing Path..."),
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Cancel',
          ),
        ),
        body: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Target Goal: \"${widget.userGoal}\"",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: Text(
                                _loadingStatuses[_statusIndex],
                                key: ValueKey<int>(_statusIndex),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 3,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildSkeletonBlock(
                                  width: 40,
                                  height: 40,
                                  isCircle: true,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSkeletonBlock(
                                        width: 180,
                                        height: 16,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildSkeletonBlock(
                                        width: double.infinity,
                                        height: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildSkeletonBlock(
                              width: double.infinity,
                              height: 45,
                            ),
                            const SizedBox(height: 12),
                            _buildSkeletonBlock(
                              width: double.infinity,
                              height: 45,
                            ),
                            const SizedBox(height: 16),
                            _buildSkeletonBlock(
                              width: double.infinity,
                              height: 110,
                              radius: 8,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonBlock({
    required double width,
    required double height,
    bool isCircle = false,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: [
            _shimmerAnimation.value - 0.4,
            _shimmerAnimation.value,
            _shimmerAnimation.value + 0.4,
          ],
        ),
      ),
    );
  }
}
