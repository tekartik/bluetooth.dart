import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_common_utils/hex_utils.dart';

/// A ble bluetooth service
class BleBluetoothService {
  final Uuid128 uuid;

  List<BleBluetoothCharacteristic>? _characteristics;

  /// Modifiable
  List<BleBluetoothCharacteristic>? get characteristics => _characteristics;

  /// Deprecate for safety only
  @protected
  set characteristics(List<BleBluetoothCharacteristic>? characteristics) =>
      _characteristics = characteristics;

  BleBluetoothService(
      {required this.uuid, List<BleBluetoothCharacteristic>? characteristics})
      : _characteristics = characteristics;

  @override
  int get hashCode => uuid.hashCode;

  @override
  bool operator ==(other) {
    if (other is BleBluetoothService) {
      return (other.uuid == uuid);
    }
    return false;
  }

  int get shortNumber => uuid.shortNumberUuid16.value;
}

/// Ble characteristic
abstract class BleBluetoothCharacteristic {
  BleBluetoothService get service;

  Uuid128 get uuid;
  int get properties;
  List<BleBluetoothDescriptor> get descriptors;

  factory BleBluetoothCharacteristic(
          {required BleBluetoothService service,
          required Uuid128 uuid,

          /// No properties by default
          int properties = 0x0,
          List<BleBluetoothDescriptor>? descriptors}) =>
      BleBluetoothCharacteristicImpl(
          service: service, uuid: uuid, properties: properties);

  BleBluetoothCharacteristicValue withValue(Uint8List value);

  int get shortNumber;
}

/// Descriptor definition
class BleBluetoothDescriptor {
  final BleBluetoothCharacteristic characteristic;
  final Uuid128 uuid;

  BleBluetoothDescriptor({required this.characteristic, required this.uuid});
}

abstract class BleBluetoothCharacteristicValue {
  BleBluetoothService get service;

  Uuid128 get uuid;
  Uint8List get value;

  BleBluetoothCharacteristic get bc;

  /// Best usage is to use [bc] and [value]
  factory BleBluetoothCharacteristicValue(
      {

      /// Needed if bc is null
      BleBluetoothService? service,

      /// Needed if bc is null
      Uuid128? uuid,
      BleBluetoothCharacteristic? bc,
      required Uint8List value}) {
    if (bc == null) {
      if (service == null) {
        throw ArgumentError.notNull('service');
      }
      if (uuid == null) {
        throw ArgumentError.notNull('uuid');
      }
    }
    return BleBluetoothCharacteristicValueImpl(
        bc: bc ?? BleBluetoothCharacteristic(service: service!, uuid: uuid!),
        value: value);
  }
}

mixin BleBluetoothCharacteristicMixin implements BleBluetoothCharacteristic {
  late BleBluetoothService _service;
  late Uuid128 _uuid;
  late int _properties;

  @override
  late List<BleBluetoothDescriptor> descriptors;

  @override
  BleBluetoothService get service => _service;
  @override
  Uuid128 get uuid => _uuid;

  @override
  int get properties => _properties;

  @override
  int get hashCode => uuid.hashCode;

  @override
  bool operator ==(other) {
    if (other is BleBluetoothCharacteristicMixin) {
      return (other.service == service) && (other.uuid == uuid);
    }
    return false;
  }

  @override
  String toString() {
    return '$uuid';
  }

  @override
  BleBluetoothCharacteristicValue withValue(Uint8List value) =>
      BleBluetoothCharacteristicValue(bc: this, value: value);

  @override
  int get shortNumber => uuid.shortNumberUuid16.value;
}

mixin BleBluetoothCharacteristicValueMixin
    implements BleBluetoothCharacteristicValue {
  late BleBluetoothCharacteristic _bc;
  late Uint8List _value;
  @override
  Uint8List get value => _value;

  @override
  BleBluetoothCharacteristic get bc => _bc;

  @override
  BleBluetoothService get service => bc.service;

  @override
  Uuid128 get uuid => bc.uuid;

  @override
  String toString() {
    return '$uuid value ${toHexString(value)}';
  }
}

class BleBluetoothCharacteristicImpl
    with BleBluetoothCharacteristicMixin
    implements BleBluetoothCharacteristic {
  BleBluetoothCharacteristicImpl(
      {required BleBluetoothService service,
      required Uuid128 uuid,
      required int properties,
      List<BleBluetoothDescriptor>? descriptors}) {
    _service = service;
    _uuid = uuid;
    _properties = properties;
  }
}

class BleBluetoothCharacteristicValueImpl
    with BleBluetoothCharacteristicValueMixin
    implements BleBluetoothCharacteristicValue {
  BleBluetoothCharacteristicValueImpl(
      {required BleBluetoothCharacteristic bc, required Uint8List value}) {
    _bc = bc;
    _value = value;
  }
}
