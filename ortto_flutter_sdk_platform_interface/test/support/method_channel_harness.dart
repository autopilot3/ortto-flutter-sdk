import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class MethodChannelHarness {
  MethodChannelHarness(this.channel);

  final MethodChannel channel;
  final List<MethodCall> calls = <MethodCall>[];

  MethodCall get singleCall => calls.single;

  void respondWith(Object? response) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return response;
    });
  }

  void respond(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }

  static Future<T> expectCompletes<T>(
    Future<T> future, {
    Duration timeout = const Duration(milliseconds: 100),
  }) {
    return future.timeout(timeout);
  }
}
