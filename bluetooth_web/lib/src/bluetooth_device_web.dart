import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart' as web;
import 'package:tekartik_bluetooth_web/src/import_bluetooth.dart';

/// Device for the web
class BluetoothDeviceWeb with BluetoothDeviceMixin implements BluetoothDevice {
  final web.BluetoothDevice nativeDevice;
  @override
  final BluetoothDeviceId id;

  BluetoothDeviceWeb(this.nativeDevice)
    : id = BluetoothDeviceId(nativeDevice.id);

  @override
  String? get name => nativeDevice.name;
}
