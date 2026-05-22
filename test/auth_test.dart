import 'package:flutter_test/flutter_test.dart';
import 'package:flow_state/services/auth_service.dart';

void main() {
  group('AuthService Secure Credentials Verification Test', () {
    late AuthService authService;

    setUp(() {
      // Initialize a clean AuthService instance
      authService = AuthService();
    });

    test('1. Unregistered mock sign-in should fail with "No account found" exception', () async {
      expect(
        () => authService.signInWithEmailAndPassword('unknown@test.com', 'Password123!'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('No account found with this email. Please sign up first.'),
        )),
      );
    });

    test('2. Correct pre-populated credentials sign-in should succeed', () async {
      final user = await authService.signInWithEmailAndPassword('test@flowstate.com', 'Password123!');
      expect(user, isNotNull);
      expect(user!.email, equals('test@flowstate.com'));
      expect(user.isAnonymous, isFalse);
    });

    test('3. Pre-populated credentials sign-in with incorrect password should fail', () async {
      expect(
        () => authService.signInWithEmailAndPassword('test@flowstate.com', 'WrongPassword'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Incorrect password. Please try again.'),
        )),
      );
    });

    test('4. Registering a new account and then logging in should succeed', () async {
      const email = 'newuser@flowstate.com';
      const password = 'SecurePassword456!';

      // Register the new user
      final registeredUser = await authService.registerWithEmailAndPassword(email, password);
      expect(registeredUser, isNotNull);
      expect(registeredUser!.email, equals(email));

      // Sign in with the registered credentials
      final loggedInUser = await authService.signInWithEmailAndPassword(email, password);
      expect(loggedInUser, isNotNull);
      expect(loggedInUser!.email, equals(email));
    });

    test('5. Registering a duplicate email address should fail', () async {
      const email = 'duplicate@flowstate.com';
      const password = 'SecurePassword456!';

      // First registration succeeds
      await authService.registerWithEmailAndPassword(email, password);

      // Second registration fails
      expect(
        () => authService.registerWithEmailAndPassword(email, 'AnotherPassword789!'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('An account already exists with this email address.'),
        )),
      );
    });
  });
}
