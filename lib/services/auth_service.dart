import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
        // Mock
        await Future.delayed(const Duration(milliseconds: 800));
        _currentUser = FlowUser(
          uid: 'mock_user_${email.hashCode}',
          email: email.trim(),
          isAnonymous: false,
        );
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
        // Mock validation
        await Future.delayed(const Duration(milliseconds: 800));
        if (password.length < 6) {
          throw Exception("Password must be at least 6 characters.");
        }
        _currentUser = FlowUser(
          uid: 'mock_user_${email.hashCode}',
          email: email.trim(),
          isAnonymous: false,
        );
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
