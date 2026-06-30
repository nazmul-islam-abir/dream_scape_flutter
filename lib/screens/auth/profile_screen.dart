import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'firebase_auth_service.dart';
import '../../main.dart';
import 'login_screen.dart';
import '../../services/learning_tracker_service.dart';
import '../../models/learning.dart';
import '../../models/learning_category.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = FirebaseAuthService();
  final _learningService = LearningTrackerService();
  final _supabase = Supabase.instance.client;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _visionController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isLoadingData = true;
  User? _user;

  // Learning data
  List<DailyLearningLog> _logs = [];
  List<Map<String, dynamic>> _roadmaps = [];
  Map<String, dynamic> _learningStats = {};
  String? _userVision;
  int _totalRoadmaps = 0;
  double _averageProgress = 0.0;
  int _totalTopicsLearned = 0;
  int _totalHoursSpent = 0;
  int _learningStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _visionController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final user = _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _user = user;
        _usernameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
      });
    }
  }

  Future<void> _loadUserData() async {
    final userId = _authService.getUserId();
    if (userId == null) {
      setState(() => _isLoadingData = false);
      return;
    }

    setState(() => _isLoadingData = true);

    try {
      // Load learning logs
      final logs = await _learningService.getDailyLogs(userId);

      // Load roadmaps
      final roadmaps = await _supabase
          .from('user_roadmaps')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Load user vision from profile
      final profile = await _supabase
          .from('user_profiles')
          .select('vision, bio')
          .eq('user_id', userId)
          .maybeSingle();

      // Load learning stats summary
      final stats = await _learningService.getLearningInsights(userId);

      setState(() {
        _logs = logs;
        _roadmaps = List<Map<String, dynamic>>.from(roadmaps);
        _userVision = profile?['vision'] as String?;
        _totalRoadmaps = _roadmaps.length;

        // Calculate average progress
        if (_roadmaps.isNotEmpty) {
          double totalProgress = 0;
          for (var roadmap in _roadmaps) {
            totalProgress += (roadmap['progress'] as num?)?.toDouble() ?? 0.0;
          }
          _averageProgress = totalProgress / _roadmaps.length;
        }

        _totalTopicsLearned = stats['totalTopicsLearned'] ?? 0;
        _totalHoursSpent = (stats['totalTimeSpent'] ?? 0) ~/ 60;
        _learningStreak = stats['streakDays'] ?? 0;

        _isLoadingData = false;
      });

      // Set vision controller
      _visionController.text = _userVision ?? '';

    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _saveVision() async {
    final userId = _authService.getUserId();
    if (userId == null) return;

    try {
      await _supabase
          .from('user_profiles')
          .update({
        'vision': _visionController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('user_id', userId);

      setState(() {
        _userVision = _visionController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vision updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving vision: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username cannot be empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.updateProfile(
        username: _usernameController.text.trim(),
      );

      // Also update Supabase profile
      final userId = _authService.getUserId();
      if (userId != null) {
        await _supabase
            .from('user_profiles')
            .update({
          'username': _usernameController.text.trim(),
          'full_name': _usernameController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('user_id', userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error signing out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null || _isLoadingData) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditing = true);
              },
              tooltip: 'Edit Profile',
            ),
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadProfile();
                });
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              _buildProfileHeader(),
              const SizedBox(height: 20),

              // Stats Cards
              _buildStatsCards(),
              const SizedBox(height: 16),

              // Vision Section
              _buildVisionSection(),
              const SizedBox(height: 16),

              // Learning Summary
              _buildLearningSummary(),
              const SizedBox(height: 16),

              // Recent Learning Logs
              _buildRecentLogs(),
              const SizedBox(height: 16),

              // My Roadmaps
              _buildRoadmapsSection(),
              const SizedBox(height: 16),

              // Edit Profile Section
              if (_isEditing) _buildEditProfileSection(),

              // Sign Out Button
              _buildSignOutButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
          stops: const [0.3, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              _user?.displayName?.substring(0, 1).toUpperCase() ??
                  _user?.email?.substring(0, 1).toUpperCase() ??
                  'U',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.displayName ?? 'User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _user?.email ?? 'No email',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _user?.emailVerified == true
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _user?.emailVerified == true
                        ? '✅ Verified'
                        : '⚠️ Not Verified',
                    style: TextStyle(
                      fontSize: 11,
                      color: _user?.emailVerified == true
                          ? Colors.white
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _learningStreak.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  '🔥 Streak',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          '📚',
          '$_totalTopicsLearned',
          'Topics Learned',
          Colors.blue.shade700,
        ),
        _buildStatCard(
          '⏰',
          '$_totalHoursSpent h',
          'Total Hours',
          Colors.purple.shade700,
        ),
        _buildStatCard(
          '🗺️',
          '$_totalRoadmaps',
          'Roadmaps',
          Colors.green.shade700,
        ),
        _buildStatCard(
          '📊',
          '${(_averageProgress * 100).toStringAsFixed(0)}%',
          'Avg Progress',
          Colors.orange.shade700,
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), Colors.white],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisionSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.visibility_outlined,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                const Text(
                  'My Learning Vision',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() => _isEditing = true);
                    },
                    tooltip: 'Edit Vision',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isEditing)
              TextField(
                controller: _visionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'What is your learning vision?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            if (!_isEditing && _userVision != null && _userVision!.isNotEmpty)
              Text(
                _userVision!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
            if (!_isEditing && (_userVision == null || _userVision!.isEmpty))
              Text(
                'No vision set yet. Tap the edit icon to define your learning vision!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (_isEditing)
              const SizedBox(height: 12),
            if (_isEditing)
              ElevatedButton(
                onPressed: _saveVision,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text('Save Vision'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningSummary() {
    // Get category breakdown
    final categories = _logs.fold<Map<String, int>>({}, (map, log) {
      final category = log.category ?? 'Other';
      map[category] = (map[category] ?? 0) + 1;
      return map;
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Learning Distribution',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (categories.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No learning data yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...categories.entries.map(
                    (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '${entry.value} topics',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total: $_totalTopicsLearned topics across ${categories.length} categories',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLogs() {
    final recentLogs = _logs.take(3).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '📝 Recent Learning',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to Daily Learning tab
                    final state = mainNavigationKey.currentState;
                    if (state != null) {
                      state.switchToTab(3);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentLogs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No learning logs yet. Start learning today!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...recentLogs.map(
                    (log) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getDifficultyColor(
                      log.difficultyLevel,
                    ).withOpacity(0.2),
                    child: Text(
                      log.difficultyLevel.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: _getDifficultyColor(log.difficultyLevel),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    log.topic,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${log.timeSpentMinutes} min • ${_formatDate(log.date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: log.category != null
                          ? _getCategoryColor(log.category!).withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      log.category ?? 'Other',
                      style: TextStyle(
                        fontSize: 10,
                        color: log.category != null
                            ? _getCategoryColor(log.category!)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapsSection() {
    final recentRoadmaps = _roadmaps.take(3).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '🗺️ My Roadmaps',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to My Roadmaps tab
                    final state = mainNavigationKey.currentState;
                    if (state != null) {
                      state.switchToTab(1);
                    }
                    Navigator.pop(context);
                  },
                  child: Text('View All (${_roadmaps.length})'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_roadmaps.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No roadmaps yet. Generate your first roadmap!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...recentRoadmaps.map(
                    (roadmap) {
                  final fullData = roadmap['full_data'] as Map<String, dynamic>? ?? {};
                  final title = fullData['roadmap_title'] ?? 'Untitled Roadmap';
                  final progress = (roadmap['progress'] as num?)?.toDouble() ?? 0.0;
                  final difficulty = fullData['difficulty'] ?? 'Beginner';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                      child: Text(
                        _getDifficultyIcon(difficulty),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(difficulty).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getDifficultyColor(difficulty),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                    onTap: () {
                      // Navigate to roadmap
                      Navigator.pop(context);
                      final state = mainNavigationKey.currentState;
                      if (state != null) {
                        state.switchToTab(1);
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditProfileSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.red.shade200),
        ),
      ),
    );
  }

  // Helper methods
  Color _getCategoryColor(String category) {
    final colors = {
      'Frontend Development': Colors.blue.shade600,
      'Backend Development': Colors.green.shade600,
      'Mobile Development': Colors.purple.shade600,
      'Database': Colors.orange.shade600,
      'DevOps': Colors.red.shade600,
      'Machine Learning': Colors.pink.shade600,
      'UI/UX Design': Colors.teal.shade600,
      'Programming Languages': Colors.indigo.shade600,
      'Web Development': Colors.cyan.shade600,
    };
    return colors[category] ?? Colors.grey.shade600;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'beginner':
        return Colors.green;
      case 'medium':
      case 'intermediate':
        return Colors.orange;
      case 'hard':
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'beginner':
        return '🟢';
      case 'medium':
      case 'intermediate':
        return '🟠';
      case 'hard':
      case 'advanced':
        return '🔴';
      default:
        return '⚪';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}