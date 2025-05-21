import 'dart:typed_data';

import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth_flutter_blue/src/ble_flutter_blue.dart';
import 'package:tekartik_bluetooth_flutter_blue/src/bluetooth_device_flutter_blue.dart';
import 'package:tekartik_bluetooth_flutter_blue/src/import_bluetooth.dart';
import 'package:tekartik_bluetooth_flutter_blue/utils/guid_utils.dart';

import 'flutter_blue_import.dart' as native;
import 'import.dart';

BluetoothDeviceConnectionState connectionStateFromBluetoothConnectionState(
  native.BluetoothConnectionState state,
) {
  switch (state) {
    case native.BluetoothConnectionState.connected:
      return BluetoothDeviceConnectionState.connected;
    case native.BluetoothConnectionState.disconnected:
      return BluetoothDeviceConnectionState.disconnected;
    /*
    No longer supported in iOS and Android
    case native.BluetoothConnectionState.connecting:
      return BluetoothDeviceConnectionState.connecting;
    case native.BluetoothConnectionState.disconnecting:
      return BluetoothDeviceConnectionState.disconnecting;
      */
    default:
      return BluetoothDeviceConnectionState.disconnected;
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
    with BluetoothDeviceConnectionMixin
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
    List<native.BluetoothService> natives,
  ) {
    var map = <BleBluetoothService, DiscoveredServiceFlutterBlue>{};
    for (var native in natives) {
      /// Some services can be invalid (crash in uuidFromGuid), simple ignore them
      try {
        var bleService = BleBluetoothService(uuid: uuidFromGuid(native.uuid));
        var bleCharacteristics = <BleBluetoothCharacteristic>[];
        for (var nativeCharacteristic in native.characteristics) {
          var bleCharacteristic = BleBluetoothCharacteristic(
            properties: nativeCharacteristic.properties.getValue(),
            service: bleService,
            uuid: uuidFromGuid((nativeCharacteristic.uuid)),
          );
          bleCharacteristics.add(bleCharacteristic);
        }

        // ignore: invalid_use_of_protected_member
        bleService.characteristics = bleCharacteristics;
        map[bleService] = DiscoveredServiceFlutterBlue(native);
      } catch (e) {
        // ignore: avoid_print
        print('error $e for ${native.uuid}');
        // devPrint(st);
      }
    }
    return map;
  }

  List<BleBluetoothService> get _discoveredServices =>
      _discoverMap!.keys.toList();
  Map<BleBluetoothService, DiscoveredServiceFlutterBlue>? _discoverMap;

  @override
  Future discoverServices() async {
    var nativeImpl = device.nativeImpl;
    _discoverMap = _wrapServices(await nativeImpl.discoverServices());
  }

  @override
  Future<List<BleBluetoothService>> getServices() async {
    if (_discoverMap == null) {
      await discoverServices();
    }
    return _discoveredServices;
  }

  @override
  Stream<BluetoothDeviceConnectionState> get onConnectionState {
    var nativeImpl = device.nativeImpl;
    return nativeImpl.connectionState.map(
      (native) => connectionStateFromBluetoothConnectionState(native),
    );
  }

  BluetoothCharacteristicFlutterBlue? findCharacteristic(
    BleBluetoothCharacteristic bc,
  ) {
    var service = _discoverMap?[bc.service];
    if (service != null) {
      return service.getCharacteristic(bc.uuid);
    }
    return null;
  }

  BluetoothCharacteristicFlutterBlue findCharacteristicOrThrow(
    BleBluetoothCharacteristic bc,
  ) {
    var fbCharacteristic = findCharacteristic(bc);
    if (fbCharacteristic == null) {
      throw StateError('Characteristic $bc not found');
    }
    return fbCharacteristic;
  }

  final readCharacteristicTimeout = const Duration(milliseconds: 10000);
  final writeCharacteristicTimeout = const Duration(milliseconds: 10000);

  @override
  Future<BleBluetoothCharacteristicValue> readCharacteristic(
    BleBluetoothCharacteristic bc,
  ) async {
    var characteristic = findCharacteristicOrThrow(bc);

    var value = await characteristic.read().timeout(readCharacteristicTimeout);

    var bcv = BleBluetoothCharacteristicValue(
      bc: bc,
      value: Uint8List.fromList(value),
    );
    return bcv;
  }

  @override
  Stream<BleBluetoothCharacteristicValue> onCharacteristicValueChanged(
    BleBluetoothCharacteristic characteristic,
  ) {
    var nativeCharacteristic = findCharacteristicOrThrow(characteristic);
    return nativeCharacteristic.value.map((value) {
      var bcv = BleBluetoothCharacteristicValue(
        bc: characteristic,
        value: Uint8List.fromList(value),
      );
      return bcv;
    });
  }

  @override
  Future<void> writeCharacteristic(
    BleBluetoothCharacteristicValue characteristicValue,
  ) async {
    var characteristic = findCharacteristicOrThrow(characteristicValue.bc);
    await characteristic.write(characteristicValue.value);
  }

  @override
  Future<void> registerCharacteristic(
    BleBluetoothCharacteristic characteristic,
    bool on,
  ) async {
    var nativeCharacteristic = findCharacteristicOrThrow(characteristic);
    await nativeCharacteristic.registerNotification(on);
  }
}
