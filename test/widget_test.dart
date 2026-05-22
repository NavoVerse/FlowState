import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flow_state/main.dart';
import 'package:flow_state/services/auth_service.dart';
import 'package:flow_state/services/db_service.dart';

void main() {
  testWidgets('FlowState App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => DatabaseService()),
        ],
        child: const FlowStateApp(),
      ),
    );

    // Verify that the title FlowState is present in the AuthScreen
    expect(find.text('FlowState'), findsOneWidget);
  });
}
