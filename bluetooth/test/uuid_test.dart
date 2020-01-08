import 'dart:typed_data';

import 'package:tekartik_bluetooth/uuid.dart';
import 'package:test/test.dart';

void main() {
  group('uuid', () {
    test('Uuid16', () {
      var uuid16 = Uuid16.fromText('123a');
      expect(uuid16.bytes, [18, 58]);
      expect(uuid16.toString(), '123a');

      expect(uuid16, Uuid16.fromBytes(Uint8List.fromList([18, 58])));
      expect(uuid16, Uuid16.fromValue(0x123a));
      expect(uuid16, isNot(Uuid16.fromValue(0x123b)));
    });
    test('Uuid128', () {
      var uuid128 = Uuid128('36c9159b-6cc6-43b3-b198-ac03cc44949e');
      expect(uuid128.bytes, [
        54,
        201,
        21,
        155,
        108,
        198,
        67,
        179,
        177,
        152,
        172,
        3,
        204,
        68,
        148,
        158
      ]);
      expect(uuid128.toString(), '36c9159b-6cc6-43b3-b198-ac03cc44949e');

      var uuid16 = Uuid16.fromValue(0x1234);
      var uuid128WithUuid16 = uuid128.withUuid16(uuid16);
      expect(uuid128WithUuid16.bytes, [
        54,
        201,
        18,
        52,
        108,
        198,
        67,
        179,
        177,
        152,
        172,
        3,
        204,
        68,
        148,
        158
      ]);
      expect(
          uuid128WithUuid16.toString(), '36c91234-6cc6-43b3-b198-ac03cc44949e');

      var uuid32 = Uuid32('1234abCd');
      var uuid128WithUuid32 = uuid128.withUuid32(uuid32);
      expect(uuid128WithUuid32.bytes, [
        18,
        52,
        171,
        205,
        108,
        198,
        67,
        179,
        177,
        152,
        172,
        3,
        204,
        68,
        148,
        158
      ]);
      expect(
          uuid128WithUuid32.toString(), '1234abcd-6cc6-43b3-b198-ac03cc44949e');

      expect(uuid128WithUuid32.shortNumberUuid16.toString(), 'abcd');
      expect(uuid128WithUuid32.longNumberUuid32.toString(), '1234abcd');
    });
  });
}
