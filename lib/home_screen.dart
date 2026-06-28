import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';
import 'roadmap_explorer_screen.dart';
import 'main.dart'; // Import main to access the global key

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

  void _submitData() async {
    if (_goalController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Generate the roadmap using AI
      final parsedJson = await AiService().generateRoadmap(
        _goalController.text,
        _selectedLevel,
      );

      // 2. Store the roadmap in Supabase
      final roadMapData = {
        'user_goal': _goalController.text.trim(),
        'difficulty': _selectedLevel,
        'full_data': parsedJson,
      };

      final response = await _supabase
          .from('user_roadmaps')
          .insert(roadMapData)
          .select()
          .single();

      // 3. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Roadmap generated and saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // 4. Navigate to roadmap explorer
        Navigator.push(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _switchToMyRoadmaps() {
    // Use the global key to switch tabs
    final state = mainNavigationKey.currentState;
    if (state != null) {
      state.switchToTab(1); // Switch to "My Roadmaps" tab (index 1)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "What do you want to learn today?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _goalController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "e.g., Cross-Platform Flutter Basics",
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedLevel,
                    items: ['Beginner', 'Intermediate', 'Advanced']
                        .map(
                          (lvl) =>
                              DropdownMenuItem(value: lvl, child: Text(lvl)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedLevel = val!),
                    decoration: const InputDecoration(
                      labelText: "Your level",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Build Curriculum Roadmap"),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _switchToMyRoadmaps,
                    icon: const Icon(Icons.folder_outlined),
                    label: const Text('View My Saved Roadmaps'),
                  ),
                ],
              ),
            ),
    );
  }
}
