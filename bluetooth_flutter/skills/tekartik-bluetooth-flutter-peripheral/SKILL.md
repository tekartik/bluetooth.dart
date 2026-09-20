---
name: tekartik-bluetooth-flutter-peripheral
description: >-
  Use when a Flutter app acts as a BLE peripheral / GATT server with
  tekartik_bluetooth_flutter: BluetoothFlutter.initPeripheral,
  BluetoothPeripheral (startAdvertising, stopAdvertising, close,
  setCharacteristicValue, notifyCharacteristicValue,
  setAndNotifyCharacteristicValue, onWriteCharacteristic,
  onSlaveConnectionChanged), BluetoothGattService,
  BluetoothGattCharacteristic with its propertyRead/propertyWrite/
  propertyNotify/propertyIndicate and permissionRead/permissionWrite
  constants, AdvertiseData/AdvertiseDataService, BluetoothSlaveConnection,
  BluetoothPeripheralWriteCharacteristicEvent and the
  bluetooth_flutter_peripheral.dart import.
---

# tekartik_bluetooth_flutter: peripheral (GATT server) role

`tekartik_bluetooth_flutter` can make the Android device itself a BLE
peripheral: it publishes a GATT server built from `BluetoothGattService`
definitions and advertises it. Only Android is registered as a plugin platform,
so this is Android only. The central (scan and connect) side of the same
package is covered by the
[tekartik-bluetooth-flutter-setup](../tekartik-bluetooth-flutter-setup/SKILL.md)
skill.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_bluetooth:
      git:
        url: https://github.com/tekartik/bluetooth.dart
        path: bluetooth
    tekartik_bluetooth_flutter:
      git:
        url: https://github.com/tekartik/bluetooth.dart
        path: bluetooth_flutter
  ```
* Imports: `package:tekartik_bluetooth_flutter/bluetooth_flutter_peripheral.dart`
  for the peripheral model (`BluetoothPeripheral`, `BluetoothGattService`,
  `BluetoothGattCharacteristic`, `AdvertiseData`, `AdvertiseDataService`,
  `BluetoothSlaveConnection`, `BluetoothPeripheralWriteCharacteristicEvent`,
  `BluetoothPeripheralInitData`, `BluetoothPeripheralPlugin`,
  `bluetoothPluginNamespace`, plus `BluetoothManager` and
  `BluetoothStateService`), `package:tekartik_bluetooth_flutter/bluetooth_flutter.dart`
  for `BluetoothFlutter` and `bluetoothFlutterPlugin`, and
  `package:tekartik_bluetooth/uuid.dart` for `Uuid128`.
* Permissions: the plugin manifest already declares `BLUETOOTH_ADVERTISE`, but
  it is a runtime permission on Android 12+. Call
  `await bluetoothAdminManagerFlutter.checkBluetoothPermissions(options: BluetoothPermissionsOptions(advertise: true))`
  (from `package:tekartik_bluetooth_flutter/bluetooth_manager.dart` and
  `package:tekartik_bluetooth/bluetooth_device.dart`) before advertising.
* Describe the server first: a `List<BluetoothGattService>`, each
  `BluetoothGattService(uuid: Uuid128(...), characteristics: [...])`, each
  `BluetoothGattCharacteristic(uuid:, properties:, permissions:, description:)`.
  `properties` and `permissions` are `int` bit masks built from the static
  constants on `BluetoothGattCharacteristic`: `propertyBroadcast`,
  `propertyRead`, `propertyWriteNoResponse`, `propertyWrite`, `propertyNotify`,
  `propertyIndicate`, `propertySignedWrite`, `propertyExtendedProps`, and
  `permissionRead`, `permissionReadEncrypted`, `permissionReadEncryptedMitm`,
  `permissionWrite`, `permissionWriteEncrypted`, `permissionWriteEncryptedMitm`,
  `permissionsWriteSigned`, `permissionWriteSignedMitm`. Combine with `|`. A
  notify-only characteristic uses `permissions: 0`.
* Create the server with
  `var peripheral = await BluetoothFlutter.initPeripheral(services: services, deviceName: 'my-device')`,
  which returns a `BluetoothPeripheral` bound to `bluetoothFlutterPlugin`.
  Do it once and keep the instance; a second `initPeripheral` re-registers the
  services natively.
* Advertise with `peripheral.startAdvertising(advertiseData: AdvertiseData(services: [AdvertiseDataService(uuid: serviceUuid)], includeDeviceName: false))`
  and stop with `peripheral.stopAdvertising()`. The legacy static
  `BluetoothFlutter.startAdvertising` / `stopAdvertising` do the same on the
  current peripheral; prefer the instance methods. **Keep the advertisement
  small**: the legacy advertising payload is 31 bytes, so a 128-bit service uuid
  plus `includeDeviceName: true` fails with `ADVERTISE_FAILED_DATA_TOO_LARGE`.
  Advertise the name or the uuid, not both.
* Serve values: `setCharacteristicValue(serviceUuid:, characteristicUuid:, value:)`
  stores the value read by centrals, `notifyCharacteristicValue(...)` pushes a
  notification/indication to the subscribed centrals, and
  `setAndNotifyCharacteristicValue(...)` does both (the usual call). `value` is
  a `Uint8List?`.
* Events: `peripheral.onWriteCharacteristic()` is a
  `Stream<BluetoothPeripheralWriteCharacteristicEvent>` (`serviceUuid`,
  `characteristicUuid`, `value`), and `peripheral.onSlaveConnectionChanged()`
  reports the connected centrals (`address`, `connected`). Both come from
  broadcast event channels: subscribe once, keep the `StreamSubscription` and
  cancel it. Note the element type of `onSlaveConnectionChanged()` is a plugin
  internal class, so bind it with `var`/`(connection)` rather than naming it;
  the static `BluetoothFlutter.onSlaveConnectionChanged()` gives the publicly
  named `BluetoothSlaveConnection` instead.
* Shut down in this order: `stopAdvertising()`, cancel the subscriptions, then
  `await peripheral.close()` (releases the native GATT server). Wrap each in
  try/catch: the native side throws when the adapter went off in between.
* Finding a characteristic from the central-side model: the
  `findGattCharacteristic(bc)` extensions on `BluetoothGattService` and on
  `Iterable<BluetoothGattService>` map a `BleBluetoothCharacteristic` back to
  the `BluetoothGattCharacteristic` you declared.
* Testing: `BluetoothGattService.toMap()`, `BluetoothPeripheral.toMap()` and
  `AdvertiseData.toMap()` are what goes over the channel and are pure Dart, so
  assert on them in `flutter test` (see `test/invoke_test.dart`); build the
  peripheral with `plugin: null` for such a test and never call its methods.
  Everything else needs a real Android device.

## Examples

### Declare a service and start advertising

```dart
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter_peripheral.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';

