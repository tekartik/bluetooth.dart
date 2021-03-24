import 'dart:typed_data';

import 'package:tekartik_common_utils/byte_data_utils.dart';
import 'package:tekartik_common_utils/hex_utils.dart';

Uint8List uint16GetBytes(int value) {
  var data = ByteData(2);
  data.setUint16(0, value);
  return byteDataToUint8List(data);
}

Uint8List uint32GetBytes(int value) {
  var data = ByteData(4);
  data.setUint32(0, value);
  return byteDataToUint8List(data);
}

int bytesGetUint16(Uint8List bytes) {
  var data = byteDataFromUint8List(bytes);
  return data.getUint16(0);
}

int bytesGetUint32(Uint8List bytes) {
  var data = byteDataFromUint8List(bytes);
  return data.getUint32(0);
}

/// Lower case string from a value
String uint16GetString(int value) => toLowerHexString(uint16GetBytes(value));

String toLowerHexString(List<int> data) {
  return toHexString(data)!.toLowerCase();
}
