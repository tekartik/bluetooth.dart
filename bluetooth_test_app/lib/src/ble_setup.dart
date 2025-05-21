import 'package:tekartik_app_platform/app_platform.dart';
import 'package:tekartik_bluetooth_test_app/ble/app_ble.dart';
import 'package:tekartik_bluetooth_test_app/import/common_import.dart';
import 'package:tekartik_bluetooth_test_app/import/import_bluetooth.dart';

/// Common services for testing, for now only battery
List<String> webOptionalServiceIds = ['00001801-0000-1000-8000-00805f9b34fb'];

void initWithBleWeb() {
  initBluetoothManager = bluetoothManagerWeb;
  deviceBluetoothManager = bluetoothManagerWeb;
}

void initWithFlutterBlue() {
  if (platformContext.io?.isIOS ?? false) {
    // ignore: avoid_print
    print('iOS user flutter blue');
    initBluetoothManager = bluetoothAdminManagerFlutterBlue;
  } else {
    initBluetoothManager = bluetoothAdminManagerFlutter;
  }
  deviceBluetoothManager = bluetoothManagerFlutterBlue;
  initBluetoothManager
  // ignore: deprecated_member_use
  .devSetOptions(BluetoothOptions()..logLevel = bluetoothLogLevelVerbose);
}

void initWithBluez() {
  // ignore: deprecated_member_use
  debugBluetoothManagerBluez = devWarning(true);
  initBluetoothManager = bluetoothManagerBluez;
  deviceBluetoothManager = bluetoothManagerBluez;
}