final simpleServiceUuid = Uuid128('583df901-b22a-4b8b-aada-24b9517949cd');
final writeUuid = Uuid128('ce724d50-7471-41e1-b60a-0e3c1bf0179a');
final readUuid = Uuid128('1755e4e0-179b-4e28-bcb7-b2544203ac04');
final notifyUuid = Uuid128('040473f7-2b60-450a-ae9d-36fb630e8a89');

final gattServices = <BluetoothGattService>[
  BluetoothGattService(
    uuid: simpleServiceUuid,
    characteristics: <BluetoothGattCharacteristic>[
      BluetoothGattCharacteristic(
        uuid: writeUuid,
        properties: BluetoothGattCharacteristic.propertyWrite,
        permissions: BluetoothGattCharacteristic.permissionWrite,
        description: 'SimpleWrite',
      ),
      BluetoothGattCharacteristic(
        uuid: readUuid,
        properties: BluetoothGattCharacteristic.propertyRead,
        permissions: BluetoothGattCharacteristic.permissionRead,
        description: 'SimpleRead',
      ),
      BluetoothGattCharacteristic(
        uuid: notifyUuid,
        properties: BluetoothGattCharacteristic.propertyNotify,
        permissions: 0,
        description: 'TimeNotify',
      ),
    ],
  ),
];

