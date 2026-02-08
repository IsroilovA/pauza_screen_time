import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pauza_screen_time/pauza_screen_time.dart';
import 'package:pauza_screen_time_example/src/app/dependencies.dart';
import 'package:pauza_screen_time_example/src/state/health_state.dart';

/// Health dashboard screen showing overall status and quick actions.
class HealthScreen extends StatefulWidget {
  final AppDependencies deps;

  const HealthScreen({super.key, required this.deps});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  bool _hasRefreshed = false;

  @override
  void initState() {
    super.initState();
    // Refresh health status on first load, but only once
    if (Platform.isAndroid && !_hasRefreshed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasRefreshed) {
          _hasRefreshed = true;
          widget.deps.healthController.refresh();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Health dashboard is Android-only.\n'
            'This screen shows permission statuses and restricted app counts.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      body: ValueListenableBuilder<HealthSnapshot?>(
        valueListenable: widget.deps.healthController,
        builder: (context, snapshot, _) {
          if (snapshot == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Loading health status...'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => widget.deps.healthController.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => widget.deps.healthController.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Health Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StatusRow(
                          label: 'Usage Access',
                          isGranted: snapshot.isUsageStatsGranted,
                        ),
                        _StatusRow(
                          label: 'Accessibility Service',
                          isGranted: snapshot.isAccessibilityGranted,
                        ),
                        _StatusRow(
                          label: 'Query All Packages',
                          isGranted: snapshot.isQueryAllPackagesGranted,
                        ),
                        const Divider(),
                        _StatusRow(
                          label: 'Restricted Apps',
                          value: '${snapshot.restrictedCount}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Last updated: ${_formatTime(snapshot.updatedAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => widget.deps.healthController.refresh(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh All'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => widget.deps.permissionManager
                          .openAndroidPermissionSettings(
                            AndroidPermission.usageStats,
                          ),
                      icon: const Icon(Icons.settings),
                      label: const Text('Usage Access'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => widget.deps.permissionManager
                          .openAndroidPermissionSettings(
                            AndroidPermission.accessibility,
                          ),
                      icon: const Icon(Icons.settings),
                      label: const Text('Accessibility'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool? isGranted;
  final String? value;

  const _StatusRow({required this.label, this.isGranted, this.value});

  @override
  Widget build(BuildContext context) {
    Widget trailing;
    if (value != null) {
      trailing = Text(
        value!,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    } else if (isGranted != null) {
      trailing = Chip(
        label: Text(
          isGranted! ? 'Granted' : 'Denied',
          style: TextStyle(
            color: isGranted! ? Colors.white : Colors.black87,
            fontSize: 11,
          ),
        ),
        backgroundColor: isGranted! ? Colors.green : Colors.grey[300],
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      );
    } else {
      trailing = const Text('Unknown');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), trailing],
      ),
    );
  }
}
