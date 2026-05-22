import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood_log.dart';
import '../models/user_profile.dart';

class DatabaseService extends ChangeNotifier {
  final FirebaseFirestore? _db;
  bool _isFirebaseAvailable = false;

  // Local fallback memory cache for immediate testing without Firebase setup
  final List<MoodLog> _mockMoodLogs = [];
  final Map<String, UserProfile> _mockUserProfiles = {};

  // Stream controller for local changes
  final StreamController<List<MoodLog>> _localLogsController = StreamController<List<MoodLog>>.broadcast();

  DatabaseService() : _db = _initFirestore() {
    _isFirebaseAvailable = _db != null;
    if (!_isFirebaseAvailable) {
      debugPrint("Firebase Firestore not initialized, using local mock store");
      _initMockDatabase();
    }
  }

  Future<void> _initMockDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user profiles first
      final savedProfiles = prefs.getStringList('mock_user_profiles');
      if (savedProfiles != null) {
        _mockUserProfiles.clear();
        for (final jsonStr in savedProfiles) {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          final tsStr = map['createdAt'] as String;
          final loginStr = map['lastLoginAt'] as String;
          final profile = UserProfile(
            uid: map['uid'] ?? '',
            email: map['email'] ?? '',
            displayName: map['displayName'] ?? '',
            createdAt: DateTime.parse(tsStr),
            lastLoginAt: DateTime.parse(loginStr),
            isAnonymous: map['isAnonymous'] ?? false,
          );
          _mockUserProfiles[profile.uid] = profile;
        }
      }

      // Load mood logs
      final savedLogs = prefs.getStringList('mock_mood_logs');
      if (savedLogs != null) {
        _mockMoodLogs.clear();
        for (final jsonStr in savedLogs) {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          final tsStr = map['timestamp'] as String;
          final log = MoodLog(
            id: map['id'] ?? '',
            userId: map['userId'] ?? '',
            score: (map['score'] as num?)?.toDouble() ?? 3.0,
            note: map['note'] ?? '',
            timestamp: DateTime.parse(tsStr),
            moodType: map['moodType'] ?? 'Calm',
          );
          _mockMoodLogs.add(log);
        }
      } else {
        // First run fallback: Add default mock logs
        _mockMoodLogs.addAll([
          MoodLog(
            id: 'mock_1',
            userId: 'mock_guest_uid',
            score: 4.0,
            note: 'Felt very calm after doing the breathing exercises today.',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            moodType: 'Calm',
          ),
          MoodLog(
            id: 'mock_2',
            userId: 'mock_guest_uid',
            score: 2.0,
            note: 'A bit stressed with work deadlines. Guided audio helped.',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            moodType: 'Anxious',
          ),
          MoodLog(
            id: 'mock_3',
            userId: 'mock_guest_uid',
            score: 5.0,
            note: 'Splendid morning! Filled with affirmations.',
            timestamp: DateTime.now().subtract(const Duration(hours: 4)),
            moodType: 'Happy',
          ),
          MoodLog(
            id: 'mock_test_1',
            userId: 'mock_user_${'test@flowstate.com'.hashCode}',
            score: 5.0,
            note: 'Welcome to your private FlowState space! Your data is completely secured.',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            moodType: 'Calm',
          ),
        ]);
        await _saveMoodLogsToPrefs();
      }

