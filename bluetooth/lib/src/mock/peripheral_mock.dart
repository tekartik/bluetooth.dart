import 'dart:typed_data';

import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

class BluetoothPeripheralCharacteristicMock {
  final Uint8List value;

  BluetoothPeripheralCharacteristicMock({required this.value});
}

class BluetoothPeripheralServiceMock {
  final characteristicsMap = <Uuid128, BluetoothPeripheralCharacteristicMock>{};
}

class BluetoothPeripheralMock extends BluetoothPeripheral {
  BluetoothPeripheralMock(
      {BluetoothPeripheralPlugin? plugin, // Needed?
      String? deviceName,
      List<BluetoothGattService>? services})
      : super(plugin: plugin, deviceName: deviceName, services: services);

  /// Current advertiseData
  AdvertiseData? advertiseData;
  final servicesMap = <Uuid128, BluetoothPeripheralServiceMock>{};

  BluetoothPeripheralServiceMock getBluetoothPeripheralServiceMock(
      Uuid128 serviceUuid,
      {bool createIfMissing = false}) {
    var service = servicesMap[serviceUuid];
    if (service == null) {
      if (createIfMissing) {
        servicesMap[serviceUuid] = service = BluetoothPeripheralServiceMock();
      } else {
        throw 'service not found $serviceUuid';
      }
    }
    return service;
  }

  @override
  Future<void> startAdvertising({AdvertiseData? advertiseData}) async {
    this.advertiseData = advertiseData ?? AdvertiseData();
  }

  @override
  Future<void> stopAdvertising() async {
    advertiseData = null;
  }

  @override
  Future setCharacteristicValue(
      {required Uuid128 serviceUuid,
      required Uuid128 characteristicUuid,
      required Uint8List? value}) async {
    var service = servicesMap[serviceUuid] ??= BluetoothPeripheralServiceMock();
    service.characteristicsMap[characteristicUuid] =
        BluetoothPeripheralCharacteristicMock(value: value!);
  }

  @override
  Future<Uint8List> getCharacteristicValue(
      {required Uuid128 serviceUuid,
      required Uuid128? characteristicUuid}) async {
    var service = servicesMap[serviceUuid];
    if (service == null) {
      throw 'service not found $serviceUuid';
    }
    return service.characteristicsMap[characteristicUuid]?.value ??
        Uint8List(0);
  }
}
