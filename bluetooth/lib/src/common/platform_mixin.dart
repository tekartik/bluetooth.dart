import 'dart:io';

import 'package:tekartik_bluetooth/src/import.dart';

mixin BluetoothManagerPlatformCompatMixin {
  /// Need for all implementation for now
  /// False on the web (js and wasm: isRunningAsJavascript is false on wasm).
  bool? get isAndroid => kDartIsWeb ? false : Platform.isAndroid;

  /// False on the web.
  bool? get isIOS => kDartIsWeb ? false : Platform.isIOS;
}
