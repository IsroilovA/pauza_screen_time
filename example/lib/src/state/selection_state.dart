import 'package:flutter/foundation.dart';

/// Controller for managing selected app package IDs.
class SelectionController extends ValueNotifier<Set<String>> {
  SelectionController() : super({});

  void toggle(String id) {
    final updated = Set<String>.from(value);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    value = updated;
  }

  void setAll(Iterable<String> ids) {
    value = Set<String>.from(ids);
  }

  void clear() {
    value = {};
  }

  bool isSelected(String id) => value.contains(id);
}
