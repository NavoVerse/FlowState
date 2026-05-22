import 'package:cloud_firestore/cloud_firestore.dart';

class MoodLog {
  final String id;
  final String userId;
  final double score; // 1.0 (very low) to 5.0 (very high)
  final String note;
  final DateTime timestamp;
  final String moodType; // e.g. "Anxious", "Calm", "Sad", "Neutral", "Happy"

  MoodLog({
    required this.id,
    required this.userId,
    required this.score,
    required this.note,
    required this.timestamp,
    required this.moodType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'score': score,
      'note': note,
      'timestamp': Timestamp.fromDate(timestamp),
      'moodType': moodType,
    };
  }

  factory MoodLog.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime ts;
    if (map['timestamp'] is Timestamp) {
      ts = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      ts = DateTime.parse(map['timestamp']);
    } else {
      ts = DateTime.now();
    }

    return MoodLog(
      id: documentId,
      userId: map['userId'] ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 3.0,
      note: map['note'] ?? '',
      timestamp: ts,
      moodType: map['moodType'] ?? 'Calm',
    );
  }

  // Helper to get corresponding emoji
  String get emoji {
    switch (moodType.toLowerCase()) {
      case 'sad':
        return '🌧️';
      case 'anxious':
        return '🌀';
      case 'neutral':
        return '🍃';
      case 'calm':
        return '🧘';
      case 'happy':
        return '☀️';
      default:
        return '✨';
    }
  }

  // Helper to get color hex
  int get colorHex {
    switch (moodType.toLowerCase()) {
      case 'sad':
        return 0xFF5C78FF; // Gentle slate blue
      case 'anxious':
        return 0xFF9E7CFF; // Soft purple
      case 'neutral':
        return 0xFF8FA382; // Sage green
      case 'calm':
        return 0xFF4DB6AC; // Calming teal
      case 'happy':
        return 0xFFFFB74D; // Warm amber
      default:
        return 0xFFE0E0E0;
    }
  }
}
