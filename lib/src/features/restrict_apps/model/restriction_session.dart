import 'package:pauza_screen_time/src/core/app_identifier.dart';

/// Snapshot of the current restriction session state.
class RestrictionSession {
  const RestrictionSession({
    required this.isActiveNow,
    required this.restrictedApps,
  });

  /// Whether restrictions are currently considered active.
  final bool isActiveNow;

  /// Current restricted app identifiers.
  final List<AppIdentifier> restrictedApps;

  /// Parses session payload from platform channels.
  factory RestrictionSession.fromMap(Map<String, dynamic> map) {
    final isActiveNow = map['isActiveNow'] as bool? ?? false;
    final rawRestrictedApps = map['restrictedApps'];
    final restrictedApps = switch (rawRestrictedApps) {
      final List<dynamic> values =>
        values.whereType<String>().map(AppIdentifier.new).toList(),
      _ => const <AppIdentifier>[],
    };

    return RestrictionSession(
      isActiveNow: isActiveNow,
      restrictedApps: restrictedApps,
    );
  }
}
