import 'package:tekartik_bluetooth/uuid.dart';

String uuidText(Uuid128? uuid, {Uuid128? parent}) {
  if (uuid == null) {
    return 'no uuid';
  }
  if (parent != null) {
    if (uuid.withUuid16(Uuid16.fromValue(0)) ==
        parent.withUuid16(Uuid16.fromValue(0))) {
      return '0x${uuid.shortNumberUuid16.toString()}';
    }
  }
  return uuid.toString();
}
