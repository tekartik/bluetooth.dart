---
name: tekartik-bluetooth-mock
description: >-
  Use when unit testing Bluetooth code without hardware using the in-memory
  mocks of tekartik_bluetooth: BluetoothManagerMock,
  BluetoothAdminManagerMock, BluetoothPeripheralMock, the bluetooth_mock.dart
  import, wiring a fake peripheral (BluetoothGattService /
  BluetoothGattCharacteristic) to a BluetoothManager, scan/newConnection/
  connect/getServices/readCharacteristic/writeCharacteristic/
  registerCharacteristic against it, setCharacteristicValue,
  getCharacteristicValue, notifyCharacteristicValue, startAdvertising and
  writeCharacteristicEvent in `dart test`.
---

# tekartik_bluetooth mocks (tekartik_bluetooth)

`package:tekartik_bluetooth/bluetooth_mock.dart` ships an in-memory central and
an in-memory peripheral that talk to each other, so application code written
against `BluetoothManager` can be tested with plain `dart test`, with no radio,
no platform channel and no device. The real API is described in the
[tekartik-bluetooth-client](../tekartik-bluetooth-client/SKILL.md) skill.

## Guidelines

* The mocks live in the main package, so no extra dependency:
  ```yaml
  dependencies:
    tekartik_bluetooth:
      git:
        url: https://github.com/tekartik/bluetooth.dart
        path: bluetooth
  ```
* `package:tekartik_bluetooth/bluetooth_mock.dart` exports exactly three names:
  `BluetoothManagerMock`, `BluetoothAdminManagerMock` and
  `BluetoothPeripheralMock`. Everything else (`BluetoothGattService`,
  `BluetoothGattCharacteristic`, `BleBluetoothService`, `Uuid128`,
  `BluetoothDeviceConnectionState`) comes from
  `package:tekartik_bluetooth/bluetooth_peripheral.dart`, `ble.dart`,
  `bluetooth_device.dart` and `uuid.dart` as usual.
* Design for injection: take a `BluetoothManager` (and a
  `BluetoothAdminManager` where needed) as a constructor parameter, pass the
  real `bluetoothManagerFlutter`/`bluetoothManagerBluez`/... in `main()`, and
  the mock in tests. Never call a platform getter from inside the logic you
  want to test.
* The peripheral is the source of truth. Build a
  `BluetoothPeripheralMock(deviceName: 'mock', services: [...])` from the same
  `BluetoothGattService` / `BluetoothGattCharacteristic` definitions the real
  device exposes, then pass it to
  `BluetoothManagerMock(peripheral: peripheral)` (`peripheral:` is required and
  may be `null`, in which case `scan()` emits nothing).
* `BluetoothManagerMock` behaviour: `scan()` yields **one** `ScanResult` and
  then completes (device `name` `'Mock'`, `id.id` `'mock'`, `address`
  `'mock_address'`, `rssi` 50), whatever `scanMode:`/`withServices:` say;
  `getInfo()` always reports `hasBluetooth`, `hasBluetoothBle` and
  `isBluetoothEnabled` true plus the current `isScanning`; `init()`,
  `stop()`, `close()`, `enable()` and `disable()` are no-ops;
  `supportsEnable` is `false`; `getConnectedDevices()` returns the public
  mutable `connectedDevices` list, so set it in the test to simulate an already
  connected device; `invokeMethod()` throws `UnsupportedError`.
* `newConnection(deviceId)` accepts **any** id and returns a connection backed
  by the peripheral. `connect()` / `disconnect()` push
  `BluetoothDeviceConnectionState.connected` / `.disconnected` into a seeded
  broadcast stream (`onConnectionState` starts at `disconnected`, so
  `await connection.onConnectionState.first` is a reliable assertion).
  `discoverServices()` is a no-op and `getServices()` converts the peripheral's
  `BluetoothGattService`s into `BleBluetoothService`s, keeping uuids and the
  `properties` bit mask.
* Reading: `readCharacteristic(bc)` reads the value stored on the peripheral.
  **Seed it first** with
  `await peripheral.setCharacteristicValue(serviceUuid:, characteristicUuid:, value:)`;
  reading a service that was never written throws
  `StateError('service not found <uuid>')`, and a known service with an unset
  characteristic gives an empty `Uint8List`.
