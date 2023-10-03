import 'dart:typed_data';

import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/src/rx_utils.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

class BluetoothPeripheralCharacteristicMock {
  final Uint8List value;

  BluetoothPeripheralCharacteristicMock({required this.value});
}

class BluetoothPeripheralServiceMock {
  final characteristicsMap = <Uuid128, BluetoothPeripheralCharacteristicMock>{};
}

class BluetoothPeripheralNotificationMock {
  final Uuid128 serviceUuid;
  final Uuid128 characteristicUuid;
  final Uint8List? value;

  BluetoothPeripheralNotificationMock(
      {required this.serviceUuid,
      required this.characteristicUuid,
      required this.value});
}

class BluetoothPeripheralMock extends BluetoothPeripheral {
  // publish here we don't replay like behavior
  final _writeCharacteristicEvent =
      PublishSubjectWrapper<BluetoothPeripheralWriteCharacteristicEvent>();

  SubjectInterface<BluetoothPeripheralWriteCharacteristicEvent>
      get writeCharacteristicEvent => _writeCharacteristicEvent;

  /// Where to post notification to be sent
  final _bleNotificationWrapper =
      PublishSubjectWrapper<BluetoothPeripheralNotificationMock>();

  SubjectInterface<BluetoothPeripheralNotificationMock> get bleNotification =>
      _bleNotificationWrapper;
  BluetoothPeripheralMock(
      { // Needed?
      String? deviceName,
      List<BluetoothGattService>? services})
      : super(plugin: null, deviceName: deviceName, services: services);

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
  Future notifyCharacteristicValue(
      {required Uuid128 serviceUuid,
      required Uuid128 characteristicUuid,
      Uint8List? value}) async {
    // TODO: implement notifyCharacteristicValue
    _bleNotificationWrapper.sink.add(BluetoothPeripheralNotificationMock(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        value: value));
  }

  @override
  Future<Uint8List> getCharacteristicValue(
      {required Uuid128 serviceUuid,
      required Uuid128 characteristicUuid}) async {
    var service = servicesMap[serviceUuid];
    if (service == null) {
      throw 'service not found $serviceUuid';
    }
    return service.characteristicsMap[characteristicUuid]?.value ??
        Uint8List(0);
  }

  /// From client connection
  Future<void> writeCharacteristicValue(
      {required Uuid128 serviceUuid,
      required Uuid128 characteristicUuid,
      required Uint8List value}) async {
    await setCharacteristicValue(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        value: value);
    _writeCharacteristicEvent.sink
        .add(BluetoothPeripheralWriteCharacteristicEvent()
          ..serviceUuid = serviceUuid
          ..characteristicUuid = characteristicUuid
          ..value = value);
  }
}