      _localLogsController.add(List.from(_mockMoodLogs));
      notifyListeners();
      debugPrint("Restored persistent mock database contents.");
    } catch (e) {
      debugPrint("Error initializing persistent mock database: $e");
    }
  }

  Future<void> _saveMoodLogsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _mockMoodLogs.map((log) {
        return jsonEncode({
          'id': log.id,
          'userId': log.userId,
          'score': log.score,
          'note': log.note,
          'timestamp': log.timestamp.toIso8601String(),
          'moodType': log.moodType,
        });
      }).toList();
      await prefs.setStringList('mock_mood_logs', list);
    } catch (e) {
      debugPrint("Error saving mood logs to prefs: $e");
    }
  }

  Future<void> _saveUserProfilesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _mockUserProfiles.values.map((profile) {
        return jsonEncode({
          'uid': profile.uid,
          'email': profile.email,
          'displayName': profile.displayName,
          'createdAt': profile.createdAt.toIso8601String(),
          'lastLoginAt': profile.lastLoginAt.toIso8601String(),
          'isAnonymous': profile.isAnonymous,
        });
      }).toList();
      await prefs.setStringList('mock_user_profiles', list);
    } catch (e) {
      debugPrint("Error saving user profiles to prefs: $e");
    }
  }

  static FirebaseFirestore? _initFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint("Firebase Firestore is not configured/available. Local fallback enabled. Error: $e");
      return null;
    }
  }

  bool get isFirebaseAvailable => _isFirebaseAvailable;

  @override
  void dispose() {
    _localLogsController.close();
    super.dispose();
  }

  // Stream of Mood Logs for a specific user
  Stream<List<MoodLog>> getMoodLogs(String userId) {
    if (_isFirebaseAvailable) {
      return _db!
          .collection('mood_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MoodLog.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } else {
      // Create a dedicated single-subscription controller for this user.
      // It yields the current logs synchronously upon listening, then forwards
      // filtered updates from the main broadcast stream.
      late StreamController<List<MoodLog>> controller;
      StreamSubscription<List<MoodLog>>? subscription;

      controller = StreamController<List<MoodLog>>(
        onListen: () {
          // Emit the current list of logs for this user immediately
          controller.add(_mockMoodLogs.where((log) => log.userId == userId).toList());
          
          // Listen for future additions/deletions and filter them
          subscription = _localLogsController.stream.listen(
            (logs) {
              if (!controller.isClosed) {
                controller.add(logs.where((log) => log.userId == userId).toList());
              }
            },
            onError: controller.addError,
            onDone: controller.close,
          );
        },
        onCancel: () {
          subscription?.cancel();
          controller.close();
        },
      );

      return controller.stream;
    }
  }

  // Add Mood Log
  Future<void> addMoodLog(String userId, double score, String note, String moodType) async {
    final newLog = MoodLog(
      id: _isFirebaseAvailable ? '' : 'mock_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      score: score,
      note: note,
      timestamp: DateTime.now(),
      moodType: moodType,
    );

    try {
      if (_isFirebaseAvailable) {
        await _db!.collection('mood_logs').add(newLog.toMap());
      } else {
        // Mock add
        await Future.delayed(const Duration(milliseconds: 300));
        _mockMoodLogs.insert(0, newLog);
        _localLogsController.add(List.from(_mockMoodLogs));
        await _saveMoodLogsToPrefs();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error adding mood log: $e");
      rethrow;
    }
  }

  // Delete Mood Log
  Future<void> deleteMoodLog(String logId) async {
    try {
      if (_isFirebaseAvailable) {
        await _db!.collection('mood_logs').doc(logId).delete();
      } else {
        await Future.delayed(const Duration(milliseconds: 200));
        _mockMoodLogs.removeWhere((log) => log.id == logId);
        _localLogsController.add(List.from(_mockMoodLogs));
        await _saveMoodLogsToPrefs();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error deleting mood log: $e");
      rethrow;
    }
  }

  // Save User Profile to Database
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      if (_isFirebaseAvailable) {
        await _db!.collection('users').doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
      } else {
        // Mock save
        await Future.delayed(const Duration(milliseconds: 200));
        _mockUserProfiles[profile.uid] = profile;
        await _saveUserProfilesToPrefs();
        debugPrint("Successfully saved mock user profile for: ${profile.email}");
      }
    } catch (e) {
      debugPrint("Error saving user profile: $e");
      rethrow;
    }
  }

  // Retrieve User Profile from Database
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      if (_isFirebaseAvailable) {
        final doc = await _db!.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return UserProfile.fromMap(doc.data()!, doc.id);
        }
      } else {
        // Mock get
        await Future.delayed(const Duration(milliseconds: 150));
        return _mockUserProfiles[uid];
      }
    } catch (e) {
      debugPrint("Error getting user profile: $e");
      rethrow;
    }
    return null;
  }

  // Static Calm Daily Quotes / Affirmations
  List<String> getAffirmations() {
    return [
      "Breathing in, I calm my body. Breathing out, I smile.",
      "You do not have to control your thoughts. You just have to stop letting them control you.",
      "This stress is only temporary. I am capable, strong, and centered.",
      "With every breath, I release anxiety and invite peace into my heart.",
      "Slow down. You are doing just fine. Trust the journey.",
      "I am grounded, safe, and supported in this present moment.",
      "Peace begins with a single conscious breath.",
      "I am allowed to rest, recharge, and take care of my well-being.",
      "My mind is clear, my heart is calm, and my soul is at peace."
    ];
  }
}
