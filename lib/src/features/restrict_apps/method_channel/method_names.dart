/// App restriction feature method names.
///
/// Keep in sync with native handlers.
class RestrictionsMethodNames {
  const RestrictionsMethodNames._();

  static const String configureShield = 'configureShield';
  static const String setRestrictedApps = 'setRestrictedApps';
  static const String addRestrictedApp = 'addRestrictedApp';
  static const String removeRestriction = 'removeRestriction';
  static const String removeAllRestrictions = 'removeAllRestrictions';
  static const String getRestrictedApps = 'getRestrictedApps';
  static const String isRestricted = 'isRestricted';
}
