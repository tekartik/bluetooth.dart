# tekartik_bluetooth_bluez

The Linux implementation of the [tekartik_bluetooth](../bluetooth/README.md)
API (Bluetooth Low Energy central role): scan, connect, read, write and
notify through the BlueZ daemon (`bluetoothd`) over the D-Bus system bus, with
[package:bluez](https://pub.dev/packages/bluez). Pure Dart: a command line
program or a Flutter Linux app.

## Getting started

The package is not on pub.dev, add it (and the common API) as git
dependencies:

```yaml
dependencies:
  tekartik_bluetooth:
    git:
      url: https://github.com/tekartik/bluetooth.dart
      path: bluetooth
  tekartik_bluetooth_bluez:
    git:
      url: https://github.com/tekartik/bluetooth.dart
      path: bluetooth_bluez
```

Needs a running `bluetoothd`, a powered adapter (`bluetoothctl power on`) and a
user allowed to use BlueZ on the system bus (the default on a desktop
session).

Scan for 5 seconds and print the devices:

```dart
import 'dart:io';

import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_bluez/bluetooth_bluez.dart';

Future<void> main() async {
  var manager = bluetoothManagerBluez;
  var adminInfo = await manager.getAdminInfo();
  if (adminInfo.isBluetoothEnabled != true) {
    stderr.writeln('no bluetooth adapter (try: bluetoothctl power on)');
    exit(1);
  }
  var seen = <BluetoothDeviceId>{};
  var subscription = manager.scan().listen((result) {
    if (seen.add(result.device.id)) {
      print('${result.device.id} ${result.device.name} rssi ${result.rssi}');
    }
  });
  await Future<void>.delayed(const Duration(seconds: 5));
  await subscription.cancel(); // stops the BlueZ discovery
  exit(0); // the D-Bus connection keeps the program alive
}
```

Then write the logic against `BluetoothManager` (see the
[tekartik_bluetooth example](../bluetooth/README.md#getting-started)) and only
pick `bluetoothManagerBluez` at startup.

## What works on Linux

* `scan()`: starts the BlueZ discovery on listen, stops it on cancel. Devices
  BlueZ already knows come first, then the new ones. `withServices` sets the
  BlueZ discovery filter and only keeps the devices advertising one of the
  services; `scanMode` is ignored.
* `newConnection(deviceId)` for a device of the last scan, then `connect()`,
  `discoverServices()`, `getServices()`, `readCharacteristic()`,
  `writeCharacteristic()`, `registerCharacteristic()` and
  `onCharacteristicValueChanged()`.
* `getInfo()`, `getAdminInfo()`: `isBluetoothEnabled` is true when BlueZ has an
  adapter.
* Not available (they throw `UnimplementedError`): `enable()`, `disable()`,
  `getConnectedDevices()`, `checkBluetoothPermissions()`.

## Common pitfalls

* Call `discoverServices()` after `connect()`: BlueZ resolves the services
  after the connection, `getServices()` returns what it has so far. It throws
  a `StateError` after 30 seconds without services.
* `newConnection()` only knows the devices of the last scan: scan first.
* End a command line program with `exit(0)`.
* `bluetoothManagerBluez` is one instance for the process: one scan at a time
  (a new `scan()` ends the previous stream).
* Set `debugBluetoothManagerBluez = true` to trace the BlueZ calls.

Agent skill:
[skills/tekartik-bluetooth-bluez-setup](skills/tekartik-bluetooth-bluez-setup/SKILL.md).
