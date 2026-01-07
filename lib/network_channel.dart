import 'dart:async';
import 'package:flutter/services.dart';

enum NetStatus { connected, disconnected }

class NetworkChannel {
  static const EventChannel _event = EventChannel('app.network/events');
  static const MethodChannel _method = MethodChannel('app.network/methods');

  static Stream<NetStatus>? _cachedStream;

  static Stream<NetStatus> changes() {
    _cachedStream ??= _event.receiveBroadcastStream().map((dynamic value) {
      final v = (value ?? '').toString();
      return v == 'connected' ? NetStatus.connected : NetStatus.disconnected;
    }).distinct();
    return _cachedStream!;
  }

  static Future<NetStatus> current() async {
    final res = await _method.invokeMethod<String>('getCurrentStatus');
    return res == 'connected' ? NetStatus.connected : NetStatus.disconnected;
  }
}
