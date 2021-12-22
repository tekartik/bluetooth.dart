import 'package:tekartik_bluetooth_bluez/bluetooth_bluez.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_test_app/ble/app_ble.dart';
import 'package:tekartik_bluetooth_test_app/import/common_import.dart';
import 'package:tekartik_bluetooth_web/bluetooth_web.dart';

void initWithBleWeb() {
  initBluetoothManager = bluetoothManagerWeb;
  deviceBluetoothManager = bluetoothManagerFlutterBlue;
}

void initWithFlutterBlue() {
  initBluetoothManager = bluetoothAdminManagerFlutter;
  deviceBluetoothManager = bluetoothManagerFlutterBlue;
  bluetoothAdminManagerFlutter
      // ignore: deprecated_member_use
      .devSetOptions(BluetoothOptions()..logLevel = bluetoothLogLevelVerbose);
}

void initWithBluez() {
  // ignore: deprecated_member_use
  debugBluetoothManagerBluez = devWarning(true);
  initBluetoothManager = bluetoothManagerBluez;
  deviceBluetoothManager = bluetoothManagerBluez;
}
