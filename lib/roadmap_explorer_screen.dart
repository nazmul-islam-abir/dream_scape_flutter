import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'topic_learning_screen.dart';
import 'project_review_screen.dart';

class RoadmapExplorerScreen extends StatefulWidget {
  final Map<String, dynamic> rawRoadmapData;
  final String? roadmapId;

  const RoadmapExplorerScreen({
    super.key,
    required this.rawRoadmapData,
    this.roadmapId,
  });

  @override
  State<RoadmapExplorerScreen> createState() => _RoadmapExplorerScreenState();
}

class _RoadmapExplorerScreenState extends State<RoadmapExplorerScreen> {
  late Roadmap _roadmap;
  double _progressValue = 0.0;
  final _supabase = Supabase.instance.client;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeRoadmap();
  }

  Future<void> _initializeRoadmap() async {
    setState(() => _isLoading = true);

    try {
      // Parse the roadmap data
      _roadmap = Roadmap.fromJson(
        widget.rawRoadmapData,
        "generated_roadmap_id",
      );

      // Load progress from database
      await _loadProgressFromDatabase();

      // Calculate progress
      _calculateProgress();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing roadmap: $e');
      setState(() => _isLoading = false);
    }
  }

  // Load saved progress from database
  Future<void> _loadProgressFromDatabase() async {
    final roadmapId = widget.roadmapId;
    if (roadmapId == null || roadmapId.isEmpty) {
      return;
    }

    try {
      final response = await _supabase
          .from('user_roadmaps')
          .select('full_data, progress')
          .eq('id', roadmapId)
          .single();

      if (response != null && response['full_data'] != null) {
        final savedData = response['full_data'] as Map<String, dynamic>;
        final savedModules = savedData['modules'] as List? ?? [];

        // Update topic completion status from saved data
        for (
          var i = 0;
          i < _roadmap.modules.length && i < savedModules.length;
          i++
        ) {
          final savedModule = savedModules[i];
          final savedTopics = savedModule['topics'] as List? ?? [];

          for (
            var j = 0;
            j < _roadmap.modules[i].topics.length && j < savedTopics.length;
            j++
          ) {
            final savedTopic = savedTopics[j];
            final isCompleted = savedTopic['isCompleted'] ?? false;
            _roadmap.modules[i].topics[j].isCompleted = isCompleted;
          }
        }
      }
    } catch (e) {
      print('Error loading progress: $e');
    }
  }

  void _calculateProgress() {
    int totalTopics = 0;
    int completedTopics = 0;

    for (var module in _roadmap.modules) {
      for (var topic in module.topics) {
        totalTopics++;
        if (topic.isCompleted) completedTopics++;
      }
    }

    setState(() {
      _progressValue = totalTopics == 0 ? 0.0 : completedTopics / totalTopics;
    });

    // Save progress to database
    _saveProgressToDatabase();
  }

  Future<void> _saveProgressToDatabase() async {
    final roadmapId = widget.roadmapId;
    if (roadmapId == null || roadmapId.isEmpty || _isSaving) return;

    _isSaving = true;

    try {
      // Get current full_data from database
      final response = await _supabase
          .from('user_roadmaps')
          .select('full_data')
          .eq('id', roadmapId)
          .single();

      if (response != null && response['full_data'] != null) {
        // Update the stored data with current progress
        final updatedData = response['full_data'] as Map<String, dynamic>;
        final modules = updatedData['modules'] as List? ?? [];

        // Update each module's topics with completion status
        for (
          var i = 0;
          i < modules.length && i < _roadmap.modules.length;
          i++
        ) {
          final module = modules[i];
          final topics = module['topics'] as List? ?? [];

          for (
            var j = 0;
            j < topics.length && j < _roadmap.modules[i].topics.length;
            j++
          ) {
            topics[j]['isCompleted'] =
                _roadmap.modules[i].topics[j].isCompleted;
          }
        }

        // Update the database with new progress
        await _supabase
            .from('user_roadmaps')
            .update({
              'full_data': updatedData,
              'progress': _progressValue,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', roadmapId);
      }
    } catch (e) {
      print('Error saving progress: $e');
    } finally {
      _isSaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading roadmap...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_roadmap.title),
        elevation: 1,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.25),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Curriculum Mastery Index",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${(_progressValue * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progressValue,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade300,
                    color: _progressValue == 1.0
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Difficulty: ${_roadmap.difficulty.toUpperCase()}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.roadmapId != null)
                      Text(
                        "ID: ${widget.roadmapId!.substring(0, 8)}...",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Modules List
          Expanded(
            child: ListView.builder(
              itemCount: _roadmap.modules.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, mIdx) {
                final module = _roadmap.modules[mIdx];
                bool isProjectUnlocked = module.topics.every(
                  (t) => t.isCompleted,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      child: Text("${module.number}"),
                    ),
                    title: Text(
                      module.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      module.objective,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    children: [
                      const Divider(height: 1),
                      // Topics List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: module.topics.length,
                        itemBuilder: (context, tIdx) {
                          final topic = module.topics[tIdx];
                          return ListTile(
                            leading: Checkbox(
                              value: topic.isCompleted,
                              onChanged: (val) {
                                setState(() {
                                  topic.isCompleted = val!;
                                  _calculateProgress();
                                });
                              },
                            ),
                            title: Text(
                              topic.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                decoration: topic.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: topic.isCompleted ? Colors.grey : null,
                              ),
                            ),
                            subtitle: Text(
                              topic.summary,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: TextButton.icon(
                              icon: const Icon(Icons.school_outlined, size: 16),
                              label: const Text("Learn"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TopicLearningScreen(
                                      topicTitle: topic.title,
                                      courseContext: _roadmap.title,
                                    ),
                                  ),
                                ).then((_) {
                                  // Refresh progress when returning from learning
                                  _calculateProgress();
                                });
                              },
                            ),
                          );
                        },
                      ),
                      // Capstone Project Section
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isProjectUnlocked
                              ? Colors.green.withOpacity(0.04)
                              : Colors.grey.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isProjectUnlocked
                                ? Colors.green
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isProjectUnlocked
                                      ? Icons.lock_open_rounded
                                      : Icons.lock_rounded,
                                  color: isProjectUnlocked
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Capstone: ${module.project.title}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...module.project.requirements.map(
                              (req) => Text(
                                "• $req",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.cloud_upload_outlined,
                                size: 18,
                              ),
                              label: const Text("Open AI Evaluation Workspace"),
                              onPressed: isProjectUnlocked
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProjectReviewScreen(
                                            projectTitle: module.project.title,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isProjectUnlocked
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
