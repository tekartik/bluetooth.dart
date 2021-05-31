import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

class BluetoothPeripheralMock extends BluetoothPeripheral {
  BluetoothPeripheralMock(
      {BluetoothPeripheralPlugin? plugin, // Needed?
      String? deviceName,
      List<BluetoothGattService>? services})
      : super(plugin: plugin, deviceName: deviceName, services: services);

  /// Current advertiseData
  AdvertiseData? advertiseData;

  @override
  Future<void> startAdvertising({AdvertiseData? advertiseData}) async {
    this.advertiseData = advertiseData ?? AdvertiseData();
  }

  @override
  Future<void> stopAdvertising() async {
    advertiseData = null;
  }
}
