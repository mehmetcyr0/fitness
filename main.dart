import 'dart:io';
import 'dart:developer' as developer;

import 'package:fitness/pages/app_theme.dart';
import 'package:fitness/pages/settings_page.dart';
import 'package:fitness/pages/theme_provider.dart';
import 'package:fitness/pages/workouts_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/register_page.dart';
import 'pages/profile_page.dart';
import 'pages/weight_input_page.dart';
import 'pages/nfc_entry_page.dart';
import 'pages/exercise_page.dart';
import 'pages/create_workout_page.dart'; // Added import
import 'models/auth_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMinSize(const Size(530, 944));
    setWindowMaxSize(const Size(1060, 1888));
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Fitness Uygulaması',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/home': (context) => const HomePage(),
            '/Antrenmanlar': (context) => const WorkoutPage(),
            '/profile': (context) => const ProfilePage(),
            '/weight-input': (context) => const WeightInputPage(),
            '/nfc-entry': (context) => const NFCEntryPage(),
            '/settings': (context) => const SettingsPage(),
            '/exercises': (context) => const ExercisesPage(), // Added route
            '/create-workout': (context) =>
                const CreateWorkoutPage(), // Added route
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App resumed, check login status again
      developer.log('App resumed, checking login status', name: 'AuthWrapper');
      _checkLoginStatus();
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      developer.log('Checking login status...', name: 'AuthWrapper');

      // Add debug info
      await AuthHelper.debugPrintStoredData();

      final isLoggedIn = await AuthHelper.isLoggedIn();
      developer.log('Login status result: $isLoggedIn', name: 'AuthWrapper');

      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error checking login status: $e', name: 'AuthWrapper');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Yükleniyor...'),
            ],
          ),
        ),
      );
    }

    developer.log(
      'AuthWrapper build - isLoggedIn: $_isLoggedIn',
      name: 'AuthWrapper',
    );
    return _isLoggedIn ? const HomePage() : const LoginPage();
  }
}
