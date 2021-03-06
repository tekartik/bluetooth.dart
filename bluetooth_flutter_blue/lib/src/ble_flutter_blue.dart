import 'package:flutter_blue/flutter_blue.dart' as native;
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter_blue/utils/guid_utils.dart';

class BluetoothCharacteristicFlutterBlue {
  final native.BluetoothCharacteristic nativeImpl;

  BluetoothCharacteristicFlutterBlue(this.nativeImpl);

  Future<List<int>> read() async {
    return await nativeImpl.read();
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
