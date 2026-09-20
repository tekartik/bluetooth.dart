---
name: tekartik-bluetooth-flutter-setup
description: >-
  Use when a Flutter app talks to BLE devices through the Tekartik Android
  plugin tekartik_bluetooth_flutter: bluetoothManagerFlutter,
  bluetoothAdminManagerFlutter, BluetoothFlutterManager, BluetoothFlutter
  (platformVersion, enableBluetooth, disableBluetooth, connect),
  bluetoothFlutterPlugin, the bluetooth_flutter.dart / bluetooth_manager.dart
  imports, checkBluetoothPermissions/BluetoothPermissionsOptions, getInfo and
  getAdminInfo, scan/ScanResult, newConnection/getServices/readCharacteristic,
  the Android-only limitation and the deprecated bluetoothManager,
  bluetoothService, bluetooth_service.dart and uuid.dart entry points.
---

# tekartik_bluetooth_flutter: the Flutter (Android) plugin

`tekartik_bluetooth_flutter` is a Flutter plugin that implements the
`tekartik_bluetooth` central-role API with a platform channel
(`tekartik_bluetooth_flutter`). Its `pubspec.yaml` only registers an **android**
platform, so this is the Android implementation; for iOS use
`tekartik_bluetooth_flutter_blue` (flutter_blue_plus) instead. It also offers
the peripheral (GATT server) side, covered by the
[tekartik-bluetooth-flutter-peripheral](../tekartik-bluetooth-flutter-peripheral/SKILL.md)
skill.

## Guidelines

* Dependency (git, not on pub.dev). Depend on `tekartik_bluetooth` too: most
  types you name come from there.
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
* Imports, and what each one actually gives you:
  * `package:tekartik_bluetooth_flutter/bluetooth_manager.dart`:
    `bluetoothManagerFlutter` (a `BluetoothFlutterManager`, i.e. a
    `BluetoothManager`), `bluetoothAdminManagerFlutter` (a
    `BluetoothAdminManager`), plus re-exports of `BluetoothDevice`,
    `ScanResult`, `BluetoothDeviceConnection`,
    `BluetoothDeviceConnectionState`, `bluetoothLogLevelNone`,
    `bluetoothLogLevelVerbose`.
  * `package:tekartik_bluetooth_flutter/bluetooth_flutter.dart`: the
    `BluetoothFlutter` static helper class, `bluetoothFlutterPlugin`,
    `BluetoothManager`, `BluetoothStateService`, `BluetoothInfo`.
  * `package:tekartik_bluetooth/bluetooth_device.dart`,
    `package:tekartik_bluetooth/ble.dart`,
    `package:tekartik_bluetooth/uuid.dart`: everything else
    (`BluetoothDeviceId`, `ScanMode`, `BluetoothAdminInfo`,
    `BluetoothPermissionsOptions`, `BleBluetoothService`,
    `BleBluetoothCharacteristic`, `Uuid128`...). These are the same
    declarations, so importing both libraries is not a conflict.
  * Deprecated, do not write in new code:
    `package:tekartik_bluetooth_flutter/bluetooth_service.dart`,
    `package:tekartik_bluetooth_flutter/uuid.dart`, and the getters
    `bluetoothManager`, `bluetoothService`, `flutterBluetoothService`.
* `bluetoothManagerFlutter` and `bluetoothAdminManagerFlutter` are the same
  singleton, exposed under two interfaces; there is no factory and no
  `dispose`. `isAndroid`/`isIOS` are `Platform.isAndroid`/`Platform.isIOS` and
  `supportsEnable` is `Platform.isAndroid`, so touching them (and the plugin at
  all) is unsafe on web: guard the import behind a conditional import or keep
  the mobile code in a mobile-only file.
* Android permissions: the plugin's own `AndroidManifest.xml` already declares
  `BLUETOOTH_SCAN` (with `neverForLocation`), `BLUETOOTH_CONNECT`,
  `BLUETOOTH_ADVERTISE`, the legacy `BLUETOOTH`/`BLUETOOTH_ADMIN` and the
  location permissions, so the app manifest does not need to repeat them. At
  runtime call `await bluetoothAdminManagerFlutter.checkBluetoothPermissions()`
  before the first scan; pass
  `options: BluetoothPermissionsOptions(advertise: true)` when the app also
  advertises. It returns a `bool`, and the native side uses
  `androidRequestCode` (default `30124`) for the permission dialog.
* Lifecycle: `await bluetoothManagerFlutter.init()` when entering the BLE
  screen (it cancels a scan left running by a hot restart) and
  `await bluetoothManagerFlutter.stop()` when leaving (`PopScope`,
  `dispose()`). `getInfo()` returns a `BluetoothInfo` (`hasBluetooth`,
  `hasBluetoothBle`, `isBluetoothEnabled`, `isScanning`, all `bool?`);
  `bluetoothAdminManagerFlutter.getAdminInfo()` returns a `BluetoothAdminInfo`
  with the first three.
* Turning the adapter on: `bluetoothManagerFlutter.enable(androidRequestCode:)`
  (or the equivalent `BluetoothFlutter.enableBluetooth(requestCode:)`) opens the
  system dialog on Android; `disable()` no longer works on Android 13+. Check
  `supportsEnable` first.
* Scanning: `bluetoothManagerFlutter.scan(scanMode: ScanMode.lowLatency)`
  returns a `Stream<ScanResult>`. The native scan starts when the stream is
  built and `stopScan` is invoked when the subscription is cancelled, so keep
  the subscription in the `State` and cancel it in `dispose()`. A new `scan()`
  closes the previous controller: one scan at a time. Results repeat, so dedupe
  on `result.device.id`.
