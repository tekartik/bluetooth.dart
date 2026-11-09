# tekartik_bluetooth_flutter

The Flutter Android plugin implementing the
[tekartik_bluetooth](../bluetooth/README.md) API (Bluetooth Low Energy): the
central role (scan, connect, read) and the peripheral role (GATT server,
advertising). Android only: the plugin registers no other platform (use
`tekartik_bluetooth_flutter_blue` for iOS).

## Getting started

The package is not on pub.dev, add it (and the common API) as git
dependencies:

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

The plugin's manifest declares the Bluetooth permissions; ask for them at
runtime, then scan:

```dart
import 'dart:async';

import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';

/// Scans for 5 seconds and returns the devices found.
Future<List<BluetoothDevice>> scanDevices() async {
  if (!await bluetoothAdminManagerFlutter.checkBluetoothPermissions()) {
    return [];
  }
  var devices = <BluetoothDeviceId, BluetoothDevice>{};
  var subscription = bluetoothManagerFlutter.scan().listen((result) {
    devices[result.device.id] = result.device;
  });
  await Future<void>.delayed(const Duration(seconds: 5));
  await subscription.cancel(); // stops the native scan
  return devices.values.toList();
}
```

Then `newConnection(device.id)`, `connect()`, `discoverServices()` (Android
only lists the services once discovered), `getServices()` and
`readCharacteristic()`, as in the
[tekartik_bluetooth example](../bluetooth/README.md#getting-started).

## What works on Android

* Central: `scan()` (`scanMode`, `withServices` as Android scan filters),
  `newConnection()`, `connect()`, `disconnect()`, `discoverServices()`,
  `getServices()`, `readCharacteristic()`, `getInfo()`, `getAdminInfo()`,
  `checkBluetoothPermissions()`, `enable()`.
* Not implemented yet (they throw `UnimplementedError`):
  `writeCharacteristic()`, `registerCharacteristic()`,
  `onCharacteristicValueChanged()`.
* Peripheral: `BluetoothFlutter.initPeripheral()` then advertising and
  characteristic values, see the
  [peripheral skill](skills/tekartik-bluetooth-flutter-peripheral/SKILL.md).

## Common pitfalls

* Call `checkBluetoothPermissions()` before the first scan (Android 12+
  `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT`, location before); pass
  `BluetoothPermissionsOptions(advertise: true)` for the peripheral role.
* Cancel the scan subscription. Prefer one `scan()` at a time: a new one ends
  the previous stream.
* `connection.close()` after `disconnect()`, last.

Agent skills:
[skills/tekartik-bluetooth-flutter-setup](skills/tekartik-bluetooth-flutter-setup/SKILL.md)
(central) and
[skills/tekartik-bluetooth-flutter-peripheral](skills/tekartik-bluetooth-flutter-peripheral/SKILL.md).
