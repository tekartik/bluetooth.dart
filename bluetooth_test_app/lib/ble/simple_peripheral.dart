import 'dart:typed_data';

import 'package:tekartik_bluetooth_test_app/import/common_import.dart';
import 'package:tekartik_bluetooth_test_app/import/import_bluetooth.dart';

final simpleServiceUuid128 = Uuid128('583df901-b22a-4b8b-aada-24b9517949cd');

final simpleCharacteristicWriteUuid128 =
    Uuid128('ce724d50-7471-41e1-b60a-0e3c1bf0179a');
final simpleCharacteristicReadUuid128 =
    Uuid128('1755e4e0-179b-4e28-bcb7-b2544203ac04');
final simpleCharacteristicTimeIndicateUuid128 =
    Uuid128('48766b55-436e-430e-a1b6-86b0e0b45a94');
final simpleCharacteristicTimeNotifyUuid128 =
    Uuid128('040473f7-2b60-450a-ae9d-36fb630e8a89');

List<BluetoothGattService> gattServices = <BluetoothGattService>[
  BluetoothGattService(
      uuid: simpleServiceUuid128,
      characteristics: <BluetoothGattCharacteristic>[
        BluetoothGattCharacteristic(
            uuid: simpleCharacteristicWriteUuid128,
            properties: BluetoothGattCharacteristic.propertyWrite,
            permissions: BluetoothGattCharacteristic.permissionWrite,
            description: 'SimpleWrite'),
        BluetoothGattCharacteristic(
            uuid: simpleCharacteristicReadUuid128,
            properties: BluetoothGattCharacteristic.propertyRead,
            permissions: BluetoothGattCharacteristic.permissionRead,
            description: 'SimpleRead'),
        BluetoothGattCharacteristic(
            uuid: simpleCharacteristicTimeIndicateUuid128,
            properties: BluetoothGattCharacteristic.propertyIndicate,
            permissions: 0,
            description: 'TimeIndicate'),
        BluetoothGattCharacteristic(
            uuid: simpleCharacteristicTimeNotifyUuid128,
            properties: BluetoothGattCharacteristic.propertyNotify,
            permissions: 0,
            description: 'TimeNotify'),
      ])
];

class SimplePeripheral {
  final String deviceName;
  BluetoothPeripheral? bluetoothPeripheral;

  SimplePeripheral({required this.deviceName}) {
    _onConnectedController.add(connectedDevices);
  }

  var connectedDevices = <String>[];
  final _onConnectedController = StreamController<List<String>>.broadcast();
  final _onWrittenController = StreamController<Uint8List?>.broadcast();

  Stream<List<String>> get onConnectedDeviceList =>
      _onConnectedController.stream;

  Stream<Uint8List?> get onValueWritten => _onWrittenController.stream;

  Future<void> startAdvertising() async {
    try {
      // If we include the device name we get:
      // ADVERTISE_FAILED_DATA_TOO_LARGE
      await bluetoothPeripheral?.startAdvertising(
          advertiseData: AdvertiseData(services: <AdvertiseDataService>[
        AdvertiseDataService(uuid: simpleServiceUuid128)
      ], includeDeviceName: false));
    } catch (e) {
      print(e); // ignore: avoid_print
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await bluetoothPeripheral?.stopAdvertising();
    } catch (e) {
      print('stopAdvertising errir $e'); // ignore: avoid_print
    }
  }

  Future<void> dispose() async {
    _onConnectedController.close().unawait();
    await stopAdvertising();
    try {
      await bluetoothPeripheral?.close();
    } catch (e) {
      print('close error $e'); // ignore: avoid_print
    }
  }

  Future<void> init({bool startAdvertisting = true}) async {
    try {
      if (bluetoothPeripheral == null) {
        var peripheral = bluetoothPeripheral =
            await BluetoothFlutter.initPeripheral(
                services: gattServices, deviceName: deviceName);
        peripheral.onWriteCharacteristic().listen((event) {
          print('onWriteCharacteristic: $event'); // ignore: avoid_print
          _onWrittenController.add(event.value);
        });
        peripheral.onSlaveConnectionChanged().listen((connection) {
          // ignore: avoid_print
          print('onSlaveConnectionChanged: $connection');
          var list = List<String>.from(connectedDevices);
          if (connection.connected ?? false) {
            var address = connection.address ?? '??:??:??:??:??:??';
            if (!list.contains(address)) {
              list.add(address);
            }
          } else {
            list.remove(connection.address);
          }
          connectedDevices = list;
          _onConnectedController.add(list);
        });
      }

      if (startAdvertisting) {
        await startAdvertising();
      }
    } catch (e) {
      print(e); // ignore: avoid_print
    }
  }

  Future<void> close() async {
    await stopAdvertising();
    try {
      await bluetoothPeripheral?.close();
    } catch (e) {
      print(e); // ignore: avoid_print
    }
  }

  void notifyConnectedDevices() {
    var text = utf8.encode(DateTime.now().toIso8601String());
    // ignore: avoid_print
    print(text);
    var value = asUint8List(text);
    bluetoothPeripheral!.notifyCharacteristicValue(
        serviceUuid: simpleServiceUuid128,
        characteristicUuid: simpleCharacteristicTimeIndicateUuid128,
        value: value);
    bluetoothPeripheral!.notifyCharacteristicValue(
        serviceUuid: simpleServiceUuid128,
        characteristicUuid: simpleCharacteristicTimeNotifyUuid128,
        value: value);
    bluetoothPeripheral!.setCharacteristicValue(
        serviceUuid: simpleServiceUuid128,
        characteristicUuid: simpleCharacteristicReadUuid128,
        value: value);
  }
}
