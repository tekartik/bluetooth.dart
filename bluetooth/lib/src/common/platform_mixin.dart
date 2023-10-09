import 'dart:io';

import 'package:tekartik_bluetooth/src/import.dart';

mixin BluetoothManagerPlatformCompatMixin {
  /// Need for all implementation for now
  bool? get isAndroid => isRunningAsJavascript ? false : Platform.isAndroid;

  bool? get isIOS => isRunningAsJavascript ? false : Platform.isIOS;
}
