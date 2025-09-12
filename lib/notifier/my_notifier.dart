import 'package:flutter/material.dart';

class MyNotifier {
  final ValueNotifier<int> myValue;
  final BuildContext context;
  VoidCallback? _listener;

  MyNotifier(this.myValue, this.context) {
    _listener = () {
      if (myValue.value % 2 == 0) {
        // Check if context is still mounted before updating
        try {
          final element = context as Element;
          if (element.mounted) {
            element.markNeedsBuild();
          }
        } catch (e) {
          // Context is no longer valid, ignore the update
          print('MyNotifier: Context no longer valid, skipping update');
        }
      }
    };
    myValue.addListener(_listener!);
  }

  void dispose() {
    if (_listener != null) {
      myValue.removeListener(_listener!);
      _listener = null;
    }
  }
}