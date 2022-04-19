import 'package:tekartik_bluetooth_test_app/import/import_bluetooth.dart';

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

String propertiesAsText(int properties) {
  var canRead = (properties & blePropertyRead) != 0;
  var canWrite = (properties & blePropertyWrite) != 0;

  bool checkFlag(int flag) {
    return (properties & flag) != 0;
  }

  var canNotify = checkFlag(blePropertyNotify);

  var sb = StringBuffer();
  void _addPropertyText(String text, bool test) {
    if (test) {
      if (sb.isNotEmpty) {
        sb.write(', ');
      }
      sb.write(text);
    }
  }

  _addPropertyText('read', canRead);
  _addPropertyText('write', canWrite);
  _addPropertyText('notify', canNotify);
  _addPropertyText('indicate', checkFlag(blePropertyIndicate));
  _addPropertyText('broadcast', checkFlag(blePropertyBroadcast));
  _addPropertyText('writeNoResponse', checkFlag(blePropertyWriteNoResponse));
  _addPropertyText('signedWrite', checkFlag(blePropertySignedWrite));
  _addPropertyText('extendedProps', checkFlag(blePropertyExtendedProps));

  return sb.toString();
}
