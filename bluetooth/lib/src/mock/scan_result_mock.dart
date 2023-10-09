import 'package:tekartik_bluetooth/bluetooth_device.dart';

class ScanResultMock implements ScanResult {
  @override
  final BluetoothDevice device;

  @override
  final int rssi;

  ScanResultMock({required this.device, this.rssi = 50});
}
