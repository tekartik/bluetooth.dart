import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_bluetooth_flutter_blue/utils/guid_utils.dart';

void main() {
  group('guid', () {
    test('uuid', () {
      var guid = Guid.empty();
      var uuid = uuidFromGuid(guid);
      expect(guid.toString(), uuid.toString());
      expect(guid, guidFromUuid(uuid));
    });
  });
}
