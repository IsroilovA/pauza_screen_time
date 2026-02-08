import 'package:flutter/material.dart';

import '../screens/apps_screen.dart';
import '../screens/health_screen.dart';
import '../screens/permissions_screen.dart';
import '../screens/restrict_screen.dart';
import '../screens/usage_screen.dart';
import '../widgets/log_sheet.dart';
import 'dependencies.dart';

/// Main app shell with bottom navigation and log panel.
class AppShell extends StatefulWidget {
  final AppDependencies deps;

  const AppShell({super.key, required this.deps});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize screens lazily - they'll be created when needed
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HealthScreen(deps: widget.deps);
      case 1:
        return PermissionsScreen(deps: widget.deps);
      case 2:
        return AppsScreen(deps: widget.deps);
      case 3:
        return UsageScreen(deps: widget.deps);
      case 4:
        return RestrictScreen(deps: widget.deps);
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  void _showLogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LogSheet(logController: widget.deps.logController),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pauza Screen Time Showcase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showLogSheet,
            tooltip: 'View Logs',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildScreen(0),
          _buildScreen(1),
          _buildScreen(2),
          _buildScreen(3),
          _buildScreen(4),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.health_and_safety),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.security),
            label: 'Permissions',
          ),
          NavigationDestination(icon: Icon(Icons.apps), label: 'Apps'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Usage'),
          NavigationDestination(icon: Icon(Icons.block), label: 'Restrict'),
        ],
      ),
    );
  }
}
