import 'package:flutter_blue/flutter_blue.dart' as native;
import 'package:tekartik_bluetooth/bluetooth_device.dart';

class BluetoothDeviceFlutterBlue implements BluetoothDevice {
  final native.BluetoothDevice nativeImpl;

  BluetoothDeviceFlutterBlue(this.nativeImpl);
  @override
  String get address => nativeImpl.id?.id;

  @override
  String get id => nativeImpl.id.id;

  @override
  String get name => nativeImpl.name;
}
