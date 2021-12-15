import 'package:flutter/material.dart';

mixin AppScreenMixin {
  void snackInfo(BuildContext context, String text) {
    var snackBar = SnackBar(content: Text(text));
    // ignore: avoid_print
    print(text);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void snackError(BuildContext context, String text) {
    var snackBar = SnackBar(content: Text('ERROR $text'));
    // ignore: avoid_print
    print('ERROR $text');

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
