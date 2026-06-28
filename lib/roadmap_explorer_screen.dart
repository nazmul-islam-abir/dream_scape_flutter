import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'topic_learning_screen.dart';
import 'project_review_screen.dart';

class RoadmapExplorerScreen extends StatefulWidget {
  final Map<String, dynamic> rawRoadmapData;
  final String? roadmapId; // Optional for future progress tracking

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

  @override
  void initState() {
    super.initState();
    _roadmap = Roadmap.fromJson(widget.rawRoadmapData, "generated_roadmap_id");
    _calculateProgress();
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

    // Optionally update progress in Supabase
    _updateProgressInSupabase();
  }

  Future<void> _updateProgressInSupabase() async {
    // Early return if roadmapId is null or empty
    final roadmapId = widget.roadmapId;
    if (roadmapId == null || roadmapId.isEmpty) return;

    try {
      // Calculate completion percentage
      int totalTopics = 0;
      int completedTopics = 0;

      for (var module in _roadmap.modules) {
        for (var topic in module.topics) {
          totalTopics++;
          if (topic.isCompleted) completedTopics++;
        }
      }

      final progress = totalTopics == 0 ? 0.0 : completedTopics / totalTopics;

      // Update the roadmap progress in Supabase
      await _supabase
          .from('user_roadmaps')
          .update({
            'progress': progress,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', roadmapId); // Now roadmapId is guaranteed non-null
    } catch (e) {
      print('Error updating progress: $e');
      // Don't show error to user, it's a background update
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_roadmap.title),
        elevation: 1,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
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
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
                                );
                              },
                            ),
                          );
                        },
                      ),
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
