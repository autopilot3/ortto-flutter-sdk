import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ortto_flutter_sdk_example/main.dart' as app;

const _runPushoverE2E = bool.fromEnvironment('PUSHOVER_E2E');
const _pushoverEmail = String.fromEnvironment('PUSHOVER_E2E_EMAIL');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches the current push demo', (tester) async {
    app.main();
    await _pumpFor(tester, const Duration(seconds: 3));

    expect(find.byType(Scaffold), findsWidgets);
    expect(
      find.text('Sign in').evaluate().isNotEmpty ||
          find.text('Home').evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets(
    'registers a real FCM token with the local Pushover backend',
    (tester) async {
      expect(_pushoverEmail, isNotEmpty,
          reason: 'Set PUSHOVER_E2E_EMAIL for the opt-in live test.');

      app.main();
      await _pumpFor(tester, const Duration(seconds: 3));

      final signOut = find.byTooltip('Sign out');
      if (signOut.evaluate().isNotEmpty) {
        await tester.tap(signOut);
        await _pumpFor(tester, const Duration(seconds: 3));
      }

      final anotherAccount = find.text('Sign in with another account');
      if (anotherAccount.evaluate().isNotEmpty) {
        await tester.tap(anotherAccount);
        await _pumpFor(tester, const Duration(milliseconds: 500));
      }

      await tester.enterText(find.byType(TextField).first, _pushoverEmail);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await _pumpFor(tester, const Duration(seconds: 2));
      expect(find.byKey(const ValueKey('main')), findsOneWidget);

      for (var attempt = 0; attempt < 45; attempt += 1) {
        if (find.text('Registered').evaluate().isNotEmpty &&
            find.text('Forwarded').evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('Forwarded'), findsOneWidget);
    },
    skip: !_runPushoverE2E,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final ticks = duration.inMilliseconds ~/ 100;
  for (var tick = 0; tick < ticks; tick += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
