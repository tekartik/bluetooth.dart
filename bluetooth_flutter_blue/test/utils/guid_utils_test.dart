import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter_blue/utils/guid_utils.dart';

void main() {
  group('guid', () {
    test('uuid', () {
      var guid = Guid.empty();
      var uuid = uuidFromGuid(guid);
      expect(guid.toString(), uuid.toString());
      expect(guid, guidFromUuid(uuid));
    });

    test('16 and 32 bit uuids', () {
      // flutter_blue_plus gives the shortest form in Guid.toString() ('180f').
      for (var text in [
        '0000180f-0000-1000-8000-00805f9b34fb', // battery service
        '00002a19-0000-1000-8000-00805f9b34fb', // battery level
        '12345678-0000-1000-8000-00805f9b34fb', // 32 bit
        '6e400001-b5a3-f393-e0a9-e50e24dcca9e', // vendor 128 bit
      ]) {
        var expected = Uuid128(text);
        var uuid = uuidFromGuid(Guid(text));
        expect(uuid, expected, reason: text);
        expect(uuid.toString(), text);
        expect(guidFromUuid(uuid), Guid(text));
      }
      expect(uuidFromGuid(Guid('180f')).shortNumberUuid16.value, 0x180f);
    });
  });
}
