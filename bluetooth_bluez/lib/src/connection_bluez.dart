import 'dart:async';

import 'package:bluez/bluez.dart';
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_bluez/src/bluez_uuid_utils.dart';
import 'package:tekartik_bluetooth_bluez/src/scan_bluez.dart';
import 'package:tekartik_common_utils/byte_utils.dart';

import 'import.dart';

abstract class BluetoothDeviceConnectionBluez
    extends BluetoothDeviceConnection {}

/// Cached service info
class _BluezServices {
  final List<BlueZGattService> bluezServices;

  /// The list for the API
  final services = <BleBluetoothService>[];
  final servicesMap = <Uuid128, _BluezService>{};

  _BluezServices(this.bluezServices) {
    for (var gattService in bluezServices) {
      var uuid = uuidFromBluezUuid(gattService.uuid);
      var bluezService = _BluezService(gattService);
      var service = bluezService.service;
      servicesMap[uuid] = bluezService;
      services.add(service);
    }
  }
}

class _BluezCharacteristic {
  final _BluezService bluezService;
  late BleBluetoothCharacteristic characteristic;
  final BlueZGattCharacteristic gattCharacteristic;

  Uuid128 get uuid => characteristic.uuid;

  _BluezCharacteristic(this.bluezService, this.gattCharacteristic) {
    var uuid = uuidFromBluezUuid(gattCharacteristic.uuid);
    var flagToProperty = {
      BlueZGattCharacteristicFlag.write: blePropertyWrite,
      BlueZGattCharacteristicFlag.read: blePropertyRead,
      BlueZGattCharacteristicFlag.notify: blePropertyNotify,
      BlueZGattCharacteristicFlag.broadcast: blePropertyBroadcast,

      BlueZGattCharacteristicFlag.writeWithoutResponse:
          blePropertyWriteNoResponse,

      BlueZGattCharacteristicFlag.indicate: blePropertyIndicate,
      BlueZGattCharacteristicFlag.authenticatedSignedWrites:
          blePropertySignedWrite,
      BlueZGattCharacteristicFlag.extendedProperties: blePropertyExtendedProps,
      // TODO BlueZGattCharacteristicFlag.reliableWrite: bleProperty,
      // TODO BlueZGattCharacteristicFlag.writableAuxiliaries, ,
      // TODO BlueZGattCharacteristicFlag.encryptRead,
      // TODO BlueZGattCharacteristicFlag.encryptWrite,
      // TODO BlueZGattCharacteristicFlag.encryptAuthenticatedRead,
      // TODO BlueZGattCharacteristicFlag.encryptAuthenticatedWrite,
//      TODO BlueZGattCharacteristicFlag.secureRead: bleProperty,
      BlueZGattCharacteristicFlag.secureWrite: blePropertySignedWrite,
      // TODO BlueZGattCharacteristicFlag.authorize,
    };
    var properties = 0;
    for (var flag in gattCharacteristic.flags) {
      properties |= flagToProperty[flag] ?? 0;
    }

    characteristic = BleBluetoothCharacteristic(
        service: bluezService.service, properties: properties, uuid: uuid);

    var descriptors = gattCharacteristic.descriptors.map((gattDescriptor) {
      var descriptor = BleBluetoothDescriptor(
          characteristic: characteristic,
          uuid: uuidFromBluezUuid(gattDescriptor.uuid));
      return descriptor;
    }).toList();
    // ignore: invalid_use_of_protected_member
    characteristic.descriptors = descriptors;
  }
}

class _BluezService {
  final BlueZGattService gattService;
  late BleBluetoothService service;

  final characteristicsMap = <Uuid128, _BluezCharacteristic>{};

  _BluezService(this.gattService) {
    var uuid = uuidFromBluezUuid(gattService.uuid);
    service = BleBluetoothService(uuid: uuid);

    var characteristics = <BleBluetoothCharacteristic>[];

    for (var gattCharacteristic in gattService.characteristics) {
      var bluezCharacteristic = _BluezCharacteristic(this, gattCharacteristic);
      var uuid = bluezCharacteristic.uuid;
      characteristicsMap[uuid] = bluezCharacteristic;
      characteristics.add(bluezCharacteristic.characteristic);
    }
    // ignore: invalid_use_of_protected_member
    service.characteristics = characteristics;
  }
}

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
        /// Clear cache
        _cachedServices = null;
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
    _getServices();
  }

  _BluezServices? _cachedServices;

  @override
  Future<List<BleBluetoothService>> getServices() async {
    return _getServices().services;
  }

  _BluezServices _getServices({bool force = false}) {
    if (force) {
      _cachedServices = null;
    }
    _cachedServices ??= _readServices();
    return _cachedServices!;
  }

  _BluezServices _readServices() {
    var deviceBluez = device.blueZDevice;
    return _BluezServices(deviceBluez.gattServices);
  }

  @override
  // TODO: implement onConnectionState
  Stream<BluetoothDeviceConnectionState> get onConnectionState {
    _connectionStateController ??= StreamController.broadcast(onListen: () {
      _checkState();
    });
    return _connectionStateController!.stream;
  }

  _BluezService? _getBluezServiceByUuid(Uuid128 serviceUuid) {
    var services = _getServices();
    _BluezService? getBluezService() {
      return services.servicesMap[serviceUuid];
    }

    var bluezService = getBluezService();
    if (bluezService == null) {
      // Try refresh cache
      _getServices(force: true);
      bluezService = getBluezService();
    }
    return bluezService;
  }

  _BluezCharacteristic? _getBluezCharacteristic(
      BleBluetoothCharacteristic characteristic) {
    var service = _getBluezServiceByUuid(characteristic.service.uuid);
    if (service != null) {
      return service.characteristicsMap[characteristic.uuid];
    }
    return null;
  }

  _BluezCharacteristic _getBluezCharacteristicOrThrow(
      BleBluetoothCharacteristic characteristic) {
    var bluezCharacteristic = _getBluezCharacteristic(characteristic);
    if (bluezCharacteristic == null) {
      throw StateError('Characteristic $characteristic not found');
    }
    return bluezCharacteristic;
  }

  @override
  Future<BleBluetoothCharacteristicValue> readCharacteristic(
      BleBluetoothCharacteristic characteristic) async {
    var bluezCharacteristic = _getBluezCharacteristicOrThrow(characteristic);
    var data =
        asUint8List(await bluezCharacteristic.gattCharacteristic.readValue());
    return characteristic.withValue(data);
  }
}
