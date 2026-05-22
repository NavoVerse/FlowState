import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_state/services/db_service.dart';

void main() {
  group('DatabaseService User Isolation Test', () {
    late DatabaseService dbService;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      dbService = DatabaseService();
      // Allow asynchronous _initMockDatabase loading to complete
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('1. Guest user should only see guest mock logs', () async {
      final logsStream = dbService.getMoodLogs('mock_guest_uid');
      final logs = await logsStream.first;
      
      expect(logs.isNotEmpty, isTrue);
      for (final log in logs) {
        expect(log.userId, equals('mock_guest_uid'));
      }
    });

    test('2. Registered test user should only see their own mock logs', () async {
      final testUid = 'mock_user_${'test@flowstate.com'.hashCode}';
      final logsStream = dbService.getMoodLogs(testUid);
      final logs = await logsStream.first;

      expect(logs.isNotEmpty, isTrue);
      for (final log in logs) {
        expect(log.userId, equals(testUid));
      }
    });

    test('3. Dynamic log creation should only appear in the creator user\'s feed', () async {
      final userA = 'user_a';
      final userB = 'user_b';

      // Verify user A has no logs initially
      var logsA = await dbService.getMoodLogs(userA).first;
      expect(logsA.isEmpty, isTrue);

      // Verify user B has no logs initially
      var logsB = await dbService.getMoodLogs(userB).first;
      expect(logsB.isEmpty, isTrue);

      // User A adds a mood log
      await dbService.addMoodLog(userA, 4.5, 'Feeling fantastic', 'Happy');

      // Verify user A now has 1 log
      logsA = await dbService.getMoodLogs(userA).first;
      expect(logsA.length, equals(1));
      expect(logsA[0].note, equals('Feeling fantastic'));
      expect(logsA[0].userId, equals(userA));

      // Verify user B still has 0 logs (no cross-contamination)
      logsB = await dbService.getMoodLogs(userB).first;
      expect(logsB.isEmpty, isTrue);
    });
  });
}
