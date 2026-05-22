import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/auth_service.dart';
import 'services/db_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try initializing Firebase, but catch errors to allow running the app in Mock mode instantly
  try {
    await Firebase.initializeApp();
    debugPrint("Firebase initialized successfully.");
  } catch (e) {
    debugPrint("Firebase failed to initialize or not configured. Running in offline mock mode. Error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DatabaseService()),
      ],
      child: const FlowStateApp(),
    ),
  );
}

class FlowStateApp extends StatefulWidget {
  const FlowStateApp({super.key});

  @override
  State<FlowStateApp> createState() => _FlowStateAppState();
}

class _FlowStateAppState extends State<FlowStateApp> {
  ThemeMode _themeMode = ThemeMode.dark; // Default to the calming Dark Mode!

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
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

      // Dynamic stream based Auth Gate
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          return StreamBuilder<FlowUser?>(
            stream: authService.userStream,
            initialData: authService.currentUser,
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user != null) {
                return HomeScreen(toggleTheme: _toggleTheme);
              }
              return const AuthScreen();
            },
          );
        },
      ),
    );
  }
}
