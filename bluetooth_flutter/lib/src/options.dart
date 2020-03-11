import 'package:tekartik_bluetooth_flutter/src/constant.dart';

///
/// internal options.
///
/// Used internally.
///
/// deprecated since 1.1.1 for internal usage only
///
@deprecated
class BluetoothOptions {
  BluetoothOptions({this.logLevel});
  int logLevel;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (logLevel != null) {
      map[paramLogLevel] = logLevel;
    }
    return map;
  }

  void fromMap(Map<String, dynamic> map) {
    final dynamic logLevel = map[paramLogLevel];
    if (logLevel is int) {
      this.logLevel = logLevel;
    }
  }
}
