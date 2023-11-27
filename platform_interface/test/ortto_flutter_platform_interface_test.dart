import 'package:ortto_flutter_platform_interface/ortto_flutter_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class FlutterOrttoPushSdkMock extends FlutterOrttoPushSdkPlatform {
  static const mockPlatformName = 'Mock';

  @override
  Future<String?> getPlatformName() async => mockPlatformName;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('FlutterOrttoPushSdkPlatformInterface', () {
    late FlutterOrttoPushSdkPlatform flutterOrttoPushSdkPlatform;

    setUp(() {
      flutterOrttoPushSdkPlatform = FlutterOrttoPushSdkMock();
      FlutterOrttoPushSdkPlatform.instance = flutterOrttoPushSdkPlatform;
    });

    group('getPlatformName', () {
      test('returns correct name', () async {
        expect(
          await FlutterOrttoPushSdkPlatform.instance.getPlatformName(),
          equals(FlutterOrttoPushSdkMock.mockPlatformName),
        );
      });
    });
  });
}