* Writing: `connection.writeCharacteristic(bc.withValue(bytes))` stores the
  value on the peripheral and pushes a
  `BluetoothPeripheralWriteCharacteristicEvent` on
  `peripheral.writeCharacteristicEvent.stream` — the way to assert "the app
  sent this". Its element type is public
  (`bluetooth_peripheral.dart`), the subject wrapper type is not: bind the
  stream with `var`.
* Notifications: `await connection.registerCharacteristic(bc, true)` subscribes
  the connection to the peripheral, then
  `await peripheral.notifyCharacteristicValue(serviceUuid:, characteristicUuid:, value:)`
  makes `connection.onCharacteristicValueChanged(bc)` emit. Register **before**
  listening and before notifying, `value:` must not be null, and note the `on`
  flag is ignored (`registerCharacteristic(bc, false)` does not unsubscribe, and
  each call adds a listener): call it once per characteristic.
* `BluetoothAdminManagerMock()` is standalone (no peripheral):
  `checkBluetoothPermissions()` and `checkCoarseLocationPermission()` return
  `true`, `getAdminInfo()` reports everything available and enabled, `enable()`
  and `disable()` are no-ops, `supportsEnable` is `false`, and `invokeMethod()`
  throws `UnimplementedError`. Use it wherever the code asks for permissions.
* `BluetoothPeripheralMock` is also useful on its own to test peripheral-side
  code: `startAdvertising(advertiseData:)` stores the `AdvertiseData` in the
  public `advertiseData` field (`null` after `stopAdvertising()`), and
  `getCharacteristicValue(...)` reads back what the app published.
* Run them with `dart test` (no `@TestOn`): the mocks are pure Dart and work on
  the VM and in the browser.

## Examples

### A fake battery device end to end

```dart
import 'dart:typed_data';

import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/bluetooth_mock.dart';
import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:test/test.dart';

final batteryServiceUuid = Uuid128('0000180f-0000-1000-8000-00805f9b34fb');
final batteryLevelUuid = Uuid128('00002a19-0000-1000-8000-00805f9b34fb');

BluetoothPeripheralMock newBatteryPeripheral() => BluetoothPeripheralMock(
  deviceName: 'mock',
  services: [
    BluetoothGattService(
      uuid: batteryServiceUuid,
      characteristics: [
        BluetoothGattCharacteristic(
          uuid: batteryLevelUuid,
          properties:
              BluetoothGattCharacteristic.propertyRead |
              BluetoothGattCharacteristic.propertyNotify,
          permissions: BluetoothGattCharacteristic.permissionRead,
        ),
      ],
    ),
  ],
);

void main() {
  test('read the battery level', () async {
    var peripheral = newBatteryPeripheral();
    // seed the value: reading an unwritten service throws
    await peripheral.setCharacteristicValue(
      serviceUuid: batteryServiceUuid,
      characteristicUuid: batteryLevelUuid,
      value: Uint8List.fromList([42]),
    );
    var manager = BluetoothManagerMock(peripheral: peripheral);

    var scanResult = await manager.scan().first; // exactly one result
    var connection = await manager.newConnection(scanResult.device.id);
    await connection.connect();
    expect(
      await connection.onConnectionState.first,
      BluetoothDeviceConnectionState.connected,
    );

    var services = await connection.getServices();
    var bc = services
        .firstWhere((s) => s.uuid == batteryServiceUuid)
        .characteristics
        .firstWhere((c) => c.uuid == batteryLevelUuid);
    var bcv = await connection.readCharacteristic(bc);
    expect(bcv.value.first, 42);

    await connection.disconnect();
    await manager.close();
  });
}
```

### Assert what the code wrote to the device

