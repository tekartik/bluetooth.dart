import 'package:flutter/services.dart';
import 'package:tekartik_bluetooth_flutter/src/constant.dart';

// const MethodChannel methodChannel = MethodChannel('tekartik_bluetooth_flutter');

class BluetoothFlutterPlugin {
  final EventChannel connectionChannel =
      const EventChannel('$namespace/connection');
  final MethodChannel methodChannel =
      const MethodChannel('tekartik_bluetooth_flutter');
  final MethodChannel callbackChannel =
      const MethodChannel('$namespace/callback');
  final EventChannel writeCharacteristicChannel =
      const EventChannel('$namespace/writeCharacteristic');

  BluetoothFlutterPlugin._();
}

final BluetoothFlutterPlugin bluetoothFlutterPlugin =
    BluetoothFlutterPlugin._();
