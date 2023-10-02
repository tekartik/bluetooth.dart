import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/src/ble.dart';
import 'package:tekartik_bluetooth/src/mock/manager_mock.dart';
import 'package:tekartik_bluetooth/src/mock/peripheral_mock.dart';

import '../../uuid.dart';

class BluetoothDeviceConnectionMock implements BluetoothDeviceConnection {
  final BluetoothManagerMock manager;

  BluetoothDeviceConnectionMock({required this.manager});
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
  Future<void> discoverServices() {
    // TODO: implement discoverServices
    throw UnimplementedError();
  }

  BluetoothPeripheralMock get peripheral => manager.peripheral!;

  BleBluetoothService serviceFromPeripheralService(
      BluetoothGattService gattService) {
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
      BluetoothGattCharacteristic gattCharacteristic) {
    var characteristic = BleBluetoothCharacteristicImpl(
        service: service,
        uuid: gattCharacteristic.uuid,
        properties: gattCharacteristic.properties);
    return characteristic;
  }

  @override
  Future<List<BleBluetoothService>> getServices() async {
    var services = manager.peripheral!.services!;
    return services.map(serviceFromPeripheralService).toList();
  }

  @override
  Stream<BleBluetoothCharacteristicValue> onCharacteristicValueChanged(
      BleBluetoothCharacteristic characteristic) {
    // TODO: implement onCharacteristicValueChanged
    throw UnimplementedError();
  }

  @override
  // TODO: implement onConnectionState
  Stream<BluetoothDeviceConnectionState> get onConnectionState =>
      throw UnimplementedError();

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
      Uuid128 serviceUuid, Uuid128 uuid) {
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
      BleBluetoothCharacteristic characteristic) async {
    var service = getService(characteristic.service.uuid);
    var bleCharacteristic =
        getCharacteristic(characteristic.service.uuid, characteristic.uuid);
    var value = await peripheral.getCharacteristicValue(
        serviceUuid: characteristic.service.uuid,
        characteristicUuid: characteristic.uuid);
    return BleBluetoothCharacteristicValue(
        service: service, value: value, bc: bleCharacteristic);
  }

  @override
  Future<void> registerCharacteristic(
      BleBluetoothCharacteristic characteristic, bool on) {
    // TODO: implement registerCharacteristic
    throw UnimplementedError();
  }

  @override
  Future<void> writeCharacteristic(
      BleBluetoothCharacteristicValue characteristicValue) async {
    await peripheral.setCharacteristicValue(
        serviceUuid: characteristicValue.service.uuid,
        characteristicUuid: characteristicValue.uuid,
        value: characteristicValue.value);
  }
}