* Connecting: `await bluetoothManagerFlutter.newConnection(deviceId)` allocates
  a native connection id, then `await connection.connect()`,
  `await connection.getServices()`, `readCharacteristic` /
  `writeCharacteristic` / `registerCharacteristic` /
  `onCharacteristicValueChanged` from the `tekartik_bluetooth` API, and
  `disconnect()` + `close()` at the end (`close()` removes the connection from
  the manager, so do it last). `connection.discoverServices()` is deprecated
  here: `getServices()` already asks the native side
  (`remoteGetServices`). `connection.onConnectionState` never emits
  `connecting`/`disconnecting` on Android.
* `BluetoothFlutter` is a thin static wrapper on the method channel:
  `platformVersion`, `enableBluetooth`, `disableBluetooth`,
  `requireBluetoothAdmin`, `connect(address)` and the peripheral entry points.
  Prefer the manager getters; use `BluetoothFlutter` only for what the manager
  does not expose. Its methods `assert` that BLE is supported, so they blow up
  in debug on an emulator without Bluetooth.
* `bluetoothFlutterPlugin` exposes the raw `methodChannel`, `callbackChannel`,
  `connectionChannel` and `writeCharacteristicChannel`; only needed for the
  peripheral side or for debugging.
* `BluetoothOptions` / `devSetOptions` / `bluetoothLogLevelVerbose` are
  `@Deprecated('Dev only')`: do not ship calls to them.
* Testing: this package's `dart test` equivalent is `flutter test`, and it only
  covers the map serialisation (`test/invoke_test.dart`); the plugin needs a
  real Android device. Unit test app logic against `BluetoothManagerMock` from
  `package:tekartik_bluetooth/bluetooth_mock.dart` and inject the manager
  rather than calling `bluetoothManagerFlutter` from deep inside widgets.

## Examples

### Widget that scans and lists devices

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _manager = bluetoothManagerFlutter;
  final _devices = <BluetoothDeviceId, BluetoothDevice>{};
  StreamSubscription<ScanResult>? _subscription;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!await bluetoothAdminManagerFlutter.checkBluetoothPermissions()) {
      return;
    }
    await _manager.init();
    _subscription = _manager.scan(scanMode: ScanMode.lowLatency).listen((
      result,
    ) {
      if (!_devices.containsKey(result.device.id)) {
        setState(() => _devices[result.device.id] = result.device);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel(); // stops the native scan
    _manager.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var devices = _devices.values.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(devices[index].name ?? '<no name>'),
          subtitle: Text('${devices[index].id}'),
        ),
      ),
    );
  }
}
```

### Make sure Bluetooth is usable before scanning

```dart
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';

Future<bool> ensureBluetoothReady({bool advertise = false}) async {
  var manager = bluetoothManagerFlutter;
  var adminManager = bluetoothAdminManagerFlutter;

  var adminInfo = await adminManager.getAdminInfo();
  if (adminInfo.hasBluetoothBle != true) {
    return false;
  }
  var granted = await adminManager.checkBluetoothPermissions(
    options: BluetoothPermissionsOptions(advertise: advertise),
  );
  if (!granted) {
    return false;
  }
  if (adminInfo.isBluetoothEnabled != true) {
    if (manager.supportsEnable != true) {
      return false;
    }
    await manager.enable(androidRequestCode: 30123);
  }
  await manager.init();
  return true;
}
```

### Connect and read a characteristic

```dart
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';

final sigBaseUuid = Uuid128('00000000-0000-1000-8000-00805f9b34fb');
final batteryServiceUuid = sigBaseUuid.withUuid16(Uuid16.fromValue(0x180f));
final batteryLevelUuid = sigBaseUuid.withUuid16(Uuid16.fromValue(0x2a19));

Future<int?> readBatteryLevel(BluetoothDeviceId deviceId) async {
  var connection = await bluetoothManagerFlutter.newConnection(deviceId);
  try {
    await connection.connect();
    // no discoverServices() here: it is deprecated on the flutter plugin
    var services = await connection.getServices();
    var bc = services
        .firstWhere((s) => s.uuid == batteryServiceUuid)
        .characteristics
        .firstWhere((c) => c.uuid == batteryLevelUuid);
    var bcv = await connection.readCharacteristic(bc);
    return bcv.value.first;
  } finally {
    await connection.disconnect();
    connection.close();
  }
}
```

### Plain platform information from the plugin

```dart
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';

Future<void> logPlatform() async {
  // ignore: avoid_print
  print('android version ${await BluetoothFlutter.platformVersion}');
  var info = await bluetoothManagerFlutter.getInfo();
  // ignore: avoid_print
  print('ble ${info.hasBluetoothBle} on ${info.isBluetoothEnabled}');
}
```

## Common mistakes

* Using this plugin on iOS or web: it only registers an Android platform. Pick
  `tekartik_bluetooth_flutter_blue` for a cross-platform Flutter app.
* Scanning without `checkBluetoothPermissions()` on Android 12+: the scan
  silently returns nothing.
* Not cancelling the scan subscription in `dispose()`.
* Calling `connection.close()` before `disconnect()`, or never calling it: the
  connection stays in the manager's map.
* Using the deprecated `bluetoothManager`, `bluetoothService`,
  `flutterBluetoothService`, `bluetooth_service.dart` or the package's own
  `uuid.dart` instead of `bluetoothManagerFlutter` and
  `package:tekartik_bluetooth/uuid.dart`.
