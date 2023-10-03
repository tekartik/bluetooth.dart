import 'dart:typed_data';

import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/src/mock/admin_manager_mock.dart';
import 'package:tekartik_bluetooth/src/mock/battery_device_mock.dart';
import 'package:tekartik_bluetooth/src/mock/manager_mock.dart';
import 'package:tekartik_bluetooth/src/mock/peripheral_mock.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:test/test.dart';

void main() {
  group('Mock', () {
    //BluetoothStateService bluetoothService;

    setUp(() {});

    test('advertise', () async {
      var remoteMock = BatteryRemoteDeviceMock();
      await remoteMock.start();
      await remoteMock.stop();
    });

    test('admin manager', () async {
      var mock = BluetoothAdminManagerMock();
      expect(
          await mock.getAdminInfo(),
          BluetoothAdminInfoImpl(
              hasBluetoothBle: true,
              hasBluetooth: true,
              isBluetoothEnabled: true));
    });
    /*
    test('manager no peripheral', () async {
      var mock = BluetoothManagerMock(peripheral: null);
      try {
        await mock.scan().first.timeout(Duration(milliseconds: 100));
      } on TimeoutException catch (_) {
        // expected
      }

      await mock.close();
    });*/
    test('manager with peripheral', () async {
      var peripheral = BluetoothPeripheralMock(deviceName: 'mock');
      var mock = BluetoothManagerMock(peripheral: peripheral);
      var scanResult = await mock.scan().first;
      expect(scanResult.device.name, 'Mock');
      await mock.close();
    });
    test('manager with advertising', () async {
      var peripheral = BluetoothPeripheralMock(deviceName: 'mock');
      await peripheral.startAdvertising();
      var mock = BluetoothManagerMock(peripheral: peripheral);
      var scanResult = await mock.scan().first;
      expect(scanResult.device.name, 'Mock');
      await mock.close();
    });
    test('manager with peripheral services', () async {
      var peripheral =
          BluetoothPeripheralMock(deviceName: 'mock', services: []);
      var mock = BluetoothManagerMock(peripheral: peripheral);
      var scanResult = await mock.scan().first;
      expect(scanResult.device.name, 'Mock');
      var device = await mock.newConnection(scanResult.device.id);
      expect(await device.onConnectionState.first,
          BluetoothDeviceConnectionState.disconnected);
      await device.connect();
      expect(await device.onConnectionState.first,
          BluetoothDeviceConnectionState.connected);
      await device.disconnect();
      expect(await device.onConnectionState.first,
          BluetoothDeviceConnectionState.disconnected);
    });
    test('manager with peripheral services', () async {
      var serviceUuid = Uuid128('0000180f-0000-1000-8000-00805f9b34fb');
      var characteristicUuid = Uuid128('00002a19-0000-1000-8000-00805f9b34fb');
      var peripheral = BluetoothPeripheralMock(deviceName: 'mock', services: [
        BluetoothGattService(uuid: serviceUuid, characteristics: [
          BluetoothGattCharacteristic(
              uuid: characteristicUuid,
              properties: BluetoothGattCharacteristic.propertyRead |
                  BluetoothGattCharacteristic.propertyWrite,
              permissions: BluetoothGattCharacteristic.permissionRead |
                  BluetoothGattCharacteristic.permissionWrite)
        ])
      ]);
      var mock = BluetoothManagerMock(peripheral: peripheral);
      var scanResult = await mock.scan().first;
      expect(scanResult.device.name, 'Mock');
      var device = await mock.newConnection(scanResult.device.id);
      var services = await device.getServices();
      var service = services.first;
      expect(
          services.first.uuid, Uuid128('0000180f-0000-1000-8000-00805f9b34fb'));

      await peripheral.setCharacteristicValue(
          serviceUuid: serviceUuid,
          characteristicUuid: characteristicUuid,
          value: Uint8List.fromList([1, 2, 3]));
      expect(
          (await device.readCharacteristic(BleBluetoothCharacteristic(
                  service: service, uuid: characteristicUuid)))
              .value,
          Uint8List.fromList([1, 2, 3]));
      await device.writeCharacteristic(BleBluetoothCharacteristicValue(
          service: BleBluetoothService(uuid: serviceUuid),
          value: Uint8List.fromList([1, 2, 3, 4]),
          uuid: characteristicUuid));
      expect(
          await peripheral.getCharacteristicValue(
            serviceUuid: serviceUuid,
            characteristicUuid: characteristicUuid,
          ),
          Uint8List.fromList([1, 2, 3, 4]));
      await mock.close();
    });
    test('manager with notify', () async {
      var serviceUuid = Uuid128('0000180f-0000-1000-8000-00805f9b34fb');
      var characteristicUuid = Uuid128('00002a19-0000-1000-8000-00805f9b34fb');
      var peripheral = BluetoothPeripheralMock(deviceName: 'mock', services: [
        BluetoothGattService(uuid: serviceUuid, characteristics: [
          BluetoothGattCharacteristic(
              uuid: characteristicUuid,
              properties: BluetoothGattCharacteristic.propertyRead |
                  BluetoothGattCharacteristic.propertyWrite |
                  BluetoothGattCharacteristic.propertyNotify,
              permissions: BluetoothGattCharacteristic.permissionRead |
                  BluetoothGattCharacteristic.permissionWrite)
        ])
      ]);
      var mock = BluetoothManagerMock(peripheral: peripheral);
      var scanResult = await mock.scan().first;
      expect(scanResult.device.name, 'Mock');
      var device = await mock.newConnection(scanResult.device.id);
      var services = await device.getServices();
      var service = services.first;
      expect(
          services.first.uuid, Uuid128('0000180f-0000-1000-8000-00805f9b34fb'));

      var characteristic = BleBluetoothCharacteristic(
          service: service, uuid: characteristicUuid);
      await device.registerCharacteristic(characteristic, true);
      var first = device.onCharacteristicValueChanged(characteristic).first;
      await peripheral.setAndNotifyCharacteristicValue(
          serviceUuid: serviceUuid,
          characteristicUuid: characteristicUuid,
          value: Uint8List.fromList([1, 2, 3]));
      expect((await first).value, [1, 2, 3]);
      await mock.close();
    });
    test('manager with indicate', () async {
      var serviceUuid = Uuid128('0000180f-0000-1000-8000-00805f9b34fb');
      var characteristicUuid = Uuid128('00002a19-0000-1000-8000-00805f9b34fb');
      var peripheral = BluetoothPeripheralMock(deviceName: 'mock', services: [
        BluetoothGattService(uuid: serviceUuid, characteristics: [
          BluetoothGattCharacteristic(
              uuid: characteristicUuid,
              properties: BluetoothGattCharacteristic.propertyRead |
                  BluetoothGattCharacteristic.propertyWrite |
                  BluetoothGattCharacteristic.propertyIndicate,
              permissions: BluetoothGattCharacteristic.permissionRead |
                  BluetoothGattCharacteristic.permissionWrite)
        ])
      ]);
      var mock = BluetoothManagerMock(peripheral: peripheral);
      var scanResult = await mock.scan().first;
      expect(scanResult.device.name, 'Mock');
      var device = await mock.newConnection(scanResult.device.id);
      var services = await device.getServices();
      var service = services.first;
      expect(
          services.first.uuid, Uuid128('0000180f-0000-1000-8000-00805f9b34fb'));

      var characteristic = BleBluetoothCharacteristic(
          service: service, uuid: characteristicUuid);

      await device.registerCharacteristic(characteristic, false);
      var first = device.onCharacteristicValueChanged(characteristic).first;
      await peripheral.setAndNotifyCharacteristicValue(
          serviceUuid: serviceUuid,
          characteristicUuid: characteristicUuid,
          value: Uint8List.fromList([1, 2, 3]));
      expect((await first).value, [1, 2, 3]);
      await mock.close();
    });
    test('peripheral on write', () async {
      var serviceUuid = Uuid128('0000180f-0000-1000-8000-00805f9b34fb');
      var characteristicUuid = Uuid128('00002a19-0000-1000-8000-00805f9b34fb');
      var peripheral = BluetoothPeripheralMock(deviceName: 'mock', services: [
        BluetoothGattService(uuid: serviceUuid, characteristics: [
          BluetoothGattCharacteristic(
              uuid: characteristicUuid,
              properties: BluetoothGattCharacteristic.propertyRead |
                  BluetoothGattCharacteristic.propertyWrite,
              permissions: BluetoothGattCharacteristic.permissionRead |
                  BluetoothGattCharacteristic.permissionWrite)
        ])
      ]);
      var first = peripheral.writeCharacteristicEvent.stream.first;
      var mock = BluetoothManagerMock(peripheral: peripheral);
      var scanResult = await mock.scan().first;
      expect(scanResult.device.name, 'Mock');
      var device = await mock.newConnection(scanResult.device.id);

      var service = BleBluetoothService(uuid: serviceUuid);
      var characteristic = BleBluetoothCharacteristic(
          service: service, uuid: characteristicUuid);
      await device.writeCharacteristic(BleBluetoothCharacteristicValue(
        bc: characteristic,
        value: Uint8List.fromList([1, 2, 3, 4, 5]),
      ));
      expect(
          await first,
          BluetoothPeripheralWriteCharacteristicEvent(
              serviceUuid: serviceUuid,
              characteristicUuid: characteristicUuid,
              value: Uint8List.fromList([1, 2, 3, 4, 5])));
      await mock.close();
    });
  });
}
