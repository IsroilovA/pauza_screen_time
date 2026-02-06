import 'package:pauza_screen_time/pauza_screen_time.dart';

import '../log/in_app_log.dart';
import '../state/health_state.dart';
import '../state/selection_state.dart';

/// Creates and provides all app dependencies (managers and controllers).
class AppDependencies {
  final PermissionManager permissionManager;
  final InstalledAppsManager installedAppsManager;
  final UsageStatsManager usageStatsManager;
  final AppRestrictionManager appRestrictionManager;

  final InAppLogController logController;
  final SelectionController selectionController;
  final HealthController healthController;

  /// Factory constructor that properly wires dependencies.
  factory AppDependencies.create() {
    final permissionManager = PermissionManager();
    final appRestrictionManager = AppRestrictionManager();
    final logController = InAppLogController();

    return AppDependencies._(
      permissionManager: permissionManager,
      installedAppsManager: InstalledAppsManager(),
      usageStatsManager: UsageStatsManager(),
      appRestrictionManager: appRestrictionManager,
      logController: logController,
      selectionController: SelectionController(),
      healthController: HealthController(
        permissionManager: permissionManager,
        restrictionManager: appRestrictionManager,
        logController: logController,
      ),
    );
  }

  AppDependencies._({
    required this.permissionManager,
    required this.installedAppsManager,
    required this.usageStatsManager,
    required this.appRestrictionManager,
    required this.logController,
    required this.selectionController,
    required this.healthController,
  });

  void dispose() {
    logController.dispose();
    selectionController.dispose();
    healthController.dispose();
  }
}
