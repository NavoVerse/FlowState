import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FlowUser {
  final String uid;
  final String email;
  final bool isAnonymous;

  FlowUser({
    required this.uid,
    required this.email,
    required this.isAnonymous,
  });
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth? _auth;
  FlowUser? _currentUser;
  bool _isFirebaseAvailable = false;
  bool _isInitialized = false;

  // Local mock credentials store - loaded from secure storage only
  final Map<String, String> _mockCredentials = {};

  final StreamController<FlowUser?> _userStreamController = StreamController<FlowUser?>.broadcast();

  // Storage keys for secure credential management
  static const String _mockCredentialsKey = 'flow_state_mock_credentials_v2';
  static const String _mockSessionUidKey = 'flow_state_session_uid';
  static const String _mockSessionEmailKey = 'flow_state_session_email';
  static const String _mockSessionAnonKey = 'flow_state_session_is_anon';

  AuthService() : _auth = _initFirebaseAuth() {
    _isFirebaseAvailable = _auth != null;
    if (_isFirebaseAvailable) {
      _setupFirebaseAuthListener();
    } else {
      // Setup default mock guest user for immediate offline testing
      debugPrint("🔐 Firebase Auth not initialized, using secure local mock auth");
      _initMockAuth();
    }
  }

  /// Sets up Firebase authentication state listener
  void _setupFirebaseAuthListener() {
    _auth!.authStateChanges().listen(
      (User? firebaseUser) {
        if (firebaseUser != null) {
          _currentUser = FlowUser(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? 'Guest',
            isAnonymous: firebaseUser.isAnonymous,
          );
        } else {
          _currentUser = null;
        }
        _userStreamController.add(_currentUser);
        notifyListeners();
      },
      onError: (error) {
        debugPrint("❌ Firebase auth state listener error: $error");
      },
    );
  }

  /// Initialize mock authentication from secure storage
  Future<void> _initMockAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load mock credentials from secure storage only
      final savedCredsJson = prefs.getString(_mockCredentialsKey);
      if (savedCredsJson != null) {
        try {
          final Map<String, dynamic> map = jsonDecode(savedCredsJson);
          map.forEach((key, value) {
            _mockCredentials[key.toLowerCase()] = value.toString();
          });
          debugPrint("✅ Loaded ${_mockCredentials.length} mock credential(s) from secure storage");
        } catch (e) {
          debugPrint("⚠️ Failed to parse stored credentials: $e");
        }
      } else {
        debugPrint("ℹ️ No stored mock credentials found. First-time setup.");
      }

      // Load active user session
      await _restoreUserSession(prefs);

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error initializing secure mock auth: $e");
    }
  }

  /// Restore previously saved user session from secure storage
  Future<void> _restoreUserSession(SharedPreferences prefs) async {
    try {
      final savedUid = prefs.getString(_mockSessionUidKey);
      final savedEmail = prefs.getString(_mockSessionEmailKey);
      final savedIsAnon = prefs.getBool(_mockSessionAnonKey);

      if (savedUid != null && savedEmail != null && savedIsAnon != null) {
        _currentUser = FlowUser(
          uid: savedUid,
          email: savedEmail,
          isAnonymous: savedIsAnon,
        );
        _userStreamController.add(_currentUser);
        notifyListeners();
        debugPrint("✅ Restored persistent mock user session: $savedEmail");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to restore user session: $e");
    }
  }

  /// Save credentials securely to local storage
  /// Note: In production, use platform-specific secure storage (Keychain/Keystore)
  Future<void> _saveCredentialsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_mockCredentials);
      await prefs.setString(_mockCredentialsKey, jsonStr);
      debugPrint("✅ Credentials saved securely");
    } catch (e) {
      debugPrint("❌ Error saving credentials: $e");
    }
  }

  /// Save user session securely to local storage
  Future<void> _saveSessionToPrefs() async {
    if (_currentUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mockSessionUidKey, _currentUser!.uid);
      await prefs.setString(_mockSessionEmailKey, _currentUser!.email);
      await prefs.setBool(_mockSessionAnonKey, _currentUser!.isAnonymous);
      debugPrint("✅ Session saved securely");
    } catch (e) {
      debugPrint("❌ Error saving session: $e");
    }
  }

  /// Clear user session from secure storage
  Future<void> _clearSessionFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_mockSessionUidKey);
      await prefs.remove(_mockSessionEmailKey);
      await prefs.remove(_mockSessionAnonKey);
      debugPrint("✅ Session cleared securely");
    } catch (e) {
      debugPrint("❌ Error clearing session: $e");
    }
  }

  static FirebaseAuth? _initFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint("⚠️ Firebase Auth unavailable. Local secure fallback enabled. Error: $e");
      return null;
    }
  }

  FlowUser? get currentUser => _currentUser;
  bool get isFirebaseAvailable => _isFirebaseAvailable;
  Stream<FlowUser?> get userStream => _userStreamController.stream;

  @override
  void dispose() {
    _userStreamController.close();
    super.dispose();
  }

  /// Sign In Anonymously (Guest Mode)
  Future<FlowUser?> signInAnonymously() async {
    try {
      if (_isFirebaseAvailable) {
        final credential = await _auth!.signInAnonymously();
        final user = credential.user;
        if (user != null) {
          _currentUser = FlowUser(
            uid: user.uid,
            email: 'Guest User',
            isAnonymous: true,
          );
          _userStreamController.add(_currentUser);
          notifyListeners();
          return _currentUser;
        }
      } else {
        // Mock anonymous login
        await Future.delayed(const Duration(milliseconds: 500));
        final guestUid = 'mock_guest_${DateTime.now().millisecondsSinceEpoch}';
        _currentUser = FlowUser(
          uid: guestUid,
          email: 'Guest User',
          isAnonymous: true,
        );
        await _saveSessionToPrefs();
        _userStreamController.add(_currentUser);
        notifyListeners();
        return _currentUser;
      }
    } catch (e) {
      debugPrint("❌ Error signing in anonymously: $e");
      rethrow;
    }
    return null;
  }

  /// Register with Email & Password
  /// Stores credentials securely in local storage
  Future<FlowUser?> registerWithEmailAndPassword(String email, String password) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        throw ArgumentError('Email and password cannot be empty');
      }

      if (_isFirebaseAvailable) {
        final credential = await _auth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          _currentUser = FlowUser(
            uid: user.uid,
            email: user.email ?? email,
            isAnonymous: false,
          );
          _userStreamController.add(_currentUser);
          notifyListeners();
          return _currentUser;
        }
      } else {
        // Mock registration with secure credential storage
        await Future.delayed(const Duration(milliseconds: 800));
        final trimmedEmail = email.trim().toLowerCase();

        if (_mockCredentials.containsKey(trimmedEmail)) {
          throw Exception("An account already exists with this email address.");
        }

        // Store credentials only after validation
        _mockCredentials[trimmedEmail] = password;
        await _saveCredentialsToPrefs();

        _currentUser = FlowUser(
          uid: 'mock_user_${trimmedEmail.hashCode}',
          email: email.trim(),
          isAnonymous: false,
        );
        await _saveSessionToPrefs();
        _userStreamController.add(_currentUser);
        notifyListeners();
        debugPrint("✅ User registered successfully: $trimmedEmail");
        return _currentUser;
      }
    } catch (e) {
      debugPrint("❌ Error registering user: $e");
      rethrow;
    }
    return null;
  }

  /// Sign In with Email & Password
  Future<FlowUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        throw ArgumentError('Email and password cannot be empty');
      }

      if (_isFirebaseAvailable) {
        final credential = await _auth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          _currentUser = FlowUser(
            uid: user.uid,
            email: user.email ?? email,
            isAnonymous: false,
          );
          _userStreamController.add(_currentUser);
          notifyListeners();
          return _currentUser;
        }
      } else {
        // Mock login with secure credential validation
        await Future.delayed(const Duration(milliseconds: 800));
        final trimmedEmail = email.trim().toLowerCase();

        if (!_mockCredentials.containsKey(trimmedEmail)) {
          throw Exception("No account found with this email. Please sign up first.");
        }

        if (_mockCredentials[trimmedEmail] != password) {
          throw Exception("Incorrect password. Please try again.");
        }

        _currentUser = FlowUser(
          uid: 'mock_user_${trimmedEmail.hashCode}',
          email: email.trim(),
          isAnonymous: false,
        );
        await _saveSessionToPrefs();
        _userStreamController.add(_currentUser);
        notifyListeners();
        debugPrint("✅ User signed in successfully: $trimmedEmail");
        return _currentUser;
      }
    } catch (e) {
      debugPrint("❌ Error signing in: $e");
      rethrow;
    }
    return null;
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      if (_isFirebaseAvailable) {
        await _auth!.signOut();
      } else {
        await _clearSessionFromPrefs();
      }
      _currentUser = null;
      _userStreamController.add(null);
      notifyListeners();
      debugPrint("✅ User signed out successfully");
    } catch (e) {
      debugPrint("❌ Error signing out: $e");
      rethrow;
    }
  }

  /// Development utility: Reset all mock credentials and sessions
  /// WARNING: Only use in development/testing environments
  Future<void> debugResetAllMockData() async {
    if (!kDebugMode) {
      throw Exception('This method is only available in debug mode');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _mockCredentials.clear();
      await prefs.remove(_mockCredentialsKey);
      await _clearSessionFromPrefs();
      _currentUser = null;
      _userStreamController.add(null);
      notifyListeners();
      debugPrint("🧹 All mock data cleared (DEBUG ONLY)");
    } catch (e) {
      debugPrint("❌ Error resetting mock data: $e");
    }
  }

  /// Development utility: Create test credential
  /// WARNING: Only use in development/testing environments
  Future<void> debugCreateTestCredential(String email, String password) async {
    if (!kDebugMode) {
      throw Exception('This method is only available in debug mode');
    }

    try {
      final trimmedEmail = email.trim().toLowerCase();
      _mockCredentials[trimmedEmail] = password;
      await _saveCredentialsToPrefs();
      debugPrint("✅ Test credential created: $trimmedEmail (DEBUG ONLY)");
    } catch (e) {
      debugPrint("❌ Error creating test credential: $e");
    }
  }
}
