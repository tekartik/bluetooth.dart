---
name: tekartik-bluetooth-bluez-setup
description: >-
  Use when running tekartik_bluetooth code on Linux through BlueZ and D-Bus
  with tekartik_bluetooth_bluez: bluetoothManagerBluez,
  debugBluetoothManagerBluez, the bluetooth_bluez.dart import, scanning with
  BlueZ discovery, newConnection/connect/discoverServices/getServices,
  readCharacteristic/writeCharacteristic/registerCharacteristic, which parts
  of BluetoothManager and BluetoothAdminManager are unimplemented on Linux
  (init, stop, enable, disable, getConnectedDevices,
  checkBluetoothPermissions), and writing a Linux command line BLE client.
---

# tekartik_bluetooth_bluez: the Linux (BlueZ) implementation

`tekartik_bluetooth_bluez` implements the `tekartik_bluetooth` central-role API
on Linux, on top of `package:bluez` and `package:dbus` (the system bus, the
`bluetoothd` daemon). Write the application code against the
`tekartik_bluetooth` interfaces and only mention this package where the manager
instance is picked.

## Guidelines

* Dependency (git, not on pub.dev). It brings `tekartik_bluetooth` along, but
  declare that one too since the interfaces come from it:
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
* `package:tekartik_bluetooth_bluez/bluetooth_bluez.dart` is the only public
  library and it exports exactly two names: `bluetoothManagerBluez` (a
  `BluetoothManagerBluez`, which is both a `BluetoothManager` and a
  `BluetoothAdminManager`) and `debugBluetoothManagerBluez`, a `bool` flag you
  set to `true` to trace connect/read/write/notify on stdout. Everything else
  (`BluetoothDeviceBluezImpl`, `ScanResultBluezImpl`, the bluez uuid helpers)
  is under `src/`: do not import it. The API types (`BluetoothManager`,
  `ScanResult`, `BleBluetoothService`, `Uuid128`...) come from
  `package:tekartik_bluetooth/bluetooth_device.dart`,
  `package:tekartik_bluetooth/ble.dart` and
  `package:tekartik_bluetooth/uuid.dart`.
* Linux only: the getter connects to the D-Bus system bus on first use. It
  needs a running `bluetoothd` and a user allowed to talk to it. There is no
  compile-time guard, so keep the import out of web/Android/iOS code paths.
* `bluetoothManagerBluez` is a single shared instance for the whole process,
  not a factory: the scan state and the connection ids are global. Do not try
  to run two independent scans.
* Prerequisite check: `await bluetoothManagerBluez.getAdminInfo()` returns a
  `BluetoothAdminInfo` where `isBluetoothEnabled` is true when BlueZ reports at
  least one adapter (`hasBluetooth` and `hasBluetoothBle` are always true on
  this implementation). `getInfo()` returns the same values plus `isScanning`
  (`null` until the first scan). `isAndroid` and `isIOS` are both `false`.
* Not implemented on Linux, they throw `UnimplementedError` (they are the
  Android platform-channel parts of the mixin): `getConnectedDevices()`,
  `checkBluetoothPermissions()`, `enable()`, `disable()`. `supportsEnable` is
  `false`. Enable the adapter with `bluetoothctl power on` / `rfkill unblock
  bluetooth` outside the app.
* `init()` and `stop()` do not throw but do nothing useful here (they swallow
  the underlying `UnimplementedError`); calling them is harmless, relying on
  them is not. `close()` is a no-op too.
* Scanning: `bluetoothManagerBluez.scan()` returns a `Stream<ScanResult>`.
  BlueZ discovery starts when you listen and stops when you cancel the
  subscription, so always keep the `StreamSubscription` and cancel it. The
  `scanMode:` and `withServices:` parameters are accepted but ignored by this
  implementation: filter on `result.device` yourself. Devices BlueZ already
  knows (paired or recently seen) are emitted immediately on listen, then new
  ones as they are discovered; dedupe on `result.device.id`. `result.rssi`
  comes straight from BlueZ.
* Device ids are the Bluetooth address (`AA:BB:CC:DD:EE:FF`), and `==` on
  `BluetoothDeviceId` is case insensitive.
* `newConnection(deviceId)` only accepts an id seen by the **current** scan
  (the scan results of the running `ScanServicesBluez`); anything else throws
  `StateError('Device id ... not found')`. Scan first, then connect, and do not
  cancel the scan before calling `newConnection`.
* Connecting: `await connection.connect()`. `connection.onConnectionState`
  reports `BluetoothDeviceConnectionState.connecting`, then `connected` or
  `disconnected` (this implementation does emit `connecting`/`disconnecting`,
  unlike Android and iOS). Listening to it replays the current state.
* **Call `await connection.discoverServices()` after `connect()`**: BlueZ
  resolves the GATT tree asynchronously and `getServices()` returns whatever is
  cached right now, so on a fresh connection it returns an empty list.
  `discoverServices()` polls until `servicesResolved` (or gattServices are
  non-empty) and throws `StateError('Unable to resolve services')` after 30 s.
