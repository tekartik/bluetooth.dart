import 'package:tekartik_bluetooth_web/src/import_bluetooth.dart';

import 'bluetooth_device_web.dart';

class ScanResultWeb implements ScanResult {
  @override
  final BluetoothDeviceWeb device;

  ScanResultWeb(this.device);

  @override
  final int rssi = 0;
}
