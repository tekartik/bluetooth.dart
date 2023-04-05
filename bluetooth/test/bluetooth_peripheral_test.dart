import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/src/uuid.dart';
import 'package:test/test.dart';

var _service1Uuid = Uuid128('d9fc68cc-0051-41b1-bea0-815c875607c3');
var _service2Uuid = Uuid128('e37f33a6-40d1-41b5-be15-9e6bbad8011b');
var _characteristic1Uuid = Uuid128('fee68ebe-c170-4c15-87c0-6c1cc1863913');
var _characteristic2Uuid = Uuid128('56adb822-7a90-4d45-90ec-b8710207282a');

void main() {
  group('BluetoothGattService', () {
    test('findGettServices', () {
      var gattServices = [
        BluetoothGattService(
            uuid: _service1Uuid,
            characteristics: <BluetoothGattCharacteristic>[
              BluetoothGattCharacteristic(
                  uuid: _characteristic1Uuid,
                  properties: BluetoothGattCharacteristic.propertyWrite,
                  permissions: BluetoothGattCharacteristic.permissionWrite,
                  description: 'Command'),
              BluetoothGattCharacteristic(
                  uuid: _characteristic2Uuid,
                  properties: BluetoothGattCharacteristic.propertyIndicate,
                  permissions: 0,
                  description: 'Indicate'),
            ])
      ];
      expect(
          gattServices
              .findGattCharacteristic(BleBluetoothCharacteristic(
                  service: BleBluetoothService(uuid: _service1Uuid),
                  uuid: _characteristic1Uuid))!
              .uuid,
          _characteristic1Uuid);
      expect(
          gattServices.findGattCharacteristic(BleBluetoothCharacteristic(
              service: BleBluetoothService(uuid: _service2Uuid),
              uuid: _characteristic1Uuid)),
          isNull);
    });
  });
}
