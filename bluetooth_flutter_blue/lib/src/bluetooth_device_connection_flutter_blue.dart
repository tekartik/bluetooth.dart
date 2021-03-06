import 'dart:typed_data';

import 'package:flutter_blue/flutter_blue.dart' as native;
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_flutter_blue/src/ble_flutter_blue.dart';
import 'package:tekartik_bluetooth_flutter_blue/src/bluetooth_device_flutter_blue.dart';
import 'package:tekartik_bluetooth_flutter_blue/utils/guid_utils.dart';

BluetoothDeviceConnectionState connectionStateFromBluetoothDeviceState(
    native.BluetoothDeviceState state) {
  switch (state) {
    case native.BluetoothDeviceState.connecting:
      return BluetoothDeviceConnectionState.connecting;
    case native.BluetoothDeviceState.connected:
      return BluetoothDeviceConnectionState.connected;
    case native.BluetoothDeviceState.disconnected:
      return BluetoothDeviceConnectionState.disconnected;
    case native.BluetoothDeviceState.disconnecting:
      return BluetoothDeviceConnectionState.disconnecting;
  }
}

extension CharacteristicPropertiesFlutterBlueExt
    on native.CharacteristicProperties {
  int getValue() {
    var value = 0;
    if (broadcast) {
      value |= blePropertyBroadcast;
    }
    if (read) {
      value |= blePropertyRead;
    }
    if (writeWithoutResponse) {
      value |= blePropertyWriteNoResponse;
    }
    if (write) {
      value |= blePropertyWrite;
    }
    if (notify) {
      value |= blePropertyNotify;
    }
    if (indicate) {
      value |= blePropertyIndicate;
    }
    if (authenticatedSignedWrites) {
      value |= blePropertySignedWrite;
    }
    if (extendedProperties) {
      value |= blePropertyExtendedProps;
    }
    return value;
  }
}

class BluetoothDeviceConnectionFlutterBlue
    implements BluetoothDeviceConnection {
  final BluetoothDeviceFlutterBlue device;

  BluetoothDeviceConnectionFlutterBlue(this.device);

  @override
  void close() {}

  @override
  Future connect() async {
    var nativeImpl = device.nativeImpl;

    /// Auto connect GATT does not work when working with BLE simulation
    /// on Android
    await nativeImpl.connect(autoConnect: false);
  }

  @override
  Future disconnect() async {
    var nativeImpl = device.nativeImpl;
    await nativeImpl.disconnect();
  }

  Map<BleBluetoothService, DiscoveredServiceFlutterBlue> _wrapServices(
      List<native.BluetoothService> natives) {
    var map = <BleBluetoothService, DiscoveredServiceFlutterBlue>{};
    for (var native in natives) {
      var bleService = BleBluetoothService(uuid: uuidFromGuid(native.uuid));
      var bleCharacteristics = <BleBluetoothCharacteristic>[];
      for (var nativeCharacteristic in native.characteristics) {
        var bleCharacteristic = BleBluetoothCharacteristic(
            properties: nativeCharacteristic.properties.getValue(),
            service: bleService,
            uuid: uuidFromGuid((nativeCharacteristic.uuid)));
        bleCharacteristics.add(bleCharacteristic);
      }

      // ignore: invalid_use_of_protected_member
      bleService.characteristics = bleCharacteristics;
      map[bleService] = DiscoveredServiceFlutterBlue(native);
    }
    return map;
  }

  List<BleBluetoothService> get _discoveredServices =>
      _discoverMap.keys.toList();
  late Map<BleBluetoothService, DiscoveredServiceFlutterBlue> _discoverMap;

  @override
  Future discoverServices() async {
    var nativeImpl = device.nativeImpl;
    _discoverMap = _wrapServices(await nativeImpl.discoverServices());
  }

  @override
  Future<List<BleBluetoothService>> getServices() async {
    return _discoveredServices;
  }

  @override
  Stream<BluetoothDeviceConnectionState> get onConnectionState {
    var nativeImpl = device.nativeImpl;
    return nativeImpl.state
        .map((native) => connectionStateFromBluetoothDeviceState(native));
  }

  BluetoothCharacteristicFlutterBlue? findCharacteristic(
      BleBluetoothCharacteristic bc) {
    var service = _discoverMap[bc.service];
    if (service != null) {
      return service.getCharacteristic(bc.uuid);
    }
    return null;
  }

  final readCharacteristicTimeout = Duration(milliseconds: 10000);

  @override
  Future<BleBluetoothCharacteristicValue> readCharacteristic(
      BleBluetoothCharacteristic bc) async {
    var characteristic = findCharacteristic(bc);
    if (characteristic == null) {
      throw StateError('read characteristic $bc not found');
    }
    var value = await characteristic.read().timeout(readCharacteristicTimeout);

    var bcv = BleBluetoothCharacteristicValue(
        bc: bc, value: Uint8List.fromList(value));
    return bcv;
  }
}
