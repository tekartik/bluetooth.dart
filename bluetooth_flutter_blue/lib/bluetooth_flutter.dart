import 'package:flutter_blue/flutter_blue.dart';

//export 'package:flutter_blue/flutter_blue.dart';
export 'package:tekartik_bluetooth/bluetooth.dart';
export 'package:tekartik_bluetooth/bluetooth_state_service.dart';
export 'package:tekartik_bluetooth_flutter/bluetooth_flutter.dart'
    show
        bluetoothLogLevelNone,
        bluetoothLogLevelVerbose,
        // ignore: deprecated_member_use
        BluetoothOptions;

class BluetoothFlutterBlue {
  static bool _isSupported;

  static Future<bool> get _isSupportedReady async {
    return _isSupported ??= await FlutterBlue.instance.isAvailable;
  }

  static Future<BluetoothState> get bluetoothState async {
    _isSupported ??= await _isSupportedReady;
    if (_isSupported) {
      return await FlutterBlue.instance.state.first;
    } else {
      return BluetoothState.unavailable;
    }
  }
}
