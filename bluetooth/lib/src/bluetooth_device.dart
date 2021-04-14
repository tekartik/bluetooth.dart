import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/src/device_id.dart';
import 'package:tekartik_common_utils/model/model.dart';

abstract class BluetoothDevice {
  String? get name;
  String get address;

  BluetoothDeviceId get id;
}

class BluetoothDeviceImpl implements BluetoothDevice {
  // On Android it is the address
  @override
  late final BluetoothDeviceId id;

  @override
  late final String address;

  @override
  String? name;

  void fromMap(Map? map) {
    var model = Model(map);
    // only on android
    address = model['address'].toString();
    id = BluetoothDeviceIdImpl(address);
    name = model['name']?.toString();
  }

  @override
  String toString() => toDebugMap().toString();

  Model toDebugMap() {
    var model = Model();
    model.setValue('address', address);
    model.setValue('name', name);
    return model;
  }
}
