import 'dart:async';

import 'package:tekartik_bluetooth_web/src/import_bluetooth.dart';
import 'package:tekartik_bluetooth_web/src/import_bluetooth_web.dart' as web;

class BluetoothDeviceConnectionWeb
    with BluetoothDeviceConnectionMixin
    implements BluetoothDeviceConnection {
  final web.BluetoothDevice nativeDevice;

  final onStateController =
      StreamController<BluetoothDeviceConnectionState>.broadcast();
  BluetoothDeviceConnectionWeb(this.nativeDevice);
  @override
  void close() {
    // TODO: implement close
  }

  @override
  Future<void> connect() async {
    onStateController.add(BluetoothDeviceConnectionState.connecting);
    try {
      await nativeDevice.connect();
      onStateController.add(BluetoothDeviceConnectionState.connected);
    } catch (e) {
      onStateController.add(BluetoothDeviceConnectionState.disconnected);
    }
  }

  @override
  Future<void> disconnect() async {
    onStateController.add(BluetoothDeviceConnectionState.disconnecting);
    try {
      nativeDevice.disconnect();
    } finally {
      onStateController.add(BluetoothDeviceConnectionState.disconnected);
    }
  }

  List<BleBluetoothService>? services;
  @override
  Future<void> discoverServices() async {
    // var nativeServices = nativeDevice.services.first;
    // TODO: implement discoverServices
    throw UnimplementedError('discoverServices');
  }

  @override
  Future<List<BleBluetoothService>> getServices() {
    // TODO: implement getServices
    throw UnimplementedError('getServices');
  }

  @override
  // TODO: implement onConnectionState
  Stream<BluetoothDeviceConnectionState> get onConnectionState =>
      onStateController.stream;

  @override
  Future<BleBluetoothCharacteristicValue> readCharacteristic(
    BleBluetoothCharacteristic characteristic,
  ) {
    // TODO: implement readCharacteristic
    throw UnimplementedError('readCharacteristic');
  }

  @override
  Future<void> writeCharacteristic(
    BleBluetoothCharacteristicValue characteristicValue,
  ) {
    // TODO: implement writeCharacteristic
    throw UnimplementedError('writeCharacteristic');
  }
}
