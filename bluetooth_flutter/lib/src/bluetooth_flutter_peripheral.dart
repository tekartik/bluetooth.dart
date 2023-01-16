import 'dart:typed_data';

import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter/src/plugin.dart';

class BluetoothFlutterPeripheral {
  final List<BluetoothGattService>? services;
  String? deviceName;

  BluetoothFlutterPeripheral({this.services, this.deviceName});

  Map<String, Object?> toMap() {
    var map = <String, Object?>{};
    if (services != null) {
      map['services'] =
          services!.map((service) => service.toMap()).toList(growable: false);
    }
    if (deviceName != null) {
      map['deviceName'] = deviceName;
    }
    return map;
  }

  /// Occurs when a bluetooth master connection has changed (there can be multiple)
  Stream<BluetoothSlaveConnection> onSlaveConnectionChanged() {
    return bluetoothFlutterPlugin.connectionChannel
        .receiveBroadcastStream()
        .map((buffer) => BluetoothSlaveConnection()..fromMap(buffer as Map));
  }

  /// Occurs when a write occurs
  Stream<BluetoothPeripheralWriteCharacteristicEvent> onWriteCharacteristic() {
    return bluetoothFlutterPlugin.writeCharacteristicChannel
        .receiveBroadcastStream()
        .map((buffer) => BluetoothPeripheralWriteCharacteristicEvent()
          ..fromMap(buffer as Map));
  }

  Future setCharacteristicValue(
      {required Uuid128 serviceUuid,
      required Uuid128 characteristicUuid,
      required Uint8List value}) async {
    await bluetoothFlutterPlugin.methodChannel
        .invokeMethod('peripheralSetCharacteristicValue', {
      'service': serviceUuid.toString(),
      'characteristic': characteristicUuid.toString(),
      'value': value
    });
  }

  //TODO check if value should be passed here...
  Future notifyCharacteristicValue(
      {required Uuid128 serviceUuid,
      required Uuid128 characteristicUuid}) async {
    await bluetoothFlutterPlugin.methodChannel
        .invokeMethod('peripheralNotifyCharacteristicValue', {
      'service': serviceUuid.toString(),
      'characteristic': characteristicUuid.toString(),
    });
  }

  Future<Uint8List?> getCharacteristicValue({
    required Uuid128 serviceUuid,
    required Uuid128 characteristicUuid,
  }) async {
    var bytes = (await bluetoothFlutterPlugin.methodChannel
        .invokeMethod('peripheralGetCharacteristicValue', {
      'service': serviceUuid.toString(),
      'characteristic': characteristicUuid.toString(),
    })) as Uint8List?;
    return bytes;
  }
}
