// 16 bit uuid
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:tekartik_bluetooth/utils/byte_utils.dart';
import 'package:tekartik_common_utils/hex_utils.dart';
import 'package:uuid/uuid.dart';

/// https://www.real-world-systems.com/docs/GUIDs.html
/// It does not appear to be an RFC4122 compliant UUID: The first character
/// after the second - in your UUID is a d. However valid UUIDs have the
/// version number at this position which must be one of 1, 3, 4, 5.
class Uuid16 {
  final Uint8List bytes;
  String? _text;

  Uuid16.fromText(String text)
      : _text = text,
        bytes = Uint8List.fromList(parseHexString(text));

  Uuid16.fromBytes(this.bytes);

  Uuid16.fromValue(int value) : bytes = uint16GetBytes(value);

  @Deprecated('Use proper init')
  Uuid16.from({Uint8List? bytes, int? value})
      : bytes = bytes ?? uint16GetBytes(value!);

  @Deprecated('Use Uuid16.fromText')
  Uuid16(String text)
      : _text = text,
        bytes = Uint8List.fromList(parseHexString(text));

  // The number
  int get value {
    var byteData = ByteData.view(bytes.buffer);
    return byteData.getUint16(0);
  }

  @override
  int get hashCode => value;

  @override
  bool operator ==(other) {
    if (other is Uuid16) {
      return other.value == value;
    }
    return false;
  }

  @override
  String toString() => _text ??= toHexString(bytes)!.toLowerCase();
}

// 16 bit uuid
class Uuid32 {
  final Uint8List bytes;
  String? _text;

  Uuid32.fromBytes({required this.bytes});

  @Deprecated('Use fromBytes')
  Uuid32.from({required this.bytes});

  Uuid32(String text)
      : _text = text,
        bytes = Uint8List.fromList(parseHexString(text));

  @override
  String toString() => _text ??= toHexString(bytes)!.toLowerCase();
}

// 128 bit uuid - 16 bytes
class Uuid128 {
  final Uint8List _value;
  String? _text;

  Uuid128.from({Uint8List? bytes, String? text})
      : _value = bytes ?? Uint8List.fromList(Uuid.parse(text!)),
        _text = text;

  /// 16 bytes
  Uuid128.bytes(Uint8List bytes) : _value = bytes;

  Uuid128(String text)
      : _text = text,
        _value = Uint8List.fromList(Uuid.parse(text,
            validate: false, validationMode: ValidationMode.nonStrict));

  /// 16 bytes
  Uint8List get bytes => _value;

  Uuid128 withUuid16(Uuid16 uuid16) {
    var list = Uint8List.fromList(_value);
    list[2] = uuid16.bytes[0];
    list[3] = uuid16.bytes[1];
    return Uuid128.from(bytes: list);
  }

  Uuid128 withUuid32(Uuid32 uuid32) {
    var list = Uint8List.fromList(_value);
    for (var i = 0; i < 4; i++) {
      list[i] = uuid32.bytes[i];
    }
    return Uuid128.from(bytes: list);
  }

  Uuid16 get shortNumberUuid16 =>
      Uuid16.fromBytes(Uint8List.fromList(bytes.sublist(2, 4)));

  @Deprecated('user shortNumberUuid16')
  Uuid16 get serviceUuid16 => shortNumberUuid16;

  Uuid16 get longNumberUuid32 =>
      Uuid16.fromBytes(Uint8List.fromList(bytes.sublist(0, 4)));

  @Deprecated('user longNumberUuid32')
  Uuid16 get serviceUuid32 => longNumberUuid32;

  @override
  String toString() => _text ??= Uuid.unparse(_value);

  @override
  int get hashCode => _value[2] + _value[3];

  @override
  bool operator ==(other) {
    if (other is Uuid128) {
      return const ListEquality<int>().equals(_value, other._value);
    }
    return false;
  }
}
