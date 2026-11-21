import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Encrypts the handover for a watch with the key of its QR code (#239,
/// ADR 0015): AES-256-GCM, a random 12-byte nonce in front, additional
/// data `waylight-watch-pair-v1`.
abstract interface class HandoverSealer {
  /// The nonce, ciphertext and tag; `null` where the platform cannot seal.
  Future<Uint8List?> seal(Uint8List key, Uint8List plaintext);
}

/// A [HandoverSealer] over the channel `app.waylight/watch`, which uses
/// the platform's AES-GCM.
final class MethodChannelHandoverSealer implements HandoverSealer {
  /// Creates the adapter.
  const MethodChannelHandoverSealer({
    this._channel = const MethodChannel('app.waylight/watch'),
  });

  final MethodChannel _channel;

  @override
  Future<Uint8List?> seal(Uint8List key, Uint8List plaintext) async {
    try {
      return await _channel.invokeMethod<Uint8List>('seal', {
        'key': key,
        'plaintext': plaintext,
      });
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

/// Sends the sealed handover to the watch's listener in the local network.
class WatchClient {
  /// Creates the client on top of [_client].
  WatchClient(this._client, {this.timeout = const Duration(seconds: 30)});

  final http.Client _client;
  final Logger _log = Logger('WatchClient');

  /// How long to wait for the watch. It redeems the code with the server
  /// before it answers, so this is longer than a plain request.
  final Duration timeout;

  /// Sends `POST http://<address>/pair` with [body] and returns the
  /// watch's status, or `null` when the watch did not answer.
  Future<int?> pair(String address, String body) async {
    try {
      final response = await _client
          .post(
            Uri.parse('http://$address/pair'),
            headers: {HttpHeaders.contentTypeHeader: 'text/plain'},
            body: body,
          )
          .timeout(timeout);
      return response.statusCode;
    } on TimeoutException {
      _log.info('Watch did not answer in time');
    } on http.ClientException catch (e) {
      _log.info('Watch unreachable', e);
    } on SocketException catch (e) {
      _log.info('Watch unreachable', e);
    }
    return null;
  }
}
