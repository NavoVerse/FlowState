import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/mood_log.dart';

class DatabaseService extends ChangeNotifier {
  final FirebaseFirestore? _db;
  bool _isFirebaseAvailable = false;

  // Local fallback memory cache for immediate testing without Firebase setup
  final List<MoodLog> _mockMoodLogs = [];

  // Stream controller for local changes
  final StreamController<List<MoodLog>> _localLogsController = StreamController<List<MoodLog>>.broadcast();

  DatabaseService() : _db = _initFirestore() {
    _isFirebaseAvailable = _db != null;
    if (!_isFirebaseAvailable) {
      debugPrint("Firebase Firestore not initialized, using local mock store");
      // Add a couple of initial mock logs to demonstrate the history chart/list beautifully!
      _mockMoodLogs.addAll([
        MoodLog(
          id: 'mock_1',
          userId: 'guest',
          score: 4.0,
          note: 'Felt very calm after doing the breathing exercises today.',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          moodType: 'Calm',
        ),
        MoodLog(
          id: 'mock_2',
          userId: 'guest',
          score: 2.0,
          note: 'A bit stressed with work deadlines. Guided audio helped.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          moodType: 'Anxious',
        ),
        MoodLog(
          id: 'mock_3',
          userId: 'guest',
          score: 5.0,
          note: 'Splendid morning! Filled with affirmations.',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          moodType: 'Happy',
        ),
      ]);
      _localLogsController.add(List.from(_mockMoodLogs));
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
      // Return local stream — initial data is already pushed in constructor
      // Only push again if the stream might have been missed (e.g. new listener)
      if (!_localLogsController.isClosed) {
        Future.microtask(() {
          if (!_localLogsController.isClosed) {
            _localLogsController.add(List.from(_mockMoodLogs));
          }
        });
      }
      return _localLogsController.stream;
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
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error deleting mood log: $e");
      rethrow;
    }
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
