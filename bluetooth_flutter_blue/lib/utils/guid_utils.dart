import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter_blue/src/flutter_blue_import.dart';

export 'package:tekartik_bluetooth_flutter_blue/src/flutter_blue_import.dart'
    show Guid;

Guid guidFromUuid(Uuid128 uuid) {
  return Guid(uuid.toString());
}

Uuid128 uuidFromGuid(Guid guid) {
  return Uuid128(guid.toString());
}
