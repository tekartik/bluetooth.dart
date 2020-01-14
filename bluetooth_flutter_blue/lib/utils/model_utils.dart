import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter_blue/src/constant.dart';

BleBluetoothDescriptor descriptorFromMap(
    {BleBluetoothCharacteristic characteristic, Map map}) {
  if (map == null) {
    return null;
  }
  return BleBluetoothDescriptor(
      characteristic: characteristic,
      uuid: Uuid128.from(text: map[uuidKey] as String));
}
