import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_common_utils/hex_utils.dart';

/// A ble bluetooth service
class BleBluetoothService {
  final Uuid128 uuid;

  List<BleBluetoothCharacteristic> _characteristics;

  /// Modifiable
  List<BleBluetoothCharacteristic> get characteristics => _characteristics;

  /// Deprecate for safety only
  @protected
  set characteristics(List<BleBluetoothCharacteristic> characteristics) =>
      _characteristics = characteristics;

  BleBluetoothService(
      {@required this.uuid, List<BleBluetoothCharacteristic> characteristics})
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

abstract class BleBluetoothCharacteristic {
  BleBluetoothService get service;

  Uuid128 get uuid;
  int get properties;
  List<BleBluetoothDescriptor> get descriptors;

  factory BleBluetoothCharacteristic(
          {@required BleBluetoothService service,
          @required Uuid128 uuid,
          int properties,
          List<BleBluetoothDescriptor> descriptors}) =>
      BleBluetoothCharacteristicImpl(
          service: service, uuid: uuid, properties: properties);

  BleBluetoothCharacteristicValue withValue(Uint8List value);

  int get shortNumber;
}

/// Descriptor definition
class BleBluetoothDescriptor {
  final BleBluetoothCharacteristic characteristic;
  final Uuid128 uuid;

  BleBluetoothDescriptor({this.characteristic, this.uuid});
}

abstract class BleBluetoothCharacteristicValue {
  BleBluetoothService get service;

  Uuid128 get uuid;
  Uint8List get value;

  BleBluetoothCharacteristic get bc;

  /// Best usage is to use [bc] and [value]
  factory BleBluetoothCharacteristicValue(
          {BleBluetoothService service,
          Uuid128 uuid,
          BleBluetoothCharacteristic bc,
          @required Uint8List value}) =>
      BleBluetoothCharacteristicValueImpl(
          bc: bc ?? BleBluetoothCharacteristic(service: service, uuid: uuid),
          value: value ?? Uint8List(0));
}

mixin BleBluetoothCharacteristicMixin implements BleBluetoothCharacteristic {
  BleBluetoothService _service;
  Uuid128 _uuid;
  int _properties;
  @override
  List<BleBluetoothDescriptor> descriptors;

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
  BleBluetoothCharacteristic _bc;
  Uint8List _value;
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
    return '$uuid value ${value == null ? value : toHexString(value)}';
  }
}

class BleBluetoothCharacteristicImpl
    with BleBluetoothCharacteristicMixin
    implements BleBluetoothCharacteristic {
  BleBluetoothCharacteristicImpl(
      {BleBluetoothService service, Uuid128 uuid, int properties}) {
    _service = service;
    _uuid = uuid;
    _properties = properties;
  }
}

class BleBluetoothCharacteristicValueImpl
    with BleBluetoothCharacteristicValueMixin
    implements BleBluetoothCharacteristicValue {
  BleBluetoothCharacteristicValueImpl(
      {BleBluetoothCharacteristic bc, Uint8List value}) {
    _bc = bc;
    _value = value;
  }
}
