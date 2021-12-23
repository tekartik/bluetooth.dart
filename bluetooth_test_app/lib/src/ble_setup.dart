import 'package:tekartik_bluetooth_bluez/bluetooth_bluez.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_test_app/ble/app_ble.dart';
import 'package:tekartik_bluetooth_test_app/import/common_import.dart';
import 'package:tekartik_bluetooth_web/bluetooth_web.dart';

/// Common services for testing, for now only battery
List<String> webOptionalServiceIds = ['00001801-0000-1000-8000-00805f9b34fb'];

void initWithBleWeb() {
  initBluetoothManager = bluetoothManagerWeb;
  deviceBluetoothManager = bluetoothManagerWeb;
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
