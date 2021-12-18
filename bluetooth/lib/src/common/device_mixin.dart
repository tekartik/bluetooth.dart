import 'package:tekartik_bluetooth/bluetooth_device.dart';

/// To support new api without breaking
mixin BluetoothDeviceMixin implements BluetoothDevice {
  /// Assume BLE by default
  @override
  BluetoothDeviceType get type => BluetoothDeviceType.le;

  /// The id is the address by default
  @override
  String get address => id.id;
}
