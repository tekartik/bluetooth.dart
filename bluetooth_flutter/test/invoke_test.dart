import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter_peripheral.dart';

void main() {
  group('invoke', () {
    test('AdvertiseData', () {
      var advertiseData = AdvertiseData(services: <AdvertiseDataService>[
        AdvertiseDataService(
            uuid: Uuid128('36c9159b-6cc6-43b3-b198-ac03cc44949e'))
      ]);
      expect(advertiseData.toMap(), {
        'services': [
          {'uuid': '36c9159b-6cc6-43b3-b198-ac03cc44949e'}
        ]
      });
    });

    test('Peripheral', () {
      var peripheral = BluetoothPeripheral(services: <BluetoothGattService>[
        BluetoothGattService(
            uuid: Uuid128('36c9159b-6cc6-43b3-b198-ac03cc44949e'),
            characteristics: <BluetoothGattCharacteristic>[
              BluetoothGattCharacteristic(
                  uuid: Uuid128('b5b15bf1-0215-464e-815b-0d88e261e56a'),
                  properties: BluetoothGattCharacteristic.propertyNotify |
                      BluetoothGattCharacteristic.propertyRead,
                  permissions: BluetoothGattCharacteristic.permissionRead)
            ])
      ], plugin: null);
      expect(peripheral.toMap(), {
        'services': [
          {
            'uuid': '36c9159b-6cc6-43b3-b198-ac03cc44949e',
            'characteristics': [
              {
                'properties': 18,
                'permissions': 1,
                'uuid': 'b5b15bf1-0215-464e-815b-0d88e261e56a'
              }
            ]
          }
        ]
      });
    });
  });
}
