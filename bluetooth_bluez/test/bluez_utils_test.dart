import 'package:bluez/bluez.dart';
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_bluez/src/bluez_utils.dart';
import 'package:test/test.dart';

void main() {
  test('bluezUuidTo/FromUuid', () {
    var uuid = Uuid128('6ba7b810-9dad-11d1-80b4-00c04fd430c8');
    expect(uuidFromBluezUuid(bluezUuidFromUuid(uuid)), uuid);
  });
  test('bluezFlagToProperty', () {
    expect(
      bluezFlagToProperty(
        BlueZGattCharacteristicFlag.authenticatedSignedWrites,
      ),
      blePropertySignedWrite,
    );
    expect(
      bluezFlagToProperty(BlueZGattCharacteristicFlag.read),
      blePropertyRead,
    );
    // No property bit for a secure write
    expect(bluezFlagToProperty(BlueZGattCharacteristicFlag.secureWrite), 0);
    expect(
      bluezFlagsToProperties({
        BlueZGattCharacteristicFlag.read,
        BlueZGattCharacteristicFlag.notify,
      }),
      blePropertyRead | blePropertyNotify,
    );
  });
}
