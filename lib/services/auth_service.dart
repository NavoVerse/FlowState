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

  // Local mock credentials store for offline/mock database testing
  final Map<String, String> _mockCredentials = {
    'test@flowstate.com': 'Password123!',
  };

  final StreamController<FlowUser?> _userStreamController = StreamController<FlowUser?>.broadcast();

  AuthService() : _auth = _initFirebaseAuth() {
    _isFirebaseAvailable = _auth != null;
    if (_isFirebaseAvailable) {
      _auth!.authStateChanges().listen((User? firebaseUser) {
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
      });
    } else {
      // Setup default mock guest user for immediate offline testing
      debugPrint("Firebase Auth not initialized, using local mock auth");
      _initMockAuth();
    }
  }

  Future<void> _initMockAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load mock credentials from secure JSON serialization
      final savedCredsJson = prefs.getString('mock_credentials_json');
      if (savedCredsJson != null) {
        final Map<String, dynamic> map = jsonDecode(savedCredsJson);
        map.forEach((key, value) {
          _mockCredentials[key] = value.toString();
        });
      } else {
        // Fallback for older format if it exists
        final savedCreds = prefs.getStringList('mock_credentials');
        if (savedCreds != null) {
          for (final entry in savedCreds) {
            final parts = entry.split(':');
            if (parts.length == 2) {
              _mockCredentials[parts[0]] = parts[1];
            }
          }
        }
      }

      // Load active user session
      final savedUid = prefs.getString('mock_session_uid');
      final savedEmail = prefs.getString('mock_session_email');
      final savedIsAnon = prefs.getBool('mock_session_is_anon');

      if (savedUid != null && savedEmail != null && savedIsAnon != null) {
        _currentUser = FlowUser(
          uid: savedUid,
          email: savedEmail,
          isAnonymous: savedIsAnon,
        );
        _userStreamController.add(_currentUser);
        notifyListeners();
        debugPrint("Restored persistent mock user session: $savedEmail");
      }
    } catch (e) {
      debugPrint("Error initializing persistent mock auth: $e");
    }
  }

  Future<void> _saveCredentialsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_mockCredentials);
      await prefs.setString('mock_credentials_json', jsonStr);
    } catch (e) {
      debugPrint("Error saving credentials to prefs: $e");
    }
  }

  Future<void> _saveSessionToPrefs() async {
    if (_currentUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mock_session_uid', _currentUser!.uid);
      await prefs.setString('mock_session_email', _currentUser!.email);
      await prefs.setBool('mock_session_is_anon', _currentUser!.isAnonymous);
    } catch (e) {
      debugPrint("Error saving session to prefs: $e");
    }
  }

  Future<void> _clearSessionFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mock_session_uid');
      await prefs.remove('mock_session_email');
      await prefs.remove('mock_session_is_anon');
    } catch (e) {
      debugPrint("Error clearing session from prefs: $e");
    }
  }

  static FirebaseAuth? _initFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint("Firebase Auth is not configured/available. Local fallback enabled. Error: $e");
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

  // Sign In Anonymously (Guest Mode)
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
        // Mock
        await Future.delayed(const Duration(milliseconds: 500));
        _currentUser = FlowUser(
          uid: 'mock_guest_uid',
          email: 'Guest User',
          isAnonymous: true,
        );
        await _saveSessionToPrefs();
        _userStreamController.add(_currentUser);
        notifyListeners();
        return _currentUser;
      }
    } catch (e) {
      debugPrint("Error signing in anonymously: $e");
      rethrow;
    }
    return null;
  }

  // Register with Email & Password
  Future<FlowUser?> registerWithEmailAndPassword(String email, String password) async {
    try {
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
        // Mock registration persistence
        await Future.delayed(const Duration(milliseconds: 800));
        final trimmedEmail = email.trim().toLowerCase();
        if (_mockCredentials.containsKey(trimmedEmail)) {
          throw Exception("An account already exists with this email address.");
        }
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
        return _currentUser;
      }
    } catch (e) {
      debugPrint("Error registering user: $e");
      rethrow;
    }
    return null;
  }

  // Sign In with Email & Password
  Future<FlowUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
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
        // Mock login credentials validation
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
        return _currentUser;
      }
    } catch (e) {
      debugPrint("Error signing in: $e");
      rethrow;
    }
    return null;
  }

  // Sign Out
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
    } catch (e) {
      debugPrint("Error signing out: $e");
      rethrow;
    }
  }
}
