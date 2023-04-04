import 'dart:typed_data';

import 'package:bluez/bluez.dart';
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_bluez/bluetooth_bluez.dart';
import 'package:tekartik_bluetooth_bluez/src/bluez_utils.dart';
import 'package:tekartik_bluetooth_bluez/src/scan_bluez.dart';

import 'import.dart';
import 'import_bluetooth.dart';

abstract class BluetoothDeviceConnectionBluez
    extends BluetoothDeviceConnection {}

class _BluezCharacteristicChangeController {
  final BlueZGattCharacteristic characteristic;
  late StreamController<Uint8List> _controller;
  StreamSubscription? _subscription;

  Stream<Uint8List> get stream => _controller.stream;

  _BluezCharacteristicChangeController(this.characteristic) {
    _controller = StreamController.broadcast(onListen: () async {
      try {
        _subscription = characteristic.propertiesChanged.listen((names) {
          // propertiesChanged [Value] [0]
          if (debugBluetoothManagerBluez) {
            print(
                'propertiesChanged ($names) characteristic ${characteristic.uuid}');
          }
          if (names.contains('Value')) {
            _controller.add(asUint8List(characteristic.value));
          }
        });
      } catch (e) {
        _controller.addError(e);
      }
    }, onCancel: () {
      _subscription?.cancel();
      //print('onCancel');
    });
  }
}

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

    var properties = bluezFlagsToProperties(gattCharacteristic.flags);

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
  var connected = false;
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

class BluetoothDeviceConnectionBluezImpl extends BluetoothDeviceConnectionBluez
    with BluetoothDeviceConnectionMixin {
  final BluetoothDeviceBluezImpl device;
  StreamSubscription? propertiesChangedSubscription;
  StreamController<BluetoothDeviceConnectionState>? _connectionStateController;

  BluetoothDeviceConnectionBluezImpl(this.device);

  @override
  void close() {
    disconnect();
    propertiesChangedSubscription?.cancel();
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
      }
      try {
        await deviceBluez.connect();
      } catch (e) {
        if (!deviceBluez.connected) {
          rethrow;
        }
      }
    } finally {
      _checkState();
    }
    propertiesChangedSubscription =
        deviceBluez.propertiesChanged.listen((propertyName) {
      //  Property changes [UUIDs, ServicesResolved]
      // Property changes [Connected]
      if (debugBluetoothManagerBluez) {
        _log('Property changes $propertyName');
      }
    });
  }

  @override
  Future disconnect() async {
    // Create controller
    onConnectionState;
    var deviceBluez = device.blueZDevice;
    _connectionStateController!.sink
        .add(BluetoothDeviceConnectionState.disconnecting);
    try {
      await deviceBluez.disconnect();
    } catch (e) {
      if (debugBluetoothManagerBluez) {
        print('[debug] expected bluez disconnect error $e');
      }
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

  void _checkConnection() {
    var deviceBluez = device.blueZDevice;
    if (!deviceBluez.connected) {
      throw StateError('Device not connected');
    }
  }

  @override
  Future discoverServices() async {
    var deviceBluez = device.blueZDevice;
    var sw = Stopwatch();
    while (true) {
      // devPrint('Waiting for services');
      // devPrint('gattServices: ${deviceBluez.gattServices}');
      if (deviceBluez.servicesResolved) {
        break;
      }
      if (sw.elapsedMilliseconds > 30000) {
        throw StateError('Unable to resolve services');
      }
      await sleep(100);
      if (deviceBluez.gattServices.isNotEmpty) {
        break;
      }
      _checkConnection();
    }
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
    // devPrint('gattServices: ${deviceBluez.gattServices}');
    return _BluezServices(deviceBluez.gattServices);
  }

  @override
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

  void _log(Object? message) {
    print('/bluez $message');
  }

  final _initLock = Lock();

  var expConnectProfile = false;

  /// Never throws
  Future<void> _initService(BleBluetoothService service) async {
    if (expConnectProfile) {
      var bluezService = _getBluezServiceByUuid(service.uuid);
      if (bluezService != null) {
        if (!bluezService.connected) {
          await _initLock.synchronized(() async {
            var deviceBluez = device.blueZDevice;
            if (!bluezService.connected) {
              try {
                await deviceBluez
                    .connectProfile(bluezUuidFromUuid(service.uuid));
                if (debugBluetoothManagerBluez) {
                  _log('connectProfile $service success');
                }
              } catch (e) {
                if (debugBluetoothManagerBluez) {
                  _log('connectProfile $service error $e');
                }
              }
            }
          });
        }
      }
    }
  }

  @override
  Future<BleBluetoothCharacteristicValue> readCharacteristic(
      BleBluetoothCharacteristic characteristic) async {
    await _initService(characteristic.service);
    var bluezCharacteristic = _getBluezCharacteristicOrThrow(characteristic);
    try {
      var data =
          asUint8List(await bluezCharacteristic.gattCharacteristic.readValue());
      var bcv = characteristic.withValue(data);
      if (debugBluetoothManagerBluez) {
        _log('read characteristic $bcv');
      }
      return bcv;
    } catch (e) {
      if (debugBluetoothManagerBluez) {
        _log('read characteristic $characteristic value error $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> writeCharacteristic(
      BleBluetoothCharacteristicValue characteristicValue) async {
    var bluezCharacteristic =
        _getBluezCharacteristicOrThrow(characteristicValue.bc);
    var bcv = characteristicValue;
    try {
      await bluezCharacteristic.gattCharacteristic
          .writeValue(characteristicValue.value);
      if (debugBluetoothManagerBluez) {
        _log('write characteristic $bcv');
      }
    } catch (e) {
      if (debugBluetoothManagerBluez) {
        _log('write characteristic $bcv value error $e');
      }
      rethrow;
    }
  }

  final _characteristicValueChangedControllers =
      <BleBluetoothCharacteristicRef, _BluezCharacteristicChangeController>{};

  @override
  Stream<BleBluetoothCharacteristicValue> onCharacteristicValueChanged(
      BleBluetoothCharacteristic characteristic) {
    if (debugBluetoothManagerBluez) {
      _log('onCharacteristicValueChanged $characteristic');
    }
    var bluezCharacteristic = _getBluezCharacteristicOrThrow(characteristic);

    var ref = characteristic.ref;
    var controller = _characteristicValueChangedControllers[ref] ??=
        _BluezCharacteristicChangeController(
            bluezCharacteristic.gattCharacteristic);
    return controller.stream.map((value) => characteristic.withValue(value));
  }

  @override
  Future<void> registerCharacteristic(
      BleBluetoothCharacteristic characteristic, bool on) async {
    if (debugBluetoothManagerBluez) {
      _log('registerCharacteristic $characteristic');
    }
    var bluezCharacteristic = _getBluezCharacteristicOrThrow(characteristic);

    try {
      if (on) {
        await bluezCharacteristic.gattCharacteristic.startNotify();
      } else {
        await bluezCharacteristic.gattCharacteristic.stopNotify();
      }
    } catch (e) {
      if (debugBluetoothManagerBluez) {
        print(
            '${on ? 'register' : 'unregister'} characteristic $characteristic value error $e');
      }
      rethrow;
    }
  }
}
