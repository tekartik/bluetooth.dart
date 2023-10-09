import 'package:cv/cv.dart';
import 'package:tekartik_bluetooth/src/common/device_mixin.dart';
import 'package:tekartik_bluetooth/src/device_id.dart';

/// Bluetooth device type.
enum BluetoothDeviceType { unknown, classic, le, dual }

/// A bluetooth device.
abstract class BluetoothDevice {
  /// Its optional name
  String? get name;

  /// Its address
  String get address;

  /// Its id.
  BluetoothDeviceId get id;

  /// Its type.
  BluetoothDeviceType get type;
}

class BluetoothDeviceImpl with BluetoothDeviceMixin implements BluetoothDevice {
  // On Android it is the address
  @override
  late final BluetoothDeviceId id;

  @override
  late final String address;

  @override
  String? name;

  void fromMap(Map? map) {
    var model = asModel(map ?? {});
    // only on android
    address = model['address'].toString();
    id = BluetoothDeviceIdImpl(address);
    name = model['name']?.toString();
  }

  @override
  String toString() => toDebugMap().toString();

  Model toDebugMap() {
    var model = newModel();
    model.setValue('address', address);
    model.setValue('name', name);
    return model;
  }
}
