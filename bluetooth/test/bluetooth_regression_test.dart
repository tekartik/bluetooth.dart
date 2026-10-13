// ignore_for_file: implementation_imports
import 'dart:typed_data';

import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/src/mixin.dart';
import 'package:tekartik_bluetooth/src/mock/manager_mock.dart';
import 'package:tekartik_bluetooth/src/mock/peripheral_mock.dart';
import 'package:tekartik_bluetooth/utils/ble_utils.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:test/test.dart';

class _AdminManager with BluetoothAdminManagerMixin {
  final calls = <MapEntry<String, Object?>>[];

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) async {
    calls.add(MapEntry(method, arguments));
    return true as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('regression', () {
    test('checkBluetoothPermissions uses the options request code', () async {
      var manager = _AdminManager();
      await manager.checkBluetoothPermissions(
        options: BluetoothPermissionsOptions(androidRequestCode: 0xb7e),
      );
      await manager.checkBluetoothPermissions();
      await manager.checkBluetoothPermissions(
        androidRequestCode: 12,
        options: BluetoothPermissionsOptions(androidRequestCode: 0xb7e),
      );
      expect(manager.calls.map((call) => call.value).toList(), [
        {'androidRequestCode': 0xb7e},
        {'androidRequestCode': requestCodeCheckBluetoothPermissions},
        {'androidRequestCode': 12},
      ]);
    });

    test('secureWrite is not the signed write property', () {
      expect(propertiesValueToPropertyFlags(blePropertySignedWrite), {
        BleCharacteristicPropertyFlag.authenticatedSignedWrites,
      });
      expect(
        propertyFlagsToPropertyValue({
          BleCharacteristicPropertyFlag.secureWrite,
        }),
        0,
      );
    });

    test('mock registerCharacteristic on/off', () async {
      var serviceUuid = Uuid128('0000180f-0000-1000-8000-00805f9b34fb');
      var characteristicUuid = Uuid128('00002a19-0000-1000-8000-00805f9b34fb');
      var peripheral = BluetoothPeripheralMock(
        deviceName: 'mock',
        services: [
          BluetoothGattService(
            uuid: serviceUuid,
            characteristics: [
              BluetoothGattCharacteristic(
                uuid: characteristicUuid,
                properties: BluetoothGattCharacteristic.propertyNotify,
                permissions: BluetoothGattCharacteristic.permissionRead,
              ),
            ],
          ),
        ],
      );
      var mock = BluetoothManagerMock(peripheral: peripheral);
      var scanResult = await mock.scan().first;
      var device = await mock.newConnection(scanResult.device.id);
      var service = (await device.getServices()).first;
      var characteristic = BleBluetoothCharacteristic(
        service: service,
        uuid: characteristicUuid,
      );
      var values = <List<int>>[];
      var subscription = device
          .onCharacteristicValueChanged(characteristic)
          .listen((value) => values.add(value.value));
      Future<void> notify(int value) async {
        await peripheral.setAndNotifyCharacteristicValue(
          serviceUuid: serviceUuid,
          characteristicUuid: characteristicUuid,
          value: Uint8List.fromList([value]),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      // Not registered
      await notify(0);
      expect(values, isEmpty);

      // Registered twice, notified once
      await device.registerCharacteristic(characteristic, true);
      await device.registerCharacteristic(characteristic, true);
      await notify(1);
      expect(values, [
        [1],
      ]);

      // Unregistered
      await device.registerCharacteristic(characteristic, false);
      await notify(2);
      expect(values, [
        [1],
      ]);

      await subscription.cancel();
      await mock.close();
    });
  });
}
