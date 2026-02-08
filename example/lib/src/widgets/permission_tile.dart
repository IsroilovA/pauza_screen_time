import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pauza_screen_time/pauza_screen_time.dart';

import '../log/in_app_log.dart';

/// Widget for displaying a permission status with action buttons.
class PermissionTile extends StatelessWidget {
  final AndroidPermission permission;
  final PermissionStatus? status;
  final PermissionManager permissionManager;
  final InAppLogController logController;

  const PermissionTile({
    super.key,
    required this.permission,
    required this.status,
    required this.permissionManager,
    required this.logController,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const ListTile(
        title: Text('Android only'),
        subtitle: Text('This permission is only available on Android'),
      );
    }

    final isGranted = status?.isGranted ?? false;
    final canRequest = status?.canRequest ?? false;
    final isQueryAllPackages = permission == AndroidPermission.queryAllPackages;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permission.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        permission.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    isGranted ? 'Granted' : 'Denied',
                    style: TextStyle(
                      color: isGranted ? Colors.white : Colors.black87,
                    ),
                  ),
                  backgroundColor: isGranted ? Colors.green : Colors.grey[300],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!isQueryAllPackages || canRequest)
                  ElevatedButton.icon(
                    onPressed: () => _handleRequest(context),
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Request / Open'),
                  ),
                ElevatedButton.icon(
                  onPressed: () => _handleOpenSettings(context),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[100],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _handleCheck(context),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Check'),
                ),
              ],
            ),
            if (isQueryAllPackages)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Note: This permission is manifest-only and cannot be requested at runtime.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[800],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRequest(BuildContext context) async {
    try {
      logController.info(
        'permissions',
        'Requesting ${permission.displayName}...',
      );
      await permissionManager.requestAndroidPermission(permission);
      logController.info(
        'permissions',
        'Opened settings flow for ${permission.displayName}. Re-check after returning.',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Settings opened. Please enable ${permission.displayName} and tap Check when you return.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, st) {
      logController.error(
        'permissions',
        'Failed to request ${permission.displayName}',
        e,
        st,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _handleOpenSettings(BuildContext context) async {
    try {
      logController.info(
        'permissions',
        'Opening settings for ${permission.displayName}...',
      );
      await permissionManager.openAndroidPermissionSettings(permission);
      logController.info(
        'permissions',
        'Settings opened for ${permission.displayName}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Settings opened. Please enable the permission and return to check again.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e, st) {
      logController.error(
        'permissions',
        'Failed to open settings for ${permission.displayName}',
        e,
        st,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _handleCheck(BuildContext context) async {
    try {
      logController.info(
        'permissions',
        'Checking ${permission.displayName}...',
      );
      final status = await permissionManager.checkAndroidPermission(permission);
      logController.info(
        'permissions',
        'Status for ${permission.displayName}: ${status.name}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status: ${status.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, st) {
      logController.error(
        'permissions',
        'Failed to check ${permission.displayName}',
        e,
        st,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
}
