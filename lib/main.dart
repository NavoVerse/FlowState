import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/auth_service.dart';
import 'services/db_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

/// Global variable to track Firebase initialization status
bool _isFirebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with enhanced error handling
  await _initializeFirebase();

  // Load saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme_mode') ?? 'dark';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DatabaseService()),
      ],
      child: FlowStateApp(
        initialThemeMode: savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark,
      ),
    ),
  );
}

/// Initializes Firebase with comprehensive error handling
/// Reports connection status and enables appropriate fallback mode
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    _isFirebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');
  } on FirebaseException catch (e) {
    debugPrint('❌ Firebase Exception: ${e.code}');
    debugPrint('Message: ${e.message}');
    _handleFirebaseError(e);
  } on PlatformException catch (e) {
    debugPrint('❌ Platform Exception: ${e.code}');
    debugPrint('Message: ${e.message}');
    _handlePlatformError(e);
  } catch (e) {
    debugPrint('❌ Unexpected error during Firebase initialization: $e');
    _isFirebaseInitialized = false;
  }
}

/// Handles Firebase-specific errors with detailed logging
void _handleFirebaseError(FirebaseException e) {
  switch (e.code) {
    case 'invalid-api-key':
      debugPrint('⚠️ Invalid Firebase API key. Check google-services.json (Android) or GoogleService-Info.plist (iOS)');
      break;
    case 'permission-denied':
      debugPrint('⚠️ Permission denied. Check Firestore Security Rules.');
      break;
    case 'unavailable':
      debugPrint('⚠️ Firebase service unavailable. Check network connectivity.');
      break;
    case 'unauthenticated':
      debugPrint('⚠️ User not authenticated for this operation.');
      break;
    default:
      debugPrint('⚠️ Firebase error: ${e.code}');
  }
  debugPrint('App will run in offline/mock mode');
  _isFirebaseInitialized = false;
}

/// Handles platform-specific errors (Android/iOS configuration issues)
void _handlePlatformError(PlatformException e) {
  debugPrint('⚠️ Platform-specific error encountered');
  debugPrint('Code: ${e.code}');
  debugPrint('Message: ${e.message}');
  
  if (e.code.contains('MISSING_GOOGLE_SERVICES')) {
    debugPrint('📝 Action: Ensure google-services.json is placed in android/app/');
  } else if (e.code.contains('MISSING_PLIST')) {
    debugPrint('📝 Action: Ensure GoogleService-Info.plist is added to iOS project');
  }
  
  debugPrint('App will run in offline/mock mode');
  _isFirebaseInitialized = false;
}

class FlowStateApp extends StatefulWidget {
  final ThemeMode initialThemeMode;

  const FlowStateApp({
    super.key,
    this.initialThemeMode = ThemeMode.dark,
  });

  @override
  State<FlowStateApp> createState() => _FlowStateAppState();
}

class _FlowStateAppState extends State<FlowStateApp> {
  late ThemeMode _themeMode;
  String? _firebaseStatus;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _setFirebaseStatus();
  }

  /// Set Firebase status message for debugging
  void _setFirebaseStatus() {
    setState(() {
      _firebaseStatus = _isFirebaseInitialized
          ? '🟢 Firebase Connected'
          : '🔴 Offline Mode (Mock Database)';
    });
  }

  /// Toggle theme and persist to SharedPreferences
  Future<void> _toggleTheme() async {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'theme_mode',
        _themeMode == ThemeMode.light ? 'light' : 'dark',
      );
      debugPrint('✅ Theme preference saved');
    } catch (e) {
      debugPrint('❌ Failed to save theme preference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowState',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // Calming Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4DB6AC), // Calming teal
          brightness: Brightness.light,
          primary: const Color(0xFF4DB6AC),
          secondary: const Color(0xFF3B82F6),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),

      // Minimalist Dark Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF34D399), // Emerald
          brightness: Brightness.dark,
          primary: const Color(0xFF34D399),
          secondary: const Color(0xFF3B82F6),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        useMaterial3: true,
      ),

      // Dynamic stream-based Auth Gate with Firebase status indicator
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          return StreamBuilder<FlowUser?>(
            stream: authService.userStream,
            initialData: authService.currentUser,
            builder: (context, snapshot) {
              final user = snapshot.data;

              if (user != null) {
                return _buildHomeScreen(context);
              }

              return const AuthScreen();
            },
          );
        },
      ),
    );
  }

  /// Build home screen with Firebase status badge
  Widget _buildHomeScreen(BuildContext context) {
    return Stack(
      children: [
        HomeScreen(toggleTheme: _toggleTheme),
        // Firebase status indicator (only in debug mode)
        if (!kReleaseMode)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isFirebaseInitialized
                    ? Colors.green.withValues(alpha: 0.8)
                    : Colors.orange.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _firebaseStatus ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
