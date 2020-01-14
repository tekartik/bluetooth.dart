import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter/src/plugin.dart';
import 'package:tekartik_common_utils/bool_utils.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/hex_utils.dart';

export 'package:tekartik_bluetooth/bluetooth.dart';
export 'package:tekartik_bluetooth/bluetooth_state_service.dart';

class BluetoothFlutterSlaveConnection {
  bool connected;
  String address;

  void fromMap(Map map) {
    address = map['address']?.toString();
    connected = parseBool(map['connected']) == true;
  }
}

class BluetoothGattCharacteristic {
  final Uuid128 uuid;

  final String description;

  /// Characteristic proprty: Characteristic is broadcastable.
  static final int propertyBroadcast = 0x01;

  /// Characteristic property: Characteristic is readable.
  static final int propertyRead = 0x02;

  /// Characteristic property: Characteristic can be written without response.
  static final int propertyWriteNoResponse = 0x04;

  /// Characteristic property: Characteristic can be written.
  static final int propertyWrite = 0x08;

  /// Characteristic property: Characteristic supports notification
  static final int propertyNotify = 0x10;

  /// Characteristic property: Characteristic supports indication
  static final int propertyIndicate = 0x20;

  /// Characteristic property: Characteristic supports write with signature
  static final int propertySignedWrite = 0x40;

  /// Characteristic property: Characteristic has extended properties
  static final int propertyExtendedProps = 0x80;

  /// Characteristic read permission
  static final int permissionRead = 0x01;

  /// Characteristic permission: Allow encrypted read operations
  static final int permissionReadEncrypted = 0x02;

  /// Characteristic permission: Allow reading with man-in-the-middle protection
  static final int permissionReadEncryptedMitm = 0x04;

  /// Characteristic write permission
  static final int permissionWrite = 0x10;

  /// Characteristic permission: Allow encrypted writes
  static final int permissionWriteEncrypted = 0x20;

  /// Characteristic permission: Allow encrypted writes with man-in-the-middle
  /// protection
  static final int permissionWriteEncryptedMitm = 0x40;

  /// Characteristic permission: Allow signed write operations
  static final int permissionsWriteSigned = 0x80;

  /// Characteristic permission: Allow signed write operations with
  /// man-in-the-middle protection
  static final int permissionWriteSignedMitm = 0x100;

  final int properties;
  final int permissions;

  BluetoothGattCharacteristic(
      {@required this.uuid,
      @required this.properties,
      @required this.permissions,
      this.description});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'properties': properties,
      'permissions': permissions,
      'uuid': uuid.toString(),
      if (description != null) 'description': description
    };
    return map;
  }
}

class BluetoothGattService {
  final Uuid128 uuid;

  final List<BluetoothGattCharacteristic> characteristics;

  BluetoothGattService({@required this.uuid, this.characteristics});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{'uuid': uuid.toString()};
    if (characteristics != null) {
      map['characteristics'] = characteristics
          .map((characteristic) => characteristic.toMap())
          .toList(growable: false);
    }
    return map;
  }
}

class AdvertiseDataService {
  final Uuid128 uuid;

  AdvertiseDataService({this.uuid});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{'uuid': uuid.toString()};
    return map;
  }
}

class AdvertiseData {
  final List<AdvertiseDataService> services;

  AdvertiseData({this.services});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    if (services != null) {
      map['services'] =
          services.map((service) => service.toMap()).toList(growable: false);
    }
    // devPrint(map);
    return map;
  }
}

class BluetoothPeripheralWriteCharacteristicEvent {
  Uuid128 serviceUuid;
  Uuid128 characteristicUuid;
  Uint8List value;

  void fromMap(Map map) {
    serviceUuid = Uuid128(map['service']?.toString());
    characteristicUuid = Uuid128(map['characteristic']?.toString());
    value = map['value'] as Uint8List;
  }

  @override
  String toString() =>
      '$serviceUuid ${characteristicUuid} ${value != null ? toHexString(value) : null}';
}

class BluetoothPeripheral {
  final List<BluetoothGattService> services;
  String deviceName;

  BluetoothPeripheral({this.services, this.deviceName});

  Map toMap() {
    var map = {};
    if (services != null) {
      map['services'] =
          services.map((service) => service.toMap()).toList(growable: false);
    }
    if (deviceName != null) {
      map['deviceName'] = deviceName;
    }
    return map;
  }

  /// Occurs when a bluetooth master connection has changed (there can be multiple)
  Stream<BluetoothFlutterSlaveConnection> onSlaveConnectionChanged() {
    return bluetoothFlutterPlugin.connectionChannel
        .receiveBroadcastStream()
        .map((buffer) =>
            BluetoothFlutterSlaveConnection()..fromMap(buffer as Map));
  }

  /// Occurs when a write occurs
  Stream<BluetoothPeripheralWriteCharacteristicEvent> onWriteCharacteristic() {
    return bluetoothFlutterPlugin.writeCharacteristicChannel
        .receiveBroadcastStream()
        .map((buffer) => BluetoothPeripheralWriteCharacteristicEvent()
          ..fromMap(buffer as Map));
  }

  Future setCharacteristicValue(
      {@required Uuid128 serviceUuid,
      @required Uuid128 characteristicUuid,
      @required Uint8List value}) async {
    await bluetoothFlutterPlugin.methodChannel
        .invokeMethod('peripheralSetCharacteristicValue', {
      'service': serviceUuid.toString(),
      'characteristic': characteristicUuid.toString(),
      'value': value
    });
  }

  //TODO check if value should be passed here...
  Future notifyCharacteristicValue(
      {@required Uuid128 serviceUuid,
      @required Uuid128 characteristicUuid}) async {
    await bluetoothFlutterPlugin.methodChannel
        .invokeMethod('peripheralNotifyCharacteristicValue', {
      'service': serviceUuid.toString(),
      'characteristic': characteristicUuid.toString(),
    });
  }

  Future<Uint8List> getCharacteristicValue({
    @required Uuid128 serviceUuid,
    @required Uuid128 characteristicUuid,
  }) async {
    Uint8List bytes = (await bluetoothFlutterPlugin.methodChannel
        .invokeMethod('peripheralGetCharacteristicValue', {
      'service': serviceUuid.toString(),
      'characteristic': characteristicUuid.toString(),
    })) as Uint8List;
    return bytes;
  }
}
