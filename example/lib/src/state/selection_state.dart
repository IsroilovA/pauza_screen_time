import 'package:flutter/foundation.dart';
import 'package:pauza_screen_time/pauza_screen_time.dart';

/// Controller for managing selected app identifiers.
class SelectionController extends ValueNotifier<Set<AppIdentifier>> {
  SelectionController() : super({});

  void toggle(AppIdentifier id) {
    final updated = Set<AppIdentifier>.from(value);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    value = updated;
  }

  void setAll(Iterable<AppIdentifier> ids) {
    value = Set<AppIdentifier>.from(ids);
  }

  void clear() {
    value = {};
  }

  bool isSelected(AppIdentifier id) => value.contains(id);
}
