import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/data/services/push/push_device.dart';
import 'package:waylight_mobile/domain/models/push.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.waylight/push');
  const device = MethodChannelPushDevice(platform: PushPlatform.fcm);
  final calls = <String>[];

  void answer(Object? Function(String method) reply) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return reply(call.method);
        });
  }

  tearDown(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('passes token, public key and forget through the channel', () async {
    answer(
      (method) => switch (method) {
        'available' => true,
        'token' => 'fcm-token',
        'publicKey' => base64Encode(List.filled(32, 1)),
        _ => null,
      },
    );

    expect(await device.available(), isTrue);
    expect(await device.token(), 'fcm-token');
    expect(await device.publicKey(), List.filled(32, 1));
    await device.forget();
    expect(calls, ['available', 'token', 'publicKey', 'forget']);
  });

  test('a platform without the channel has no push', () async {
    expect(await device.available(), isFalse);
  });
}
