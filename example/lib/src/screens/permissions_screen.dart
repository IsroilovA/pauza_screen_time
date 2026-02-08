import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pauza_screen_time/pauza_screen_time.dart';
import 'package:pauza_screen_time_example/src/app/dependencies.dart';
import 'package:pauza_screen_time_example/src/widgets/permission_tile.dart';

/// Permissions screen for checking and requesting Android permissions.
class PermissionsScreen extends StatefulWidget {
  final AppDependencies deps;

  const PermissionsScreen({super.key, required this.deps});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  Map<AndroidPermission, PermissionStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    // Delay permission check to avoid concurrent isolates at startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshStatuses();
      }
    });
  }

  Future<void> _refreshStatuses() async {
    if (!Platform.isAndroid) return;

    try {
      final permissions = [
        AndroidPermission.usageStats,
        AndroidPermission.accessibility,
        AndroidPermission.queryAllPackages,
      ];
      final statuses = await widget.deps.permissionManager
          .checkAndroidPermissions(permissions);
      setState(() {
        _statuses = statuses;
      });
    } catch (e) {
      widget.deps.logController.error(
        'permissions',
        'Failed to refresh permission statuses',
        e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Permissions screen is Android-only.\n'
            'This screen allows checking and requesting special access permissions.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshStatuses,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'These are special access settings controlled by Android. '
                'The app will open a Settings screen; you must enable it manually.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            PermissionTile(
              permission: AndroidPermission.usageStats,
              status: _statuses[AndroidPermission.usageStats],
              permissionManager: widget.deps.permissionManager,
              logController: widget.deps.logController,
            ),
            PermissionTile(
              permission: AndroidPermission.accessibility,
              status: _statuses[AndroidPermission.accessibility],
              permissionManager: widget.deps.permissionManager,
              logController: widget.deps.logController,
            ),
            PermissionTile(
              permission: AndroidPermission.queryAllPackages,
              status: _statuses[AndroidPermission.queryAllPackages],
              permissionManager: widget.deps.permissionManager,
              logController: widget.deps.logController,
            ),
            if (Platform.isAndroid)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Overlay Permission',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Some devices require enabling "Display over other apps" '
                          'for the shield overlay to work properly.',
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _openOverlaySettings(),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Open Overlay Settings'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openOverlaySettings() async {
    try {
      widget.deps.logController.info(
        'permissions',
        'Opening overlay settings...',
      );
      // Try to open overlay settings using method channel
      // Fallback to app details if overlay settings intent fails
      try {
        // Use a platform channel call to open overlay settings
        // For now, fallback to app details settings
        await widget.deps.permissionManager.openAndroidPermissionSettings(
          AndroidPermission.queryAllPackages, // Opens app details
        );
      } catch (e) {
        // If that fails, try accessibility settings as another fallback
        await widget.deps.permissionManager.openAndroidPermissionSettings(
          AndroidPermission.accessibility,
        );
      }
      widget.deps.logController.info('permissions', 'Overlay settings opened');
    } catch (e, st) {
      widget.deps.logController.error(
        'permissions',
        'Failed to open overlay settings',
        e,
        st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open overlay settings. '
              'Please go to Settings > Apps > ${_getAppName()} > Display over other apps',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _getAppName() {
    // This would ideally come from package info, but for simplicity:
    return 'Pauza Screen Time Example';
  }
}