* Read/write/notify take the `BleBluetoothCharacteristic` objects returned by
  `getServices()`; a hand-built one is looked up by service uuid +
  characteristic uuid and throws `StateError('Characteristic ... not found')`
  when BlueZ does not expose it. `readCharacteristic(bc)` returns a
  `BleBluetoothCharacteristicValue` (`bcv.value` is a `Uint8List`);
  `writeCharacteristic(bc.withValue(bytes))` writes;
  `registerCharacteristic(bc, true)` maps to BlueZ `StartNotify` and
  `onCharacteristicValueChanged(bc)` streams the values (register first, then
  listen, and `registerCharacteristic(bc, false)` when done).
* `connection.close()` disconnects and releases the D-Bus subscriptions; call
  it in a `finally`. Errors from BlueZ are rethrown as `DBusMethodResponseException`
  and friends from `package:dbus`, so catch broadly around connect and read.
* Command line programs: the D-Bus system bus connection stays open and keeps
  the Dart VM alive after your work is done. End the program with `exit(0)`
  from `dart:io`.
* Testing: there is no hardware-free test here (`dart test` only runs the uuid
  conversion test). Unit test the logic against `BluetoothManagerMock` from
  `package:tekartik_bluetooth/bluetooth_mock.dart` and keep this package to the
  one line that picks the manager.

## Examples

### Scan for 5 seconds and list the devices

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

  var devices = <BluetoothDeviceId, BluetoothDevice>{};
  var subscription = manager.scan().listen((result) {
    if (devices.putIfAbsent(result.device.id, () => result.device) ==
        result.device) {
      print('${result.device.id} ${result.device.name} rssi ${result.rssi}');
    }
  });
  await Future<void>.delayed(const Duration(seconds: 5));
  await subscription.cancel();
  exit(0); // the dbus system bus connection keeps the VM alive
}
```

### Connect to a device found by name and read a characteristic

```dart
import 'dart:async';
import 'dart:io';

import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_bluez/bluetooth_bluez.dart';

final sigBaseUuid = Uuid128('00000000-0000-1000-8000-00805f9b34fb');
final batteryServiceUuid = sigBaseUuid.withUuid16(Uuid16.fromValue(0x180f));
final batteryLevelUuid = sigBaseUuid.withUuid16(Uuid16.fromValue(0x2a19));

Future<void> main(List<String> args) async {
  var wantedName = args.first;
  var manager = bluetoothManagerBluez;

  // Keep the scan alive: newConnection only knows the current scan results.
  var completer = Completer<BluetoothDeviceId>();
  var subscription = manager.scan().listen((result) {
    if (result.device.name == wantedName && !completer.isCompleted) {
      completer.complete(result.device.id);
    }
  });
  var deviceId = await completer.future.timeout(const Duration(seconds: 20));

  var connection = await manager.newConnection(deviceId);
  try {
    await connection.connect();
    await connection.discoverServices(); // needed: bluez resolves lazily
    var services = await connection.getServices();
    var bc = services
        .firstWhere((s) => s.uuid == batteryServiceUuid)
        .characteristics
        .firstWhere((c) => c.uuid == batteryLevelUuid);
    var bcv = await connection.readCharacteristic(bc);
    print('battery ${bcv.value.first}%');
  } finally {
    await connection.disconnect();
    connection.close();
    await subscription.cancel();
  }
  exit(0);
}
```

### Listen to notifications with the debug trace on

```dart
import 'dart:async';

import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_bluez/bluetooth_bluez.dart';

Future<StreamSubscription<BleBluetoothCharacteristicValue>> notify(
  BluetoothDeviceConnection connection,
  Uuid128 serviceUuid,
  Uuid128 characteristicUuid,
) async {
  debugBluetoothManagerBluez = true; // traces bluez calls on stdout
  await connection.discoverServices();
  var bc = (await connection.getServices())
      .firstWhere((s) => s.uuid == serviceUuid)
      .characteristics
      .firstWhere((c) => c.uuid == characteristicUuid);
  await connection.registerCharacteristic(bc, true); // bluez StartNotify
  return connection.onCharacteristicValueChanged(bc).listen((bcv) {
    print('${bcv.uuid} ${bcv.value}');
  });
}
```

### Follow the connection state

```dart
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_bluez/bluetooth_bluez.dart';

Future<void> watch(BluetoothDeviceId deviceId) async {
  var connection = await bluetoothManagerBluez.newConnection(deviceId);
  // bluez does emit connecting/disconnecting, Android and iOS do not.
  connection.onConnectionState.listen((state) {
    switch (state) {
      case BluetoothDeviceConnectionState.connected:
        print('connected');
      case BluetoothDeviceConnectionState.disconnected:
        print('disconnected');
      default:
        print('state $state');
    }
  });
  await connection.connect();
}
```

## Common mistakes

* Calling `getServices()` right after `connect()` and getting an empty list:
  `discoverServices()` first.
* Cancelling the scan subscription before `newConnection()`: the device id is
  then unknown and `newConnection` throws a `StateError`.
* Expecting `scanMode:` or `withServices:` to do anything on BlueZ.
* Calling `getConnectedDevices()`, `checkBluetoothPermissions()`, `enable()`
  or `disable()` on Linux: they throw `UnimplementedError`.
* Forgetting `exit(0)` in a CLI and wondering why the program hangs.
* Importing `package:tekartik_bluetooth_bluez/src/...` for the impl classes
  instead of programming against the `tekartik_bluetooth` interfaces.
