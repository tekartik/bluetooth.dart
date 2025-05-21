import 'package:tekartik_bluetooth/ble.dart';

/// 0 if none
Set<BleCharacteristicPropertyFlag> propertiesValueToPropertyFlags(
  int propertiesValue,
) {
  var flags = <BleCharacteristicPropertyFlag>{};
  for (var flag in BleCharacteristicPropertyFlag.values) {
    var value = _propertyFlagToPropertyValue(flag);
    if (value != 0 && (propertiesValue & value) == value) {
      flags.add(flag);
    }
  }
  return flags;
}

/// 0 if none
int _propertyFlagToPropertyValue(BleCharacteristicPropertyFlag flag) =>
    _flagToPropertyMap[flag] ?? 0;
var _flagToPropertyMap = {
  BleCharacteristicPropertyFlag.write: blePropertyWrite,
  BleCharacteristicPropertyFlag.read: blePropertyRead,
  BleCharacteristicPropertyFlag.notify: blePropertyNotify,
  BleCharacteristicPropertyFlag.broadcast: blePropertyBroadcast,

  BleCharacteristicPropertyFlag.writeWithoutResponse:
      blePropertyWriteNoResponse,

  BleCharacteristicPropertyFlag.indicate: blePropertyIndicate,
  BleCharacteristicPropertyFlag.authenticatedSignedWrites:
      blePropertySignedWrite,
  BleCharacteristicPropertyFlag.extendedProperties: blePropertyExtendedProps,
  // TODO BlueZGattCharacteristicFlag.reliableWrite: bleProperty,
  // TODO BlueZGattCharacteristicFlag.writableAuxiliaries, ,
  // TODO BlueZGattCharacteristicFlag.encryptRead,
  // TODO BlueZGattCharacteristicFlag.encryptWrite,
  // TODO BlueZGattCharacteristicFlag.encryptAuthenticatedRead,
  // TODO BlueZGattCharacteristicFlag.encryptAuthenticatedWrite,
  //      TODO BlueZGattCharacteristicFlag.secureRead: bleProperty,
  BleCharacteristicPropertyFlag.secureWrite: blePropertySignedWrite,
  // TODO BlueZGattCharacteristicFlag.authorize,
};

int propertyFlagsToPropertyValue(Set<BleCharacteristicPropertyFlag> flags) {
  var properties = 0;
  for (var flag in flags) {
    properties |= _propertyFlagToPropertyValue(flag);
  }
  return properties;
}
