import 'package:rxdart/rxdart.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/src/ble.dart';
import 'package:tekartik_bluetooth/src/mock/manager_mock.dart';
import 'package:tekartik_bluetooth/src/mock/peripheral_mock.dart';
import 'package:tekartik_bluetooth/src/rx_utils.dart';

import '../../uuid.dart';

class BluetoothDeviceConnectionMock implements BluetoothDeviceConnection {
  final BluetoothManagerMock manager;

  /// Where to post notification to be sent
  final _bleNotificationWrapper =
      PublishSubjectWrapper<BleBluetoothCharacteristicValue>();

  SubjectInterface<BleBluetoothCharacteristicValue> get bleNotification =>
      _bleNotificationWrapper;
  final _bleConnectionStateWrapper =
      BehaviorSubject<BluetoothDeviceConnectionState>.seeded(
        BluetoothDeviceConnectionState.disconnected,
      );

  BluetoothDeviceConnectionMock({required this.manager});
  @override
  void close() {
    disconnect();
  }

  @override
  Future<void> connect() async {
    _bleConnectionStateWrapper.sink.add(
      BluetoothDeviceConnectionState.connected,
    );
  }

  @override
  Future disconnect() async {
    _bleConnectionStateWrapper.sink.add(
      BluetoothDeviceConnectionState.disconnected,
    );
  }

  @override
  Future<void> discoverServices() async {}

  BluetoothPeripheralMock get peripheral => manager.peripheral!;

  BleBluetoothService serviceFromPeripheralService(
    BluetoothGattService gattService,
  ) {
    var service = BleBluetoothServiceImpl(uuid: gattService.uuid);
    var characteristics = gattService.characteristics.map((e) {
      var characteristic = characteristicFromGattCharacteristic(service, e);
      return characteristic;
    });
    // ignore: invalid_use_of_protected_member
    return service..characteristics = characteristics.toList();
  }

  BleBluetoothCharacteristic characteristicFromGattCharacteristic(
    BleBluetoothService service,
    BluetoothGattCharacteristic gattCharacteristic,
  ) {
    var characteristic = BleBluetoothCharacteristicImpl(
      service: service,
      uuid: gattCharacteristic.uuid,
      properties: gattCharacteristic.properties,
    );
    return characteristic;
  }

  @override
  Future<List<BleBluetoothService>> getServices() async {
    var services = manager.peripheral!.services!;
    return services.map(serviceFromPeripheralService).toList();
  }

  @override
  Stream<BleBluetoothCharacteristicValue> onCharacteristicValueChanged(
    BleBluetoothCharacteristic characteristic,
  ) {
    return _bleNotificationWrapper.stream.where(
      (event) =>
          event.service.uuid == characteristic.service.uuid &&
          event.uuid == characteristic.uuid,
    );
  }

  @override
  // TODO: implement onConnectionState
  Stream<BluetoothDeviceConnectionState> get onConnectionState =>
      _bleConnectionStateWrapper.stream;

  BleBluetoothService getService(Uuid128 uuid) {
    var gattServices = manager.peripheral!.services!;
    var service = BleBluetoothServiceImpl(uuid: uuid);
    for (var peripheralService in gattServices) {
      if (peripheralService.uuid == uuid) {
        return serviceFromPeripheralService(peripheralService);
      }
    }
    return service;
  }

  BleBluetoothCharacteristic getCharacteristic(
    Uuid128 serviceUuid,
    Uuid128 uuid,
  ) {
    var service = getService(serviceUuid);

    for (var characteristic in service.characteristics) {
      if (characteristic.uuid == uuid) {
        return characteristic;
      }
    }
    throw ArgumentError('characteristic not found $uuid');
  }

  @override
  Future<BleBluetoothCharacteristicValue> readCharacteristic(
    BleBluetoothCharacteristic characteristic,
  ) async {
    var service = getService(characteristic.service.uuid);
    var bleCharacteristic = getCharacteristic(
      characteristic.service.uuid,
      characteristic.uuid,
    );
    var value = await peripheral.getCharacteristicValue(
      serviceUuid: characteristic.service.uuid,
      characteristicUuid: characteristic.uuid,
    );
    return BleBluetoothCharacteristicValue(
      service: service,
      value: value,
      bc: bleCharacteristic,
    );
  }

  @override
  Future<void> registerCharacteristic(
    BleBluetoothCharacteristic characteristic,
    bool on,
  ) async {
    peripheral.bleNotification.stream.listen((event) {
      if (event.serviceUuid == characteristic.service.uuid &&
          event.characteristicUuid == characteristic.uuid) {
        _bleNotificationWrapper.sink.add(
          BleBluetoothCharacteristicValue(
            service: BleBluetoothService(uuid: event.serviceUuid),
            value: event.value!,
            uuid: event.characteristicUuid,
          ),
        );
      }
    });
  }

  @override
  Future<void> writeCharacteristic(
    BleBluetoothCharacteristicValue characteristicValue,
  ) async {
    await peripheral.writeCharacteristicValue(
      serviceUuid: characteristicValue.service.uuid,
      characteristicUuid: characteristicValue.uuid,
      value: characteristicValue.value,
    );
  }
}
