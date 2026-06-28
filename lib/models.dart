class Roadmap {
  final String id;
  final String title;
  final String difficulty;
  final List<Module> modules;

  Roadmap({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.modules,
  });

  factory Roadmap.fromJson(Map<String, dynamic> json, String generatedId) {
    var list = json['modules'] as List? ?? [];
    List<Module> moduleList = list.map((i) => Module.fromJson(i)).toList();

    return Roadmap(
      id: generatedId,
      title: json['roadmap_title'] ?? 'Custom Roadmap Path',
      difficulty: json['difficulty'] ?? 'Beginner',
      modules: moduleList,
    );
  }
}

class Module {
  final int number;
  final String title;
  final String objective;
  final List<Topic> topics;
  final CapstoneProject project;

  Module({
    required this.number,
    required this.title,
    required this.objective,
    required this.topics,
    required this.project,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    var tList = json['topics'] as List? ?? [];
    List<Topic> topicObjects = tList.map((i) => Topic.fromJson(i)).toList();

    return Module(
      number: json['module_number'] ?? 0,
      title: json['module_title'] ?? 'Untitled Module',
      objective: json['module_objective'] ?? '',
      topics: topicObjects,
      project: CapstoneProject.fromJson(json['capstone_project'] ?? {}),
    );
  }
}

class Topic {
  final String title;
  final String summary;
  bool isCompleted;

  Topic({required this.title, required this.summary, this.isCompleted = false});

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      title: json['topic_title'] ?? 'Untitled Topic',
      summary: json['core_concept_summary'] ?? '',
    );
  }
}

class CapstoneProject {
  final String title;
  final List<String> requirements;
  final String guidelines;

  CapstoneProject({
    required this.title,
    required this.requirements,
    required this.guidelines,
  });

  factory CapstoneProject.fromJson(Map<String, dynamic> json) {
    var reqs = json['project_requirements'] as List? ?? [];
    return CapstoneProject(
      title: json['project_title'] ?? 'Module Assignment',
      requirements: reqs.map((e) => e.toString()).toList(),
      guidelines:
          json['submission_guidelines'] ?? 'Submit via the workspace console.',
    );
  }
}
