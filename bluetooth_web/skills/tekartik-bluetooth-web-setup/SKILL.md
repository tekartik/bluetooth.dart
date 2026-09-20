---
name: tekartik-bluetooth-web-setup
description: >-
  Use when running tekartik_bluetooth code in a browser on top of Web Bluetooth
  with tekartik_bluetooth_web: bluetoothManagerWeb, BluetoothManagerWeb,
  webRequestDevice, BluetoothRequestDeviceOptionsWeb,
  BluetoothRequestDeviceFilterWeb (name, namePrefix, services,
  acceptAllDevices, optionalServices), the bluetooth_web.dart import, the
  device chooser and its user-gesture/secure-context requirements, getInfo and
  getAdminInfo, scan and newConnection, and the GATT operations
  (getServices, readCharacteristic, writeCharacteristic,
  registerCharacteristic) that still throw UnimplementedError here.
---

# tekartik_bluetooth_web: the Web Bluetooth implementation

`tekartik_bluetooth_web` maps the `tekartik_bluetooth` API onto the browser Web
Bluetooth API through `package:flutter_web_bluetooth`. It is **partial**: device
selection and connect/disconnect work, the GATT operations do not yet. Read the
limitations below before designing around it.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_bluetooth:
      git:
        url: https://github.com/tekartik/bluetooth.dart
        path: bluetooth
    tekartik_bluetooth_web:
      git:
        url: https://github.com/tekartik/bluetooth.dart
        path: bluetooth_web
  ```
  It pulls `flutter_web_bluetooth` from the fork
  `https://github.com/tekartikdev/flutter_web_bluetooth.git`, so do not also
  depend on the pub.dev `flutter_web_bluetooth`: pub will not resolve both.
* Browser only, and only where Web Bluetooth exists: Chrome, Edge and other
  Chromium browsers, over **https or `http://localhost`**. Firefox and Safari
  have no Web Bluetooth. Check `chrome://bluetooth-internals` and
  `chrome://flags` when debugging. There is no compile guard, so keep this
  import out of VM/Flutter-native code paths.
* `package:tekartik_bluetooth_web/bluetooth_web.dart` exports exactly four
  names: `bluetoothManagerWeb` (a `BluetoothManagerWeb`, which is both a
  `BluetoothManager` and a `BluetoothAdminManager`), `BluetoothManagerWeb`,
  `BluetoothRequestDeviceOptionsWeb` and `BluetoothRequestDeviceFilterWeb`.
  Everything else comes from `package:tekartik_bluetooth/bluetooth_device.dart`,
  `ble.dart` and `uuid.dart`.
* Feature check: `await bluetoothManagerWeb.getInfo()` (or `getAdminInfo()`)
  answers `hasBluetooth`, `hasBluetoothBle` and `isBluetoothEnabled`, all three
  set to `FlutterWebBluetooth.instance.isBluetoothApiSupported`. `isAndroid`
  and `isIOS` are `false`.
* **`webRequestDevice()` is the entry point.** The browser has no free-running
  scan: the user must pick a device in the native chooser.
  `await bluetoothManagerWeb.webRequestDevice(options)` opens it and returns
  the chosen `BluetoothDevice`. It **must be called from a user gesture**
  (a click/tap handler); calling it from `main()` or a timer throws a
  `SecurityError` from the browser, and a cancelled chooser throws too, so wrap
  it in try/catch.
* Options: `BluetoothRequestDeviceOptionsWeb(acceptAllDevices: true, optionalServices: [...])`
  lists everything, or `acceptAllDevices: false` with
  `filters: [BluetoothRequestDeviceFilterWeb(namePrefix: 'MyDev', services: [...])]`.
  The uuids in `services` and `optionalServices` are **lowercase uuid strings**
  (`'0000180f-0000-1000-8000-00805f9b34fb'`), not `Uuid128` objects; use
  `uuid.toString()`. A service the page will ever touch must appear in
  `filters[].services` or in `optionalServices`, or the browser blocks access
  to it.
* `scan()` does not scan the radio: it streams the devices the user has already
  granted for this origin (`FlutterWebBluetooth.instance.devices`), as
  `ScanResult`s whose `rssi` is always `0`. Use it to repopulate the device
  list on reload, and `webRequestDevice()` to add a new one. Cancel the
  subscription as usual.
* `newConnection(deviceId)` only resolves ids that this manager has seen, from
  `webRequestDevice()` or from the `scan()` stream; anything else throws
  `StateError('device id ... not found')`.
* `connection.connect()` / `disconnect()` work, and
  `connection.onConnectionState` emits `connecting` then `connected`, or
  `disconnected` on failure. **`connect()` never throws**: it catches the error
  and emits `disconnected`, so listen to `onConnectionState` (subscribe before
  calling `connect()`: the controller is a broadcast without replay) instead of
  relying on the future. `connection.close()` is a no-op.
