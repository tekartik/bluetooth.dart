import 'package:flutter_blue/flutter_blue.dart' as native;
import 'package:tekartik_bluetooth/bluetooth_device.dart';

class BluetoothDeviceIdFlutterBlue
    with BluetoothDeviceIdMixin
    implements BluetoothDeviceId {
  final native.DeviceIdentifier nativeId;

  BluetoothDeviceIdFlutterBlue(this.nativeId);

  @override
  String get id => nativeId.id;
}

class BluetoothDeviceFlutterBlue implements BluetoothDevice {
  final native.BluetoothDevice nativeImpl;

  BluetoothDeviceFlutterBlue(this.nativeImpl);
  @override
  String get address => nativeImpl.id?.id;

  @override
  BluetoothDeviceId get id => BluetoothDeviceIdFlutterBlue(nativeImpl.id);

  @override
  String get name => nativeImpl.name;
}
