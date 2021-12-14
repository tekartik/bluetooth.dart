import 'package:bluez/bluez.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_common_utils/byte_utils.dart';

BlueZUUID bluezUuidFromUuid(Uuid128 uuid) {
  return BlueZUUID(uuid.bytes);
}

Uuid128 uuidFromBluezUuid(BlueZUUID bluezUuid) {
  return Uuid128.bytes(asUint8List(bluezUuid.value));
}
