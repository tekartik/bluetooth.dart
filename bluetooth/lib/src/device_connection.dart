import 'package:tekartik_bluetooth/bluetooth_manager.dart';

import 'ble.dart';
import 'import.dart';

/// The profile is in disconnected state
const int bluetoothDeviceConnectionStateDisconnected = 0;

/// The profile is in connecting state
const int bluetoothDeviceConnectionStateConnecting = 1;

/// The profile is in connected state
const int bluetoothDeviceConnectionStateConnected = 2;

/// The profile is in disconnecting state
const int bluetoothDeviceConnectionStateDisconnecting = 3;

/// The profile is in unknown state
const int bluetoothDeviceConnectionStateUnknown = 4;

class BluetoothDeviceConnectionState {
  final int state;
  const BluetoothDeviceConnectionState(this.state);
  static const disconnected = BluetoothDeviceConnectionState(
      bluetoothDeviceConnectionStateDisconnected);
  static const connecting =
      BluetoothDeviceConnectionState(bluetoothDeviceConnectionStateConnecting);
  static const connected =
      BluetoothDeviceConnectionState(bluetoothDeviceConnectionStateConnected);
  static const disconnecting = BluetoothDeviceConnectionState(
      bluetoothDeviceConnectionStateDisconnecting);
  static const unknown =
      BluetoothDeviceConnectionState(bluetoothDeviceConnectionStateUnknown);

  @override
  int get hashCode => state;

  @override
  bool operator ==(Object other) {
    if (other is BluetoothDeviceConnectionState) {
      return other.state == state;
    }
    return false;
  }

  @override
  String toString() {
    switch (state) {
      case bluetoothDeviceConnectionStateDisconnected:
        return 'State.disconnected';
      case bluetoothDeviceConnectionStateDisconnecting:
        return 'State.disconnecting';
      case bluetoothDeviceConnectionStateConnected:
        return 'State.connected';
      case bluetoothDeviceConnectionStateConnecting:
        return 'State.connecting';
      case bluetoothDeviceConnectionStateUnknown:
        return 'State.unknown';
      default:
        return 'State.other';
    }
  }
}

abstract class BluetoothDeviceConnection {
  Future discoverServices();

  Future<List<BleBluetoothService>> getServices();

  /// Connect
  Stream<BluetoothDeviceConnectionState> get onConnectionState;

  /// Return of throw
  Future connect();

  Future<BleBluetoothCharacteristicValue> readCharacteristic(
      BleBluetoothCharacteristic characteristic);

  Future disconnect();

  /// Dispose everything
  void close();
}

class BluetoothDeviceConnectionImpl implements BluetoothDeviceConnection {
  final BluetoothManager manager;
  final int connectionId;

  BluetoothDeviceConnectionImpl(
      {@required this.manager, @required this.connectionId});
  @override
  void close() {
    // TODO: implement close
  }

  @override
  Future connect() {
    // TODO: implement connect
    throw UnimplementedError();
  }

  @override
  Future disconnect() {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  Future discoverServices() {
    // TODO: implement discoverServices
    throw UnimplementedError();
  }

  @override
  Future<List<BleBluetoothService>> getServices() {
    // TODO: implement getServices
    throw UnimplementedError();
  }

  @override
  // TODO: implement onConnectionState
  Stream<BluetoothDeviceConnectionState> get onConnectionState =>
      throw UnimplementedError();

  @override
  Future<BleBluetoothCharacteristicValue> readCharacteristic(
      BleBluetoothCharacteristic characteristic) {
    // TODO: implement readCharacteristic
    throw UnimplementedError();
  }
}
