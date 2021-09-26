import 'dart:typed_data';

import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth/bluetooth_service.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter/src/constant.dart';
import 'package:tekartik_bluetooth_flutter/src/exception.dart';
import 'package:tekartik_bluetooth_flutter/src/import.dart';
import 'package:tekartik_bluetooth_flutter/src/mixin.dart';
import 'package:tekartik_bluetooth_flutter/utils/model_utils.dart';
import 'package:tekartik_common_utils/map_utils.dart';
import 'package:tekartik_common_utils/model/model_v2.dart';

// abstract class BluetoothDeviceConnection {}
export 'package:tekartik_bluetooth/src/device_connection.dart';

class BluetoothDeviceConnectionFlutterImpl
    implements BluetoothDeviceConnection {
  final lock = Lock();
  final BluetoothFlutterManagerMixin manager;
  final controller = StreamController<MethodCall>.broadcast();
  final connectionStateController =
      StreamController<BluetoothDeviceConnectionState>.broadcast();

  BluetoothDeviceConnectionState? connectionState;

  /// set upon connection
  int? connectionId;

  BluetoothDeviceConnectionFlutterImpl({required this.manager}) {
    controller.stream.listen((call) {
      if (call.method == 'remoteConnectionState') {
        // devPrint(call.arguments);
        onConnectionStateChanged(call.arguments as Map?);
      }
    }, onDone: () {
      () async {
        // devPrint('done $this');
        if (connectionId != null) {
          await disconnect();
        }
      }();
    });
    connectionStateController.stream.listen((state) {
      connectionState = state;
    });
  }

  Model _baseMap() {
    var map = newModel();

    map[connectionIdKey] = connectionId;
    return map;
  }

  @override
  Future<BleBluetoothCharacteristicValue> readCharacteristic(
      BleBluetoothCharacteristic characteristic) async {
    var map = _baseMap();

    var serviceUuid = characteristic.service.uuid.toString();
    var characteristicUuid = characteristic.uuid.toString();
    map[serviceUuidKey] = serviceUuid;
    map[characteristicUuidKey] = characteristicUuid;

    var completer = Completer<BleBluetoothCharacteristicValue>();
    var subscription = controller.stream
        .where((call) => call.method == 'remoteReadCharacteristicResult')
        .map((call) => asModel(asMap(call.arguments) ?? {}))
        .listen((map) {
      var readServiceUuid = map[serviceUuidKey] as String?;
      var readCharacteristicUuid = map[characteristicUuidKey] as String?;
      if (readServiceUuid == serviceUuid &&
          readCharacteristicUuid == characteristicUuid) {
        var status = map[statusKey];
        if (!completer.isCompleted) {
          if (status == androidBleGattSuccess) {
            var value = map[valueKey] as Uint8List;
            completer.complete(BleBluetoothCharacteristicValue(
                bc: characteristic, value: value));
          } else {
            completer.completeError(
                BluetoothException('gattStatus $status', status));
          }
        }
      }
    });
    try {
      await manager.invokeMethod<dynamic>('remoteReadCharacteristic', map);

      return await completer.future.timeout(bleReadCharacteristicTimeout);
    } finally {
      subscription.cancel().unawait();
    }
  }

  @override
  Future disconnect() async {
    await lock.synchronized(() async {
      var map = _baseMap();

      var completer = Completer();
      if (connectionState?.state == null ||
          connectionState?.state == androidBleConnectionStateDisconnected) {
        // devPrint('Not connected');
        return;
      }
      var subscription = connectionStateController.stream.listen((state) {
        if (state.state == androidBleConnectionStateDisconnected) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      });
      try {
        if (connectionState?.state != androidBleConnectionStateDisconnecting) {
          await manager.invokeMethod<dynamic>('remoteDisconnect', map);
        }
        await completer.future.timeout(bleDisconnectedTimeout, onTimeout: () {
          // devPrint('disconnect timeout');
        });
      } catch (e) {
        print('disconnect $this error $e');
      } finally {
        subscription.cancel().unawait();
      }
    });
  }

  void fromMap(Map map) {
    connectionId = parseInt(map[connectionIdKey]);
  }

  Model toDebugMap() {
    var model = newModel();
    model.setValue(connectionIdKey, connectionId);
    return model;
  }

  @override
  String toString() => toDebugMap().toString();

  Future<T> invokeMethod<T>(String method, [dynamic arguments]) {
    return manager.invokeMethod(method, arguments);
  }

  @Deprecated('Use remote get service')
  @override
  Future discoverServices() async {
    var map = _baseMap();

    var completer = Completer();
    var subscription = controller.stream
        .where((call) => call.method == 'remoteDiscoverServicesResult')
        .map((call) => asModel(asMap(call.arguments) ?? {}))
        .listen((map) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    try {
      await manager.invokeMethod<dynamic>('remoteDiscoverServices', map);

      return await completer.future.timeout(bleDiscoverServicesTimeout);
    } finally {
      subscription.cancel().unawait();
    }
  }

  @override
  Future<List<BleBluetoothService>> getServices() async {
    var map = _baseMap();
    var list = await invokeMethod<List>('remoteGetServices', map);
    return list.map((item) {
      var map = item as Map;
      var uuidText = map[uuidKey] as String?;
      var bleService = BleBluetoothService(uuid: Uuid128.from(text: uuidText));
      var characteristicsMapList = map[characteristicsKey] as List?;
      var characteristics = characteristicsMapList?.map((item) {
        var map = item as Map;
        var uuidText = map[uuidKey] as String?;
        // devPrint('properties ${map[propertiesKey]}');
        var properties = (map[propertiesKey] as int?) ?? 0x00;
        var descriptorMapList = (map[descriptorsKey] as List?)?.cast<Map>();

        var characteristic = BleBluetoothCharacteristicImpl(
            service: bleService,
            uuid: Uuid128.from(text: uuidText),
            properties: properties);
        var descriptors = descriptorMapList
            ?.map((map) =>
                descriptorFromMap(characteristic: characteristic, map: map))
            .toList(growable: false);
        characteristic.descriptors = <BleBluetoothDescriptor>[...?descriptors];
        return characteristic;
      }).toList(growable: false);
      // ignore: invalid_use_of_protected_member
      bleService.characteristics = characteristics;
      return bleService;
    }).toList(growable: false);
  }

  @override
  void close() {
    manager.connections.remove(connectionId);
    controller.close();
  }

  @override
  Future connect() async {
    await lock.synchronized(() async {
      var map = _baseMap();

      var completer = Completer();
      if (connectionState?.state == androidBleConnectionStateConnected) {
        // devPrint('Already connected');
      }

      var subscription = connectionStateController.stream.listen((state) {
        if (state.state == androidBleConnectionStateConnected) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      });
      try {
        if (connectionState?.state != androidBleConnectionStateConnecting) {
          await manager.invokeMethod<dynamic>('remoteConnect', map);
        }
        await completer.future.timeout(bleConnectedTimeout);
      } finally {
        subscription.cancel().unawait();
      }
    });
  }

  void onConnectionStateChanged(Map? map) {
    // devPrint('map $map in $connections');

    if (!connectionStateController.isClosed) {
      var state = map!['state'] as int;
      connectionStateController.add(BluetoothDeviceConnectionStateImpl(state));
    } else {
      // devPrint('controller closed');
    }
  }

  @override
  Stream<BluetoothDeviceConnectionState> get onConnectionState =>
      connectionStateController.stream;
}

class BluetoothDeviceConnectionStateImpl
    implements BluetoothDeviceConnectionState {
  @override
  int state;

  BluetoothDeviceConnectionStateImpl(this.state);

  /*
  void fromMap(Map map) {
    var model = Model(map);
    connectionId = model['connectionId'] as int;
    state = model['state'] as int;
  }
  */

  Model toDebugMap() {
    var model = newModel();
    model.setValue('state', state);
    return model;
  }

  @override
  String toString() => toDebugMap().toString();
}
