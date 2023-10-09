import 'flutter_blue_import.dart' as native;
import 'import_bluetooth.dart';

class BluetoothDeviceIdFlutterBlue
    with BluetoothDeviceIdMixin
    implements BluetoothDeviceId {
  final native.DeviceIdentifier nativeId;

  BluetoothDeviceIdFlutterBlue(this.nativeId);

  @override
  String get id => nativeId.str;
}

class BluetoothDeviceFlutterBlue
    with BluetoothDeviceMixin
    implements BluetoothDevice {
  final native.BluetoothDevice nativeImpl;

  BluetoothDeviceFlutterBlue(this.nativeImpl);

  @override
  String get address => nativeImpl.remoteId.str;

  @override
  BluetoothDeviceId get id => BluetoothDeviceIdFlutterBlue(nativeImpl.remoteId);

  @override
  String get name => nativeImpl.platformName;

  @override
  BluetoothDeviceType get type => BluetoothDeviceType.le;
}
