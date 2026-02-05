import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Platform interface for installed apps functionality.
///
/// Defines the contract for platform-specific implementations
/// of app enumeration and information retrieval.

/// The interface for installed apps platform implementations.
abstract class InstalledAppsPlatform extends PlatformInterface {
  InstalledAppsPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Returns a list of all installed applications.
  ///
  /// [includeSystemApps] - Whether to include system apps.
  /// [includeIcons] - Whether to include app icons (default: true).
  Future<List<Map<dynamic, dynamic>>> getInstalledApps(
    bool includeSystemApps, [
    bool includeIcons = true,
  ]) {
    throw UnimplementedError('getInstalledApps() has not been implemented.');
  }

  /// Returns information about a specific app.
  ///
  /// Returns null if the app is not found.
  /// [includeIcons] - Whether to include app icons (default: true).
  Future<Map<dynamic, dynamic>?> getAppInfo(
    String packageId, [
    bool includeIcons = true,
  ]) {
    throw UnimplementedError('getAppInfo() has not been implemented.');
  }

  /// Shows the iOS FamilyActivityPicker for user to select apps.
  ///
  /// [preSelectedTokens] - Optional list of base64-encoded ApplicationTokens
  /// that should appear pre-selected when the picker opens.
  ///
  /// Only available on iOS.
  Future<List<Map<dynamic, dynamic>>> showFamilyActivityPicker({List<String>? preSelectedTokens}) {
    throw UnimplementedError('showFamilyActivityPicker() has not been implemented.');
  }
}
