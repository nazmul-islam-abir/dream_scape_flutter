import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';

class ProjectReviewScreen extends StatefulWidget {
  final String projectTitle;

  const ProjectReviewScreen({super.key, required this.projectTitle});

  @override
  State<ProjectReviewScreen> createState() => _ProjectReviewScreenState();
}

class _ProjectReviewScreenState extends State<ProjectReviewScreen> {
  final _codeController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final _aiService = AiService();

  bool _isEvaluating = false;
  Map<String, dynamic>? _evaluationResult;

  Future<void> _submitAssignmentPipeline() async {
    if (_codeController.text.trim().isEmpty) return;

    setState(() {
      _isEvaluating = true;
      _evaluationResult = null;
    });

    try {
      final analysis = await _aiService.evaluateProjectSubmission(
        widget.projectTitle,
        _codeController.text,
      );
      final bool isPassedStatus =
          analysis['status']?.toString().toLowerCase() == 'perfect';

      await _supabase.from('project_submissions').insert({
        'project_title': widget.projectTitle,
        'submitted_code': _codeController.text,
        'ai_review': analysis,
        'is_passed': isPassedStatus,
      });

      setState(() {
        _evaluationResult = analysis;
        _isEvaluating = false;
      });
    } catch (e) {
      setState(() {
        _isEvaluating = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Pipeline error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Capstone Guardrails")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            "Project Workspace: ${widget.projectTitle}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            maxLines: 10,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText:
                  "// Paste implementation or terminal architecture scripts here...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isEvaluating ? null : _submitAssignmentPipeline,
            child: Text(
              _isEvaluating
                  ? "Analyzing Infrastructure Elements..."
                  : "Execute Validation Review",
            ),
          ),
          if (_evaluationResult != null) ...[
            const Divider(height: 32),
            Text(
              "Result Status: ${_evaluationResult!['status'].toString().toUpperCase()}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _evaluationResult!['status'] == 'perfect'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(_evaluationResult!['critique_summary'] ?? ''),
            const SizedBox(height: 8),
            ...(_evaluationResult!['identified_issues'] as List? ?? []).map(
              (issue) => Text("• $issue"),
            ),
            const SizedBox(height: 8),
            Text(
              "Remedial Steps: ${_evaluationResult!['remedial_steps'] ?? ''}",
            ),
          ],
        ],
      ),
    );
  }
}
