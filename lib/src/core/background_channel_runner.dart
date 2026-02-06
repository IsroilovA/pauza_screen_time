import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';

/// Runs selected platform-channel calls on a background isolate.
///
/// This is mainly useful for calls that return large payloads (e.g. lists with
/// icon byte arrays), so that platform message decoding doesn't block the UI
/// isolate.
class BackgroundChannelRunner {
  const BackgroundChannelRunner._();

  /// Invokes [method] on [channelName] from a background isolate.
  ///
  /// The returned value must be isolate-sendable (e.g. primitives, lists/maps of
  /// sendable values, and typed data like [Uint8List]).
  static Future<T?> invokeMethod<T>(
    String channelName,
    String method, {
    dynamic arguments,
  }) async {
    final token = ServicesBinding.rootIsolateToken;

    // In tests (or unusual initialization flows) the binding may not be
    // initialized. Fall back to running on the current isolate.
    if (token == null) {
      final channel = MethodChannel(channelName);
      return channel.invokeMethod<T>(method, arguments);
    }

    final responsePort = ReceivePort();

    await Isolate.spawn<Map<String, Object?>>(
      _backgroundInvokeEntry,
      <String, Object?>{
        'replyTo': responsePort.sendPort,
        'token': token,
        'channelName': channelName,
        'method': method,
        'arguments': arguments,
      },
    );

    final message = await responsePort.first;
    responsePort.close();

    if (message is! Map) {
      throw StateError(
        'Background isolate returned an unexpected message: $message',
      );
    }

    final ok = message['ok'] as bool? ?? false;
    if (ok) {
      return message['result'] as T?;
    }

    final exceptionType = message['exceptionType'] as String? ?? 'Error';
    if (exceptionType == 'PlatformException') {
      throw PlatformException(
        code: message['code'] as String? ?? 'unknown',
        message: message['message'] as String?,
        details: message['details'],
      );
    }

    final error =
        message['error'] as String? ?? 'Unknown background isolate error';
    final stack = message['stack'] as String?;
    throw StateError(stack == null ? error : '$error\n$stack');
  }
}

Future<void> _backgroundInvokeEntry(Map<String, Object?> message) async {
  final replyTo = message['replyTo'] as SendPort;
  final token = message['token'] as RootIsolateToken;
  final channelName = message['channelName'] as String;
  final method = message['method'] as String;
  final arguments = message['arguments'];

  try {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    final channel = MethodChannel(channelName);
    final result = await channel.invokeMethod<dynamic>(method, arguments);
    replyTo.send(<String, Object?>{'ok': true, 'result': result});
  } on PlatformException catch (e, st) {
    replyTo.send(<String, Object?>{
      'ok': false,
      'exceptionType': 'PlatformException',
      'code': e.code,
      'message': e.message,
      'details': e.details,
      'stack': st.toString(),
    });
  } catch (e, st) {
    replyTo.send(<String, Object?>{
      'ok': false,
      'exceptionType': 'Error',
      'error': e.toString(),
      'stack': st.toString(),
    });
  }
}
