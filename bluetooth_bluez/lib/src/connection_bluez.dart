import 'dart:async';

import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_bluez/src/bluez_uuid_utils.dart';
import 'package:tekartik_bluetooth_bluez/src/scan_bluez.dart';

import 'import.dart';

abstract class BluetoothDeviceConnectionBluez
    extends BluetoothDeviceConnection {}

class BluetoothDeviceConnectionBluezImpl
    extends BluetoothDeviceConnectionBluez {
  final BluetoothDeviceBluezImpl device;
  StreamController<BluetoothDeviceConnectionState>? _connectionStateController;

  BluetoothDeviceConnectionBluezImpl(this.device);
  @override
  void close() {
    // TODO: implement close
  }

  @override
  Future<void> connect() async {
    var deviceBluez = device.blueZDevice;
    // Create controller
    onConnectionState;
    _connectionStateController!.sink
        .add(BluetoothDeviceConnectionState.connecting);
    try {
      if (!deviceBluez.connected) {
        try {
          await deviceBluez.connect();
        } catch (e) {
          if (!deviceBluez.connected) {
            rethrow;
          }
        }
      }
    } finally {
      _checkState();
    }
  }

  @override
  Future disconnect() async {
    var deviceBluez = device.blueZDevice;
    _connectionStateController!.sink
        .add(BluetoothDeviceConnectionState.disconnecting);
    try {
      await deviceBluez.disconnect();
      // Create controller
      onConnectionState;
    } finally {
      _checkState();
    }
  }

  void _checkState() {
    var deviceBluez = device.blueZDevice;
    _connectionStateController!.sink.add(deviceBluez.connected
        ? BluetoothDeviceConnectionState.connected
        : BluetoothDeviceConnectionState.disconnected);
  }

  @override
  Future discoverServices() async {
    // Ok already available
    // var deviceBluez = device.blueZDevice;
  }

  @override
  Future<List<BleBluetoothService>> getServices() async {
    var deviceBluez = device.blueZDevice;
    var services = deviceBluez.gattServices.map((gattService) {
      var uuid = uuidFromBluezUuid(gattService.uuid);
      var service = BleBluetoothService(uuid: uuid);
      // ignore: invalid_use_of_protected_member
      service.characteristics =
          gattService.characteristics.map((gattCharacteristic) {
        var characteristic = BleBluetoothCharacteristic(
            service: service, uuid: uuidFromBluezUuid(gattCharacteristic.uuid));

        var descriptors = gattCharacteristic.descriptors.map((gattDescriptor) {
          var descriptor = BleBluetoothDescriptor(
              characteristic: characteristic,
              uuid: uuidFromBluezUuid(gattDescriptor.uuid));
          return descriptor;
        }).toList();
        // ignore: invalid_use_of_protected_member
        characteristic.descriptors = descriptors;
        return characteristic;
      }).toList();
      return service;
    }).toList();
    return services;
  }

  @override
  // TODO: implement onConnectionState
  Stream<BluetoothDeviceConnectionState> get onConnectionState {
    _connectionStateController ??= StreamController.broadcast(onListen: () {
      _checkState();
    });
    return _connectionStateController!.stream;
  }

  @override
  Future<BleBluetoothCharacteristicValue> readCharacteristic(
      BleBluetoothCharacteristic characteristic) {
    // TODO: implement readCharacteristic
    throw UnimplementedError();
  }
}
