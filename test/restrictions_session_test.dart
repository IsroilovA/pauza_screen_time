import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pauza_screen_time/src/core/app_identifier.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/app_restriction_platform.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/data/app_restriction_manager.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/method_channel/channel_name.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/method_channel/method_names.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/method_channel/restrictions_method_channel.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/model/restriction_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RestrictionsMethodChannel session APIs', () {
    const channel = MethodChannel(restrictionsChannelName);
    final methodChannel = RestrictionsMethodChannel(channel: channel);

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'isRestrictionSessionActiveNow returns false on null result',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method ==
                  RestrictionsMethodNames.isRestrictionSessionActiveNow) {
                return null;
              }
              return null;
            });

        final isActive = await methodChannel.isRestrictionSessionActiveNow();
        expect(isActive, isFalse);
      },
    );

    test('getRestrictionSession parses valid payload', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == RestrictionsMethodNames.getRestrictionSession) {
              return {
                'isActiveNow': true,
                'restrictedApps': ['x'],
              };
            }
            return null;
          });

      final session = await methodChannel.getRestrictionSession();
      expect(session.isActiveNow, isTrue);
      expect(session.restrictedApps, const [AppIdentifier('x')]);
    });

    test('getRestrictionSession defaults missing keys', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == RestrictionsMethodNames.getRestrictionSession) {
              return <String, dynamic>{};
            }
            return null;
          });

      final session = await methodChannel.getRestrictionSession();
      expect(session, isA<RestrictionSession>());
      expect(session.isActiveNow, isFalse);
      expect(session.restrictedApps, isEmpty);
    });
  });

  group('AppRestrictionManager session delegation', () {
    test('delegates session methods to platform', () async {
      final fakePlatform = _FakeAppRestrictionPlatform();
      final manager = AppRestrictionManager(platform: fakePlatform);

      final isActiveNow = await manager.isRestrictionSessionActiveNow();
      final session = await manager.getRestrictionSession();

      expect(fakePlatform.isRestrictionSessionActiveNowCalled, isTrue);
      expect(fakePlatform.getRestrictionSessionCalled, isTrue);
      expect(isActiveNow, isTrue);
      expect(session.isActiveNow, isTrue);
      expect(session.restrictedApps, const [
        AppIdentifier.android('com.example.app'),
      ]);
    });
  });
}

class _FakeAppRestrictionPlatform extends AppRestrictionPlatform {
  bool isRestrictionSessionActiveNowCalled = false;
  bool getRestrictionSessionCalled = false;

  @override
  Future<bool> addRestrictedApp(AppIdentifier identifier) async => false;

  @override
  Future<void> configureShield(Map<String, dynamic> configuration) async {}

  @override
  Future<List<AppIdentifier>> getRestrictedApps() async => const [];

  @override
  Future<bool> isRestricted(AppIdentifier identifier) async => false;

  @override
  Future<void> removeAllRestrictions() async {}

  @override
  Future<bool> removeRestriction(AppIdentifier identifier) async => false;

  @override
  Future<List<AppIdentifier>> setRestrictedApps(
    List<AppIdentifier> identifiers,
  ) async => const [];

  @override
  Future<RestrictionSession> getRestrictionSession() async {
    getRestrictionSessionCalled = true;
    return const RestrictionSession(
      isActiveNow: true,
      restrictedApps: [AppIdentifier('com.example.app')],
    );
  }

  @override
  Future<bool> isRestrictionSessionActiveNow() async {
    isRestrictionSessionActiveNowCalled = true;
    return true;
  }
}
