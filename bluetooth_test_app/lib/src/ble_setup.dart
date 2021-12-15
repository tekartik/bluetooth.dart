import 'package:tekartik_bluetooth_bluez/bluetooth_bluez.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_test_app/ble/app_ble.dart';
import 'package:tekartik_bluetooth_test_app/import/common_import.dart';

void initWithFlutterBlue() {
  initBluetoothManager = bluetoothManager;
  deviceBluetoothManager = bluetoothManagerFlutterBlue;
}

void initWithBluez() {
  // ignore: deprecated_member_use
  debugBluetoothManagerBluez = devWarning(true);
  initBluetoothManager = bluetoothManagerBluez;
  deviceBluetoothManager = bluetoothManagerBluez;
}
