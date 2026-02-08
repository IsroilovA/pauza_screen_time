import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:pauza_screen_time/src/core/app_identifier.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/app_restriction_platform.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/method_channel/channel_name.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/method_channel/method_names.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/model/restriction_session.dart';

/// Method-channel implementation for the Restrict Apps feature.
class RestrictionsMethodChannel extends AppRestrictionPlatform {
  @visibleForTesting
  final MethodChannel channel;

  RestrictionsMethodChannel({MethodChannel? channel})
    : channel = channel ?? const MethodChannel(restrictionsChannelName);

  @override
  Future<void> configureShield(Map<String, dynamic> configuration) {
    return channel.invokeMethod<void>(
      RestrictionsMethodNames.configureShield,
      configuration,
    );
  }

  @override
  Future<List<AppIdentifier>> setRestrictedApps(
    List<AppIdentifier> identifiers,
  ) async {
    final result = await channel.invokeMethod<List<dynamic>>(
      RestrictionsMethodNames.setRestrictedApps,
      {
        'identifiers': identifiers
            .map((identifier) => identifier.value)
            .toList(),
      },
    );
    if (result == null) return [];
    return result.cast<String>().map(AppIdentifier.new).toList();
  }

  @override
  Future<bool> addRestrictedApp(AppIdentifier identifier) async {
    final result = await channel.invokeMethod<bool>(
      RestrictionsMethodNames.addRestrictedApp,
      {'identifier': identifier.value},
    );
    return result ?? false;
  }

  @override
  Future<bool> removeRestriction(AppIdentifier identifier) async {
    final result = await channel.invokeMethod<bool>(
      RestrictionsMethodNames.removeRestriction,
      {'identifier': identifier.value},
    );
    return result ?? false;
  }

  @override
  Future<bool> isRestricted(AppIdentifier identifier) async {
    final result = await channel.invokeMethod<bool>(
      RestrictionsMethodNames.isRestricted,
      {'identifier': identifier.value},
    );
    return result ?? false;
  }

  @override
  Future<void> removeAllRestrictions() {
    return channel.invokeMethod<void>(
      RestrictionsMethodNames.removeAllRestrictions,
    );
  }

  @override
  Future<List<AppIdentifier>> getRestrictedApps() async {
    final result = await channel.invokeMethod<List<dynamic>>(
      RestrictionsMethodNames.getRestrictedApps,
    );
    if (result == null) return [];
    return result.cast<String>().map(AppIdentifier.new).toList();
  }

  @override
  Future<bool> isRestrictionSessionActiveNow() async {
    final result = await channel.invokeMethod<bool>(
      RestrictionsMethodNames.isRestrictionSessionActiveNow,
    );
    return result ?? false;
  }

  @override
  Future<bool> isRestrictionSessionConfigured() async {
    final result = await channel.invokeMethod<bool>(
      RestrictionsMethodNames.isRestrictionSessionConfigured,
    );
    return result ?? false;
  }

  @override
  Future<void> pauseEnforcement(Duration duration) {
    return channel.invokeMethod<void>(
      RestrictionsMethodNames.pauseEnforcement,
      {'durationMs': duration.inMilliseconds},
    );
  }

  @override
  Future<void> resumeEnforcement() {
    return channel.invokeMethod<void>(
      RestrictionsMethodNames.resumeEnforcement,
    );
  }

  @override
  Future<RestrictionSession> getRestrictionSession() async {
    final result = await channel.invokeMethod<Map<dynamic, dynamic>>(
      RestrictionsMethodNames.getRestrictionSession,
    );
    if (result == null) {
      return const RestrictionSession(
        isActiveNow: false,
        isPausedNow: false,
        pausedUntil: null,
        restrictedApps: [],
      );
    }

    try {
      final normalized = Map<String, dynamic>.from(result);
      return RestrictionSession.fromMap(normalized);
    } catch (_) {
      return const RestrictionSession(
        isActiveNow: false,
        isPausedNow: false,
        pausedUntil: null,
        restrictedApps: [],
      );
    }
  }
}
