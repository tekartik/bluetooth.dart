import 'package:bluez/bluez.dart';
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_common_utils/byte_utils.dart';

/// Uuid conversion
BlueZUUID bluezUuidFromUuid(Uuid128 uuid) {
  return BlueZUUID(uuid.bytes);
}

/// Uuid conversion
Uuid128 uuidFromBluezUuid(BlueZUUID bluezUuid) {
  return Uuid128.bytes(asUint8List(bluezUuid.value));
}

/// 0 if none
int bluezFlagToProperty(BlueZGattCharacteristicFlag flag) =>
    _flagToPropertyMap[flag] ?? 0;

var _flagToPropertyMap = {
  BlueZGattCharacteristicFlag.write: blePropertyWrite,
  BlueZGattCharacteristicFlag.read: blePropertyRead,
  BlueZGattCharacteristicFlag.notify: blePropertyNotify,
  BlueZGattCharacteristicFlag.broadcast: blePropertyBroadcast,

  BlueZGattCharacteristicFlag.writeWithoutResponse: blePropertyWriteNoResponse,

  BlueZGattCharacteristicFlag.indicate: blePropertyIndicate,
  BlueZGattCharacteristicFlag.authenticatedSignedWrites: blePropertySignedWrite,
  BlueZGattCharacteristicFlag.extendedProperties: blePropertyExtendedProps,
  // TODO BlueZGattCharacteristicFlag.reliableWrite: bleProperty,
  // TODO BlueZGattCharacteristicFlag.writableAuxiliaries, ,
  // TODO BlueZGattCharacteristicFlag.encryptRead,
  // TODO BlueZGattCharacteristicFlag.encryptWrite,
  // TODO BlueZGattCharacteristicFlag.encryptAuthenticatedRead,
  // TODO BlueZGattCharacteristicFlag.encryptAuthenticatedWrite,
//      TODO BlueZGattCharacteristicFlag.secureRead: bleProperty,
  BlueZGattCharacteristicFlag.secureWrite: blePropertySignedWrite,
  // TODO BlueZGattCharacteristicFlag.authorize,
};
int bluezFlagsToProperties(Set<BlueZGattCharacteristicFlag> flags) {
  var properties = 0;
  for (var flag in flags) {
    properties |= bluezFlagToProperty(flag);
  }
  return properties;
}
