import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_test_app/ble/app_ble.dart';

void initWithFlutterBlue() {
  initBluetoothManager = bluetoothManager;
  deviceBluetoothManager = bluetoothManagerFlutterBlue;
}