* **Not implemented yet**, they throw `UnimplementedError`:
  `discoverServices()`, `getServices()`, `readCharacteristic()`,
  `writeCharacteristic()`, `registerCharacteristic()` and
  `onCharacteristicValueChanged()` on the connection, and on the manager
  `getConnectedDevices()`, `checkBluetoothPermissions()`, `enable()` and
  `disable()` (`supportsEnable` is `false`). For actual GATT traffic in a
  browser today, drop to `package:flutter_web_bluetooth` directly
  (`FlutterWebBluetooth.instance`, `device.discoverServices()`), or keep the
  shared code on the `tekartik_bluetooth` interfaces and implement the web side
  yourself.
* `init()` and `stop()` are inherited no-ops here (they swallow the underlying
  `UnimplementedError`); calling them is harmless.
* Running the demo: `web/main.dart` in this package is a
  `tekartik_test_menu_browser` page exercising `isBluetoothApiSupported`,
  `isAvailable` and `requestDevice`; serve it with
  `dart run build_runner serve` and open it in Chrome.
* Testing: nothing here is unit testable without a browser and a user. Test the
  logic against `BluetoothManagerMock` from
  `package:tekartik_bluetooth/bluetooth_mock.dart` and inject the manager.

## Examples

### Ask the user to pick a device (from a click handler)

```dart
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_web/bluetooth_web.dart';

final batteryServiceUuid = Uuid128('0000180f-0000-1000-8000-00805f9b34fb');

/// Wire this to a button click: the browser chooser needs a user gesture.
Future<BluetoothDevice?> pickDevice() async {
  var info = await bluetoothManagerWeb.getInfo();
  if (info.hasBluetoothBle != true) {
    return null; // no Web Bluetooth in this browser
  }
  try {
    return await bluetoothManagerWeb.webRequestDevice(
      BluetoothRequestDeviceOptionsWeb(
        acceptAllDevices: false,
        filters: [
          BluetoothRequestDeviceFilterWeb(
            namePrefix: 'MyDevice',
            services: [batteryServiceUuid.toString()],
          ),
        ],
        // every service the page may use must be declared up front
        optionalServices: [batteryServiceUuid.toString()],
      ),
    );
  } catch (_) {
    return null; // chooser cancelled, or no user gesture
  }
}
```

### Accept any device but declare the services used

```dart
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_web/bluetooth_web.dart';

final deviceInfoServiceUuid = Uuid128('0000180a-0000-1000-8000-00805f9b34fb');
final batteryServiceUuid = Uuid128('0000180f-0000-1000-8000-00805f9b34fb');

Future<BluetoothDevice> pickAnyDevice() {
  return bluetoothManagerWeb.webRequestDevice(
    BluetoothRequestDeviceOptionsWeb(
      acceptAllDevices: true,
      optionalServices: [
        deviceInfoServiceUuid.toString(),
        batteryServiceUuid.toString(),
      ],
    ),
  );
}
```

### Connect and follow the state

```dart
import 'dart:async';

import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_web/bluetooth_web.dart';

Future<bool> connectTo(BluetoothDeviceId deviceId) async {
  var connection = await bluetoothManagerWeb.newConnection(deviceId);
  var completer = Completer<bool>();
  // subscribe first: connect() never throws, it only emits disconnected
  var subscription = connection.onConnectionState.listen((state) {
    if (completer.isCompleted) {
      return;
    }
    if (state == BluetoothDeviceConnectionState.connected) {
      completer.complete(true);
    } else if (state == BluetoothDeviceConnectionState.disconnected) {
      completer.complete(false);
    }
  });
  try {
    await connection.connect();
    return await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => false,
    );
  } finally {
    await subscription.cancel();
  }
}
```

### Repopulate the list of already granted devices

```dart
import 'dart:async';

import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_web/bluetooth_web.dart';

/// scan() streams the devices this origin was already granted, not a radio
/// scan, and rssi is always 0.
Future<List<BluetoothDevice>> knownDevices() async {
  var devices = <BluetoothDeviceId, BluetoothDevice>{};
  var subscription = bluetoothManagerWeb.scan().listen((result) {
    devices[result.device.id] = result.device;
  });
  await Future<void>.delayed(const Duration(milliseconds: 500));
  await subscription.cancel();
  return devices.values.toList();
}
```

## Common mistakes

* Calling `webRequestDevice()` outside a click handler, or on `http://` other
  than localhost: the browser refuses.
* Expecting `scan()` to discover new devices: only `webRequestDevice()` can add
  one.
* Forgetting to list a service in `optionalServices` (or in a filter) and then
  being blocked from it by the browser.
* Passing `Uuid128` objects where the web options want lowercase uuid
  `String`s.
* Writing GATT code against this package: `getServices()`,
  `readCharacteristic()`, `writeCharacteristic()` and
  `registerCharacteristic()` throw `UnimplementedError`.
* Relying on `connect()` throwing on failure, or on `rssi` being meaningful.
