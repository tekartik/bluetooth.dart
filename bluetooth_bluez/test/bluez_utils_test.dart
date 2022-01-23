import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_bluez/src/bluez_utils.dart';
import 'package:test/test.dart';

void main() {
  test('bluezUuidTo/FromUuid', () {
    var uuid = Uuid128('6ba7b810-9dad-11d1-80b4-00c04fd430c8');
    expect(uuidFromBluezUuid(bluezUuidFromUuid(uuid)), uuid);
  });
}
