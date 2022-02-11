import 'dart:typed_data';

import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter_blue/utils/guid_utils.dart';

import 'flutter_blue_import.dart' as native;

class BluetoothCharacteristicFlutterBlue {
  final native.BluetoothCharacteristic nativeImpl;

  BluetoothCharacteristicFlutterBlue(this.nativeImpl);

  Future<List<int>> read() async {
    return await nativeImpl.read();
  }

  Future<void> write(Uint8List value) async {
    await nativeImpl.write(value);
  }

  Future<void> registerNotification(bool on) async {
    await nativeImpl.setNotifyValue(on);
  }

  /// Value changed
  Stream<List<int>> get value {
    return nativeImpl.value;
  }
}

class DiscoveredServiceFlutterBlue {
  final native.BluetoothService nativeImpl;

  final _map = <Uuid128, BluetoothCharacteristicFlutterBlue>{};

  DiscoveredServiceFlutterBlue(this.nativeImpl) {
    for (var nativeCharacteristic in nativeImpl.characteristics) {
      var uuid = uuidFromGuid(nativeCharacteristic.uuid);
      var bleCharacteristic =
          BluetoothCharacteristicFlutterBlue(nativeCharacteristic);
      _map[uuid] = bleCharacteristic;
    }
  }

  BluetoothCharacteristicFlutterBlue? getCharacteristic(Uuid128? uuid) =>
      _map[uuid!];
//BleBluetoothService service;

}
