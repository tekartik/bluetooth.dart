import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/uuid.dart';

BleBluetoothDescriptor descriptorFromMap({
  required BleBluetoothCharacteristic characteristic,
  required Map map,
}) {
  return BleBluetoothDescriptor(
    characteristic: characteristic,
    uuid: Uuid128.from(text: map[uuidKey] as String?),
  );
}
