import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../log/in_app_log.dart';

/// Bottom sheet widget for displaying in-app logs.
class LogSheet extends StatelessWidget {
  final InAppLogController logController;

  const LogSheet({
    super.key,
    required this.logController,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LogEntry>>(
      valueListenable: logController,
      builder: (context, entries, _) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'In-App Logs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (entries.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            final text = entries.map((e) => e.toString()).join('\n');
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logs copied to clipboard')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy'),
                        ),
                      TextButton.icon(
                        onPressed: () {
                          logController.clear();
                        },
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: entries.isEmpty
                    ? const Center(
                        child: Text(
                          'No log entries yet.\nActions will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          Color levelColor;
                          switch (entry.level) {
                            case 'error':
                              levelColor = Colors.red;
                              break;
                            case 'warn':
                              levelColor = Colors.orange;
                              break;
                            default:
                              levelColor = Colors.blue;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: SelectableText(
                              entry.toString(),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: levelColor,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
