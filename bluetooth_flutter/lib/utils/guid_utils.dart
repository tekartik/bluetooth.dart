import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter.dart';

Guid guidFromUuid(Uuid128 uuid) {
  return Guid(uuid.toString());
}

Uuid128 uuidFromGuid(Guid guid) {
  return Uuid128(guid.toString());
}
