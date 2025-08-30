import 'package:flutter/material.dart';

class MyNotifier {
  final ValueNotifier<int> myValue;
  final BuildContext context;

  MyNotifier(this.myValue, this.context) {
    myValue.addListener(() {
      if (myValue.value % 2 == 0) {
        // Update the state of MyWidget
        (context as Element).markNeedsBuild();
      }
    });
  }
}