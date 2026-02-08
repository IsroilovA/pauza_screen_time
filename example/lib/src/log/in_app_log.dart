import 'package:flutter/foundation.dart';

/// A single log entry in the in-app log.
class LogEntry {
  final DateTime at;
  final String level; // 'info', 'warn', 'error'
  final String tag; // e.g. 'permissions', 'apps', 'usage', 'restrict'
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.at,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final timeStr =
        '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}:'
        '${at.second.toString().padLeft(2, '0')}';
    final levelStr = level.toUpperCase().padRight(5);
    final tagStr = tag.padRight(12);
    final errorStr = error != null ? '\n  Error: $error' : '';
    final stackStr = stackTrace != null ? '\n  Stack: $stackTrace' : '';
    return '[$timeStr] $levelStr [$tagStr] $message$errorStr$stackStr';
  }
}

/// Controller for managing in-app log entries.
class InAppLogController extends ValueNotifier<List<LogEntry>> {
  static const int _maxEntries = 300;

  InAppLogController() : super([]);

  void info(String tag, String message) {
    _add(
      LogEntry(at: DateTime.now(), level: 'info', tag: tag, message: message),
    );
  }

  void warn(String tag, String message, [Object? error]) {
    _add(
      LogEntry(
        at: DateTime.now(),
        level: 'warn',
        tag: tag,
        message: message,
        error: error,
      ),
    );
  }

  void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _add(
      LogEntry(
        at: DateTime.now(),
        level: 'error',
        tag: tag,
        message: message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  void _add(LogEntry entry) {
    final updated = [entry, ...value];
    if (updated.length > _maxEntries) {
      updated.removeRange(_maxEntries, updated.length);
    }
    value = updated;
  }

  void clear() {
    value = [];
  }
}