```dart
import 'dart:typed_data';

import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/bluetooth_mock.dart';
import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:test/test.dart';

final serviceUuid = Uuid128('583df901-b22a-4b8b-aada-24b9517949cd');
final commandUuid = Uuid128('ce724d50-7471-41e1-b60a-0e3c1bf0179a');

void main() {
  test('write is seen by the peripheral', () async {
    var peripheral = BluetoothPeripheralMock(
      deviceName: 'mock',
      services: [
        BluetoothGattService(
          uuid: serviceUuid,
          characteristics: [
            BluetoothGattCharacteristic(
              uuid: commandUuid,
              properties: BluetoothGattCharacteristic.propertyWrite,
              permissions: BluetoothGattCharacteristic.permissionWrite,
            ),
          ],
        ),
      ],
    );
    var manager = BluetoothManagerMock(peripheral: peripheral);
    var connection = await manager.newConnection(BluetoothDeviceId('mock'));
    await connection.connect();
    var bc = (await connection.getServices())
        .firstWhere((s) => s.uuid == serviceUuid)
        .characteristics
        .firstWhere((c) => c.uuid == commandUuid);

    var events = peripheral.writeCharacteristicEvent.stream;
    var next = events.first;
    await connection.writeCharacteristic(
      bc.withValue(Uint8List.fromList([1, 2])),
    );

    var event = await next;
    expect(event.serviceUuid, serviceUuid);
    expect(event.characteristicUuid, commandUuid);
    expect(event.value, [1, 2]);
  });
}
```

### Notifications from the fake peripheral

```dart
import 'dart:typed_data';

import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/bluetooth_mock.dart';
import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:test/test.dart';

final serviceUuid = Uuid128('583df901-b22a-4b8b-aada-24b9517949cd');
final notifyUuid = Uuid128('040473f7-2b60-450a-ae9d-36fb630e8a89');

void main() {
  test('notification reaches the central', () async {
    var peripheral = BluetoothPeripheralMock(
      deviceName: 'mock',
      services: [
        BluetoothGattService(
          uuid: serviceUuid,
          characteristics: [
            BluetoothGattCharacteristic(
              uuid: notifyUuid,
              properties: BluetoothGattCharacteristic.propertyNotify,
              permissions: 0,
            ),
          ],
        ),
      ],
    );
    var manager = BluetoothManagerMock(peripheral: peripheral);
    var connection = await manager.newConnection(BluetoothDeviceId('mock'));
    await connection.connect();
    var bc = (await connection.getServices())
        .firstWhere((s) => s.uuid == serviceUuid)
        .characteristics
        .firstWhere((c) => c.uuid == notifyUuid);

    // register once, then listen, then notify
    await connection.registerCharacteristic(bc, true);
    var next = connection.onCharacteristicValueChanged(bc).first;
    await peripheral.notifyCharacteristicValue(
      serviceUuid: serviceUuid,
      characteristicUuid: notifyUuid,
      value: Uint8List.fromList([7]),
    );
    expect((await next).value, [7]);
  });
}
```

### Permissions and adapter state without a device

```dart
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/bluetooth_mock.dart';
import 'package:test/test.dart';

/// Application code takes the interfaces, never the platform getters.
Future<bool> ensureReady(
  BluetoothManager manager,
  BluetoothAdminManager adminManager,
) async {
  var info = await adminManager.getAdminInfo();
  if (info.hasBluetoothBle != true) {
    return false;
  }
  if (!await adminManager.checkBluetoothPermissions()) {
    return false;
  }
  await manager.init();
  return true;
}

void main() {
  test('ready with the mocks', () async {
    var manager = BluetoothManagerMock(
      peripheral: BluetoothPeripheralMock(deviceName: 'mock'),
    );
    expect(await ensureReady(manager, BluetoothAdminManagerMock()), isTrue);
  });
}
```

## Common mistakes

* Calling `readCharacteristic` before `peripheral.setCharacteristicValue`:
  `StateError('service not found ...')`.
* Expecting `scan()` to keep emitting: the mock yields one result and closes.
* Listening to `onCharacteristicValueChanged` without
  `registerCharacteristic(bc, true)` first, or notifying before listening (the
  notification subject does not replay).
* Calling `registerCharacteristic(bc, false)` and expecting it to unsubscribe.
* Building a `BluetoothPeripheralMock` whose services do not match the real
  device: the test passes and the app fails on hardware.
* Calling `invokeMethod` on the mocks: `UnsupportedError` /
  `UnimplementedError`.
