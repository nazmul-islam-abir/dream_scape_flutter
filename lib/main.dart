import 'package:dream_scape/screens/auth/firebase_auth_service.dart';
import 'package:dream_scape/screens/auth/login_screen.dart';
import 'package:dream_scape/screens/auth/profile_screen.dart';
import 'package:dream_scape/screens/explorer_screen.dart';
import 'package:dream_scape/screens/daily_learning_screen.dart';
import 'package:dream_scape/screens/learning_path_screen.dart';
import 'package:dream_scape/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'home_screen.dart';
import 'my_roadmaps_screen.dart';
import 'theme/app_theme.dart';

import 'widgets/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseApp? app;
  try {
    app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      try {
        app = Firebase.app();
      } catch (innerError) {
        print('Error getting existing Firebase app: $innerError');
      }
    } else {
      print('Firebase initialization error: $e');
    }
  }

  try {
    await Supabase.initialize(
      url: 'https://vfnjcomfshwosmgoqdqs.supabase.co',
      anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmbmpjb21mc2h3b3NtZ29xZHFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2NTY1MjgsImV4cCI6MjA5ODIzMjUyOH0.FgjRWYX9c3gFqjsc8dnLNsBvjwsfPml3FqgzSibsKKQ',
    );
  } catch (e) {
    print('Supabase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DreamScape Learning',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking authentication...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Error',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user != null && user.emailVerified) {
          return const MainNavigationScreen();
        }

        if (user != null && !user.emailVerified) {
          return _buildVerifyEmailScreen(context, user);
        }

        return const LoginScreen();
      },
    );
  }

  Widget _buildVerifyEmailScreen(BuildContext context, User user) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_rounded,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification email to:\n${user.email}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your inbox and click the verification link.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      '💡 Tips:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Check your spam/junk folder\n'
                          '• Wait a minute for the email to arrive\n'
                          '• Click the link in the email to verify',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.amber.shade700,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await user.sendEmailVerification();
                          _showSnackBar(
                            context,
                            '✅ Verification email resent! Check your inbox.',
                            Colors.green,
                          );
                        } catch (e) {
                          _showSnackBar(
                            context,
                            '❌ Error: ${e.toString()}',
                            Colors.red,
                          );
                        }
                      },
                      icon: const Icon(Icons.email_outlined, size: 18),
                      label: Text(
                        'Resend Email',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await FirebaseAuth.instance.currentUser?.reload();
                          final refreshedUser = FirebaseAuth.instance.currentUser;
                          if (refreshedUser != null && refreshedUser.emailVerified) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MainNavigationScreen(),
                              ),
                            );
                          } else {
                            _showSnackBar(
                              context,
                              '⚠️ Email not verified yet. Please check your inbox.',
                              Colors.orange,
                            );
                          }
                        } catch (e) {
                          _showSnackBar(
                            context,
                            '❌ Error checking verification: ${e.toString()}',
                            Colors.red,
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(
                        'Check Now',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.inter(color: AppTheme.textLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

final GlobalKey<MainNavigationScreenState> mainNavigationKey =
GlobalKey<MainNavigationScreenState>();

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const MyRoadmapsScreen(),
    const ExplorerScreen(),
    const DailyLearningScreen(),
    const LearningPathScreen(),
  ];

  void switchToTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onNavTap(int index) {
    if (index == 5) {
      // Profile - navigate to profile screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );
      return;
    }
    switchToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}