Future<BluetoothPeripheral?> startPeripheral(String deviceName) async {
  var granted = await bluetoothAdminManagerFlutter.checkBluetoothPermissions(
    options: BluetoothPermissionsOptions(advertise: true),
  );
  if (!granted) {
    return null;
  }
  var peripheral = await BluetoothFlutter.initPeripheral(
    services: gattServices,
    deviceName: deviceName,
  );
  await peripheral.startAdvertising(
    advertiseData: AdvertiseData(
      services: <AdvertiseDataService>[
        AdvertiseDataService(uuid: simpleServiceUuid),
      ],
      // true + a 128 bit uuid overflows the 31 byte advertisement
      includeDeviceName: false,
    ),
  );
  return peripheral;
}
```

### Push a value and react to writes

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter_peripheral.dart';

class CounterPeripheral {
  final BluetoothPeripheral peripheral;
  final Uuid128 serviceUuid;
  final Uuid128 notifyUuid;
  final _subscriptions = <StreamSubscription<Object?>>[];

  CounterPeripheral(this.peripheral, this.serviceUuid, this.notifyUuid);

  void listen() {
    _subscriptions.add(
      peripheral.onWriteCharacteristic().listen((event) {
        // ignore: avoid_print
        print('written ${event.characteristicUuid} ${event.value}');
      }),
    );
    // the element type is plugin internal: bind it with var
    _subscriptions.add(
      peripheral.onSlaveConnectionChanged().listen((connection) {
        // ignore: avoid_print
        print('${connection.address} connected ${connection.connected}');
      }),
    );
  }

  Future<void> publish(int value) => peripheral.setAndNotifyCharacteristicValue(
    serviceUuid: serviceUuid,
    characteristicUuid: notifyUuid,
    value: Uint8List.fromList([value & 0xff]),
  );

  Future<void> dispose() async {
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
    try {
      await peripheral.stopAdvertising();
    } catch (_) {}
    try {
      await peripheral.close();
    } catch (_) {}
  }
}
```

### Watch the connected centrals with the static stream

```dart
import 'dart:async';

import 'package:tekartik_bluetooth_flutter/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter_peripheral.dart';

StreamSubscription<BluetoothSlaveConnection> watchCentrals(
  void Function(List<String> addresses) onChanged,
) {
  var addresses = <String>[];
  return BluetoothFlutter.onSlaveConnectionChanged().listen((connection) {
    var address = connection.address ?? '??:??:??:??:??:??';
    if (connection.connected ?? false) {
      if (!addresses.contains(address)) {
        addresses = [...addresses, address];
      }
    } else {
      addresses = addresses.where((item) => item != address).toList();
    }
    onChanged(addresses);
  });
}
```

### Unit test the channel payload without a device

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter_peripheral.dart';

void main() {
  test('peripheral map', () {
    var peripheral = BluetoothPeripheral(
      services: <BluetoothGattService>[
        BluetoothGattService(
          uuid: Uuid128('36c9159b-6cc6-43b3-b198-ac03cc44949e'),
          characteristics: <BluetoothGattCharacteristic>[
            BluetoothGattCharacteristic(
              uuid: Uuid128('b5b15bf1-0215-464e-815b-0d88e261e56a'),
              properties:
                  BluetoothGattCharacteristic.propertyNotify |
                  BluetoothGattCharacteristic.propertyRead,
              permissions: BluetoothGattCharacteristic.permissionRead,
            ),
          ],
        ),
      ],
      plugin: null, // no channel: only toMap() is safe to call
    );
    expect(peripheral.toMap(), {
      'services': [
        {
          'uuid': '36c9159b-6cc6-43b3-b198-ac03cc44949e',
          'characteristics': [
            {
              'properties': 18,
              'permissions': 1,
              'uuid': 'b5b15bf1-0215-464e-815b-0d88e261e56a',
            },
          ],
        },
      ],
    });
  });
}
```

## Common mistakes

* `ADVERTISE_FAILED_DATA_TOO_LARGE`: a 128-bit service uuid plus
  `includeDeviceName: true` does not fit in the advertisement.
* Advertising on Android 12+ without asking for `BLUETOOTH_ADVERTISE` through
  `checkBluetoothPermissions(options: BluetoothPermissionsOptions(advertise: true))`.
* Calling `initPeripheral` again on every rebuild instead of keeping the
  `BluetoothPeripheral` instance.
* Only calling `setCharacteristicValue` and expecting subscribed centrals to be
  woken up: use `notifyCharacteristicValue` or
  `setAndNotifyCharacteristicValue`.
* Forgetting `peripheral.close()`: the native GATT server and the advertisement
  survive the screen.
* Expecting the peripheral role on iOS or web: the plugin is Android only.
