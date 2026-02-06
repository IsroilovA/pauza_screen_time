import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Segment granularity for iOS usage reports.
enum IOSUsageReportSegment {
  daily('daily'),
  hourly('hourly');

  const IOSUsageReportSegment(this.value);

  final String value;
}

/// iOS-only usage report platform view.
///
/// This widget embeds a native DeviceActivityReport view via UiKitView.
/// It requires iOS 16.0+ and a Device Activity Report extension target
/// configured in the host app.
class UsageReportView extends StatelessWidget {
  /// Report context identifier used by the iOS report extension.
  final String reportContext;

  /// Start of the reporting interval.
  final DateTime startDate;

  /// End of the reporting interval.
  final DateTime endDate;

  /// Segment granularity for the report.
  final IOSUsageReportSegment segment;

  /// Optional fallback to render on non-iOS platforms.
  final Widget? fallback;

  const UsageReportView({
    required this.reportContext,
    required this.startDate,
    required this.endDate,
    this.segment = IOSUsageReportSegment.daily,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isIOS) {
      return fallback ?? const SizedBox.shrink();
    }

    return UiKitView(
      viewType: 'pauza_screen_time/usage_report',
      creationParams: {
        'reportContext': reportContext,
        'segment': segment.value,
        'startTimeMs': startDate.millisecondsSinceEpoch,
        'endTimeMs': endDate.millisecondsSinceEpoch,
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

/// iOS-specific alias for [UsageReportView].
class IOSUsageReportView extends UsageReportView {
  const IOSUsageReportView({
    required super.reportContext,
    required super.startDate,
    required super.endDate,
    super.segment,
    super.fallback,
    super.key,
  });
}
