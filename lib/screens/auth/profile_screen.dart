import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'firebase_auth_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../theme/app_theme.dart';
import '../../services/learning_tracker_service.dart';
import '../../models/learning.dart';
import '../../models/post.dart';
import '../../services/social_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = FirebaseAuthService();
  final _learningService = LearningTrackerService();
  final _socialService = SocialService();
  final _supabase = Supabase.instance.client;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _visionController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isLoadingData = true;
  User? _user;

  // Learning data
  List<DailyLearningLog> _logs = [];
  List<Map<String, dynamic>> _roadmaps = [];
  List<Post> _userPosts = [];
  Map<String, dynamic> _learningStats = {};
  String? _userVision;
  String? _userBio;
  int _totalRoadmaps = 0;
  double _averageProgress = 0.0;
  int _totalTopicsLearned = 0;
  int _totalHoursSpent = 0;
  int _learningStreak = 0;
  int _followersCount = 0;
  int _followingCount = 0;

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
    _bioController.dispose();
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
      final logs = await _learningService.getDailyLogs(userId);
      final roadmaps = await _supabase
          .from('user_roadmaps')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final posts = await _socialService.getPosts(userId: userId);

      final profile = await _supabase
          .from('user_profiles')
          .select('vision, bio, followers_count, following_count')
          .eq('user_id', userId)
          .maybeSingle();

      final stats = await _learningService.getLearningInsights(userId);

      setState(() {
        _logs = logs;
        _roadmaps = List<Map<String, dynamic>>.from(roadmaps);
        _userPosts = posts;
        _userVision = profile?['vision'] as String?;
        _userBio = profile?['bio'] as String?;
        _followersCount = (profile?['followers_count'] as int?) ?? 0;
        _followingCount = (profile?['following_count'] as int?) ?? 0;
        _totalRoadmaps = _roadmaps.length;

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

      _visionController.text = _userVision ?? '';
      _bioController.text = _userBio ?? '';
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _saveProfile() async {
    final userId = _authService.getUserId();
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Update user profile in Supabase
      await _supabase.from('user_profiles').upsert({
        'user_id': userId,
        'vision': _visionController.text.trim(),
        'bio': _bioController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update Firebase display name
      await _authService.updateProfile(
        username: _usernameController.text.trim(),
      );

      setState(() {
        _userVision = _visionController.text.trim();
        _userBio = _bioController.text.trim();
        _isEditing = false;
        _isLoading = false;
      });

      _showSnackBar('Profile updated successfully! ✅', Colors.green);
    } catch (e) {
      _showSnackBar('Error saving profile: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 5) {
      // Already on profile, do nothing
      return;
    }
    // Navigate to other screens
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null || _isLoadingData) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 5,
          onTap: _onNavTap,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () {
                setState(() => _isEditing = true);
              },
              child: Text(
                'Edit',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _visionController.text = _userVision ?? '';
                  _bioController.text = _userBio ?? '';
                  _usernameController.text = _user?.displayName ?? '';
                });
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
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
              const SizedBox(height: 16),

              // Stats Cards
              _buildStatsCards(),
              const SizedBox(height: 16),

              // Bio Section
              _buildBioSection(),
              const SizedBox(height: 16),

              // Vision Section
              _buildVisionSection(),
              const SizedBox(height: 16),

              // Learning Progress Chart
              _buildLearningChart(),
              const SizedBox(height: 16),

              // Skills / Topics Learned
              _buildSkillsSection(),
              const SizedBox(height: 16),

              // My Roadmaps
              _buildRoadmapsSection(),
              const SizedBox(height: 16),

              // My Posts
              _buildPostsSection(),
              const SizedBox(height: 16),

              // Edit Section
              if (_isEditing) _buildEditSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 5,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              _user?.displayName?.substring(0, 1).toUpperCase() ??
                  _user?.email?.substring(0, 1).toUpperCase() ??
                  'U',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
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
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  _user?.email ?? 'No email',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _user?.emailVerified == true
                            ? AppTheme.secondaryColor.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _user?.emailVerified == true
                            ? '✅ Verified'
                            : '⚠️ Not Verified',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _user?.emailVerified == true
                              ? AppTheme.secondaryColor
                              : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🔥 $_learningStreak day streak',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '👥 $_followersCount followers',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '👤 $_followingCount following',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('📚', '$_totalTopicsLearned', 'Topics'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard('⏰', '$_totalHoursSpent h', 'Hours'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard('🗺️', '$_totalRoadmaps', 'Roadmaps'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard('📊', '${(_averageProgress * 100).toStringAsFixed(0)}%', 'Progress'),
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📝 Bio',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          if (_userBio != null && _userBio!.isNotEmpty)
            Text(
              _userBio!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            )
          else
            Text(
              'No bio yet. Tap Edit to add one!',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVisionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Learning Vision',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          if (_userVision != null && _userVision!.isNotEmpty)
            Text(
              _userVision!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            )
          else
            Text(
              'No vision set yet. Tap Edit to define your learning vision!',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLearningChart() {
    final weeklyProgress =
        _learningStats['weeklyProgress'] as Map<String, double>? ?? {};

    if (weeklyProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = weeklyProgress.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final data = sortedEntries.map((entry) {
      final date = DateTime.parse(entry.key);
      return WeeklyData(
        day: '${date.day}/${date.month}',
        value: entry.value,
      );
    }).toList();

    final maxValue = data.isEmpty
        ? 2.0
        : data.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Weekly Learning Activity',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              data[index].day,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textLight,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.value,
                        color: AppTheme.primaryColor,
                        width: 20,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    final topics = _logs.map((log) => log.topic).toSet().toList();
    final categories = _logs
        .where((log) => log.category != null)
        .map((log) => log.category!)
        .toSet()
        .toList();

    if (topics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🛠️ Skills & Topics',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: topics.take(10).map((topic) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                  ),
                ),
                child: Text(
                  topic,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Categories: ${categories.join(", ")}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          if (topics.length > 10)
            Text(
              '+ ${topics.length - 10} more topics',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoadmapsSection() {
    if (_roadmaps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🗺️ My Roadmaps',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (_roadmaps.length > 3)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'View All (${_roadmaps.length})',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._roadmaps.take(3).map((roadmap) {
            final fullData = roadmap['full_data'] as Map<String, dynamic>? ?? {};
            final title = fullData['roadmap_title'] ?? 'Untitled Roadmap';
            final difficulty = fullData['difficulty'] ?? 'Beginner';
            final progress = (roadmap['progress'] as num?)?.toDouble() ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(difficulty).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getDifficultyIcon(difficulty),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              difficulty,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: _getDifficultyColor(difficulty),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.transparent,
                        color: AppTheme.primaryColor,
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    if (_userPosts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📝 My Posts',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (_userPosts.length > 2)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'View All (${_userPosts.length})',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._userPosts.take(2).map((post) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.topicTitle != null)
                    Text(
                      '📚 ${post.topicTitle}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    post.content.length > 100
                        ? '${post.content.substring(0, 100)}...'
                        : post.content,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 14,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likesCount}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.comment_outlined,
                        size: 14,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentsCount}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEditSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✏️ Edit Profile',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell others about yourself',
              prefixIcon: Icon(Icons.description_outlined),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _visionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Learning Vision',
              hintText: 'What is your learning vision?',
              prefixIcon: Icon(Icons.visibility_outlined),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _visionController.text = _userVision ?? '';
                      _bioController.text = _userBio ?? '';
                      _usernameController.text = _user?.displayName ?? '';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
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
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return '🟢';
      case 'intermediate':
        return '🟠';
      case 'advanced':
        return '🔴';
      default:
        return '⚪';
    }
  }
}

class WeeklyData {
  final String day;
  final double value;

  WeeklyData({required this.day, required this.value});
}