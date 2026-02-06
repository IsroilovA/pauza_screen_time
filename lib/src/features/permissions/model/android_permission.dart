// Android-specific permissions required by the plugin.
//
// This enum represents permissions specific to the Android platform
// for app restriction, usage tracking, and overlay functionality.

/// Android platform permissions.
enum AndroidPermission {
  /// Permission to access app usage statistics.
  /// Requires user to grant "Usage Access" in system settings.
  /// Manifest: android.permission.PACKAGE_USAGE_STATS
  usageStats(
    key: 'android.usageStats',
    displayName: 'Usage Access',
    description: 'Required to access app usage statistics and screen time data',
  ),

  /// Permission to use Accessibility Service.
  /// Required for detecting foreground app changes.
  /// User must enable the service in Accessibility settings.
  accessibility(
    key: 'android.accessibility',
    displayName: 'Accessibility Service',
    description: 'Required to detect when restricted apps are launched',
  ),

  /// Permission to draw overlay windows over other apps.
  /// Required for displaying the blocking shield.
  /// Manifest: android.permission.SYSTEM_ALERT_WINDOW
  overlay(
    key: 'android.overlay',
    displayName: 'Display Over Other Apps',
    description: 'Required to display the blocking screen over restricted apps',
  ),

  /// Permission to query all installed packages.
  /// Required on Android 11+ to enumerate installed apps.
  /// Manifest: android.permission.QUERY_ALL_PACKAGES
  queryAllPackages(
    key: 'android.queryAllPackages',
    displayName: 'Query All Packages',
    description: 'Required to list all installed applications',
  );

  const AndroidPermission({
    required this.key,
    required this.displayName,
    required this.description,
  });

  /// The string key for platform channel communication.
  final String key;

  /// A user-friendly name for the permission.
  final String displayName;

  /// A description of what the permission is used for.
  final String description;

  /// Creates an AndroidPermission from its string key.
  factory AndroidPermission.fromKey(String key) {
    return AndroidPermission.values.firstWhere(
      (element) => element.key == key,
      orElse: () => throw ArgumentError('Unknown Android permission key: $key'),
    );
  }
}

