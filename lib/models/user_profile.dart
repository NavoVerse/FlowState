import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isAnonymous;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isAnonymous,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isAnonymous': isAnonymous,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime created;
    if (map['createdAt'] is Timestamp) {
      created = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      created = DateTime.parse(map['createdAt']);
    } else {
      created = DateTime.now();
    }

    DateTime lastLogin;
    if (map['lastLoginAt'] is Timestamp) {
      lastLogin = (map['lastLoginAt'] as Timestamp).toDate();
    } else if (map['lastLoginAt'] is String) {
      lastLogin = DateTime.parse(map['lastLoginAt']);
    } else {
      lastLogin = DateTime.now();
    }

    return UserProfile(
      uid: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      createdAt: created,
      lastLoginAt: lastLogin,
      isAnonymous: map['isAnonymous'] ?? false,
    );
  }
}
