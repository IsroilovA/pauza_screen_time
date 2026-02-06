/// Formats a duration to a human-readable string (e.g., "2h 30m").
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours > 0 && minutes > 0) {
    return '${hours}h ${minutes}m';
  } else if (hours > 0) {
    return '${hours}h';
  } else if (minutes > 0) {
    return '${minutes}m';
  } else {
    return '<1m';
  }
}
