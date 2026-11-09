# tekartik_bluetooth

The common Bluetooth Low Energy API of the bluetooth.dart repo: a
`BluetoothManager` to scan and connect, a `BluetoothDeviceConnection` to read,
write and listen to GATT characteristics, uuid helpers, and mocks to test
without a radio. Pure Dart (runs everywhere); the radio access comes from an
implementation package of the same repo:

| Package                         | Platform                                     | Manager                       |
|---------------------------------|----------------------------------------------|-------------------------------|
| `tekartik_bluetooth_flutter`    | Flutter Android (central and peripheral)     | `bluetoothManagerFlutter`     |
| `tekartik_bluetooth_flutter_blue` | Flutter (flutter_blue_plus)                | `bluetoothManagerFlutterBlue` |
| `tekartik_bluetooth_bluez`      | Linux (BlueZ over D-Bus)                     | `bluetoothManagerBluez`       |
| `tekartik_bluetooth_web`        | browser (Web Bluetooth)                      | `bluetoothManagerWeb`         |
| this package                    | tests, anywhere                              | `BluetoothManagerMock`        |

## Getting started

The packages are not on pub.dev, add them as git dependencies (this one in
shared code, an implementation in the app):

```yaml
dependencies:
  tekartik_bluetooth:
    git:
      url: https://github.com/tekartik/bluetooth.dart
      path: bluetooth
```

Write the logic against `BluetoothManager`, run it here with the mock:

```dart
import 'dart:typed_data';

import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/bluetooth_mock.dart';
import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/uuid.dart';

final sigBaseUuid = Uuid128('00000000-0000-1000-8000-00805f9b34fb');
final batteryServiceUuid = sigBaseUuid.withUuid16(Uuid16.fromValue(0x180f));
final batteryLevelUuid = sigBaseUuid.withUuid16(Uuid16.fromValue(0x2a19));

/// Works with any manager: bluetooth_flutter, bluez, web or the mock.
Future<int> readBatteryLevel(BluetoothManager manager) async {
  var scanResult = await manager
      .scan(withServices: [batteryServiceUuid])
      .first; // cancels the scan
  var connection = await manager.newConnection(scanResult.device.id);
  try {
    await connection.connect();
    var services = await connection.getServices();
    var bc = services
        .firstWhere((service) => service.uuid == batteryServiceUuid)
        .characteristics
        .firstWhere((bc) => bc.uuid == batteryLevelUuid);
    var bcv = await connection.readCharacteristic(bc);
    return bcv.value.first;
  } finally {
    await connection.disconnect();
    connection.close();
  }
}

Future<void> main() async {
  // A simulated device (no radio needed), with a battery level of 42.
  var peripheral = BluetoothPeripheralMock(
    services: [
      BluetoothGattService(
        uuid: batteryServiceUuid,
        characteristics: [
          BluetoothGattCharacteristic(
            uuid: batteryLevelUuid,
            properties: BluetoothGattCharacteristic.propertyRead,
            permissions: BluetoothGattCharacteristic.permissionRead,
          ),
        ],
      ),
    ],
  );
  await peripheral.setCharacteristicValue(
    serviceUuid: batteryServiceUuid,
    characteristicUuid: batteryLevelUuid,
    value: Uint8List.fromList([42]),
  );
  print(await readBatteryLevel(BluetoothManagerMock(peripheral: peripheral))); // 42
}
```

## Libraries

* `bluetooth_device.dart`: `BluetoothManager` (`scan`, `newConnection`,
  `getConnectedDevices`, `init`, `stop`, `getInfo`), `BluetoothDevice`,
  `BluetoothDeviceId`, `ScanResult`, `ScanMode`, `BluetoothDeviceConnection`,
  `BluetoothDeviceConnectionState`.
* `ble.dart`: the GATT model (`BleBluetoothService`,
  `BleBluetoothCharacteristic`, `BleBluetoothCharacteristicValue`,
  `blePropertyRead`...).
* `uuid.dart`: `Uuid128` (any 8-4-4-4-12 hex text, vendor uuids included),
  `Uuid16`, `Uuid32`.
* `bluetooth_peripheral.dart`: the peripheral side (advertising, GATT server)
  and `BluetoothGattService`/`BluetoothGattCharacteristic`.
* `bluetooth_mock.dart`: `BluetoothManagerMock`, `BluetoothAdminManagerMock`,
  `BluetoothPeripheralMock`.

## Common pitfalls

* Cancel the scan subscription (or take `.first`): the scan runs until then.
  A new `scan()` ends the previous stream.
* Use the services and characteristics returned by `getServices()` for reads
  and writes, not hand built ones.
* On Android call `checkBluetoothPermissions()` of the admin manager before
  scanning.
* `withServices` is only applied by bluetooth_flutter (Android) and
  flutter_blue; filter the results yourself elsewhere.

Agent skills: [skills/tekartik-bluetooth-client](skills/tekartik-bluetooth-client/SKILL.md)
(scan, connect, read, write, notify) and
[skills/tekartik-bluetooth-mock](skills/tekartik-bluetooth-mock/SKILL.md)
(tests with the mocks).
