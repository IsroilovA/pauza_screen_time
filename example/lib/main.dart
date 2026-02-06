import 'package:flutter/material.dart';

import 'src/app/app_shell.dart';
import 'src/app/dependencies.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppDependencies _deps;

  @override
  void initState() {
    super.initState();
    _deps = AppDependencies.create();
  }

  @override
  void dispose() {
    _deps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pauza Screen Time Showcase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: AppShell(deps: _deps),
    );
  }
}
