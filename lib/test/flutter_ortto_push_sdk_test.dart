import 'package:ortto_flutter_sdk/flutter_ortto_sdk.dart';
import 'package:ortto_flutter_platform_interface/ortto_flutter_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterOrttoPushSdkPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FlutterOrttoPushSdkPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterOrttoPushSdk', () {
    late FlutterOrttoPushSdkPlatform flutterOrttoPushSdkPlatform;

    setUp(() {
      flutterOrttoPushSdkPlatform = MockFlutterOrttoPushSdkPlatform();
      FlutterOrttoPushSdkPlatform.instance = flutterOrttoPushSdkPlatform;
    });

    group('getPlatformName', () {
      test('returns correct name when platform implementation exists',
          () async {
        const platformName = '__test_platform__';
        when(
          () => flutterOrttoPushSdkPlatform.getPlatformName(),
        ).thenAnswer((_) async => platformName);

        final actualPlatformName = await getPlatformName();
        expect(actualPlatformName, equals(platformName));
      });

      test('throws exception when platform implementation is missing',
          () async {
        when(
          () => flutterOrttoPushSdkPlatform.getPlatformName(),
        ).thenAnswer((_) async => null);

        expect(getPlatformName, throwsException);
      });
    });
  });
}
