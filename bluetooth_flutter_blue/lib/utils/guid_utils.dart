import 'package:flutter_blue/flutter_blue.dart';
import 'package:tekartik_bluetooth/uuid.dart';

Guid guidFromUuid(Uuid128 uuid) {
  return Guid(uuid.toString());
}

Uuid128 uuidFromGuid(Guid guid) {
  return Uuid128(guid.toString());
}
