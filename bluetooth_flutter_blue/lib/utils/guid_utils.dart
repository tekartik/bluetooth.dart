import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter_blue/src/flutter_blue_import.dart';

export 'package:tekartik_bluetooth_flutter_blue/src/flutter_blue_import.dart'
    show Guid;

/// The flutter_blue_plus [Guid] of [uuid].
Guid guidFromUuid(Uuid128 uuid) {
  return Guid(uuid.toString());
}

/// The 128 bit uuid of [guid] (a 16 or 32 bit one expanded on the Bluetooth
/// base uuid).
Uuid128 uuidFromGuid(Guid guid) {
  // Not guid.toString(): the shortest form ('180f' for a 16 bit uuid), that
  // Uuid128 would read as 180f0000-0000-0000-0000-000000000000.
  return Uuid128(guid.str128);
}
