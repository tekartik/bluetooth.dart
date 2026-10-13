import 'package:bluez/bluez.dart';
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/utils/ble_utils.dart';
import 'package:tekartik_bluetooth/uuid.dart';

import 'import.dart';

/// Uuid conversion
BlueZUUID bluezUuidFromUuid(Uuid128 uuid) {
  return BlueZUUID(uuid.bytes);
}

/// Uuid conversion
Uuid128 uuidFromBluezUuid(BlueZUUID bluezUuid) {
  return Uuid128.bytes(asUint8List(bluezUuid.value));
}

/// 0 if none
int bluezFlagToProperty(BlueZGattCharacteristicFlag flag) {
  var bleFlag = BleCharacteristicPropertyFlag.values.asNameMap()[flag.name];
  return bleFlag == null ? 0 : propertyFlagsToPropertyValue({bleFlag});
}

int bluezFlagsToProperties(Set<BlueZGattCharacteristicFlag> flags) {
  var properties = 0;
  for (var flag in flags) {
    properties |= bluezFlagToProperty(flag);
  }
  return properties;
}
