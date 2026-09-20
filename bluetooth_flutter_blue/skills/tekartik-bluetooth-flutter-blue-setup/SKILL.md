---
name: tekartik-bluetooth-flutter-blue-setup
description: >-
  Use when a Flutter app (Android, iOS, macOS) implements the tekartik_bluetooth
  central API on top of flutter_blue_plus with tekartik_bluetooth_flutter_blue:
  bluetoothManagerFlutterBlue, BluetoothManagerFlutterBlue,
  bluetoothAdminManagerFlutterBlue, BluetoothFlutterBlue.bluetoothState,
  the bluetooth_flutter.dart and utils/guid_utils.dart imports,
  guidFromUuid/uuidFromGuid/Guid, scan/newConnection/getServices/
  readCharacteristic/registerCharacteristic, and which BluetoothManager members
  (init, getInfo, close, enable, disable, supportsEnable,
  checkBluetoothPermissions) throw UnimplementedError here.
---

# tekartik_bluetooth_flutter_blue: the flutter_blue_plus implementation

`tekartik_bluetooth_flutter_blue` implements the `tekartik_bluetooth` central
(scan/connect/GATT client) API on top of `package:flutter_blue_plus`, so the
same application code runs on Android, iOS and macOS. It is a plain Dart
package, not a plugin: the native side is flutter_blue_plus, and the
platform configuration is flutter_blue_plus' own.

## Guidelines

* Dependency (git, not on pub.dev). Declare `tekartik_bluetooth` too, it holds
  the interfaces:
  ```yaml
  dependencies:
    tekartik_bluetooth:
      git:
        url: https://github.com/tekartik/bluetooth.dart
        path: bluetooth
    tekartik_bluetooth_flutter_blue:
      git:
        url: https://github.com/tekartik/bluetooth.dart
        path: bluetooth_flutter_blue
  ```
  It pulls `flutter_blue_plus` (`>=2.3.4`), `tekartik_app_platform` and
  `tekartik_bluetooth_flutter` (the Android-only Tekartik plugin, which only
  matters if you also use its peripheral API).
* Platform setup is flutter_blue_plus': the app's own
  `AndroidManifest.xml` must declare `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` (and
  `ACCESS_FINE_LOCATION` on older Android), `minSdk` 21+, and the iOS/macOS
  `Info.plist` needs `NSBluetoothAlwaysUsageDescription`. This package adds no
  manifest of its own.
* Imports:
  * `package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart`:
    `bluetoothManagerFlutterBlue` (a `BluetoothManagerFlutterBlue`, i.e. a
    `BluetoothManager`), `bluetoothAdminManagerFlutterBlue` (a
    `BluetoothAdminManager`), the `BluetoothFlutterBlue` helper class, and
    re-exports of `package:tekartik_bluetooth/bluetooth.dart` (`ScanResult`,
    `ScanMode`, `BluetoothDeviceConnection`, `BluetoothInfo`,
    `BluetoothAdminInfo`, `BluetoothPermissionsOptions`...) and
    `bluetooth_state_service.dart`.
  * `package:tekartik_bluetooth/bluetooth_device.dart` for `BluetoothDevice`
    and `BluetoothDeviceId` (not re-exported here),
    `package:tekartik_bluetooth/ble.dart` for the GATT model and
    `package:tekartik_bluetooth/uuid.dart` for `Uuid128`.
  * `package:tekartik_bluetooth_flutter_blue/utils/guid_utils.dart` for
    `guidFromUuid(uuid)`, `uuidFromGuid(guid)` and the flutter_blue_plus `Guid`
    type, when you must bridge to a raw flutter_blue_plus call.
  * Importing `package:flutter_blue_plus/flutter_blue_plus.dart` unqualified in
    the same file clashes on `ScanResult`, `BluetoothDevice` and
    `BluetoothService`: use `show` (or `as native`) for the one native type you
    need, typically `BluetoothAdapterState`.
* Call `platformInit()` from `package:tekartik_app_platform/app_platform.dart`
  in `main()`: `bluetoothAdminManagerFlutterBlue.isAndroid` / `.isIOS` /
  `.supportsEnable` read `platformContext` and answer `false` before that.
* **Only part of `BluetoothManager` is implemented.** These throw
  `UnimplementedError` on `bluetoothManagerFlutterBlue`: `init()`, `getInfo()`,
  `close()`, `enable()`, `disable()`, `supportsEnable`, and the deprecated
  `checkBluetoothPermissions()`/`checkCoarseLocationPermission()`. Implemented:
  `scan()`, `stop()`, `getConnectedDevices()`, `newConnection()`, `isAndroid`,
  `isIOS`. Do not write `await manager.init()` here, unlike the other backends.
* Adapter state goes through `bluetoothAdminManagerFlutterBlue` instead:
  `getAdminInfo()` returns a `BluetoothAdminInfo` (`hasBluetooth` and
  `hasBluetoothBle` = `FlutterBluePlus.isSupported`, `isBluetoothEnabled` =
  adapter state `on`; it never throws, it returns nulls and prints on error),
  `enable()` calls `FlutterBluePlus.turnOn()` and throws
  `StateError('Manual setup needed')` if the adapter is still off, `disable()`
  is a no-op, `supportsEnable` is `isAndroid`.
  `bluetoothAdminManagerFlutterBlue.checkBluetoothPermissions()` also throws
  `UnimplementedError`: ask for the runtime permissions with
  `permission_handler` or let flutter_blue_plus prompt on first scan.
* `BluetoothFlutterBlue.bluetoothState` is a
  `Future<BluetoothAdapterState>` (flutter_blue_plus enum, `unavailable` when
  BLE is not supported): handy for a status widget.
* Scanning: `bluetoothManagerFlutterBlue.scan(withServices: [uuid128, ...])`
  returns a `Stream<ScanResult>`; `withServices` is translated to
  flutter_blue_plus `Guid`s and applied natively, while `scanMode:` is ignored.
  It throws `Exception('Another scan is already in progress')` when
  `FlutterBluePlus.isScanningNow`, so only run one scan and cancel the
  subscription (which calls `FlutterBluePlus.stopScan`) before starting
  another. `manager.stop()` also stops the native scan.
* **The manager keeps a scan cache and `newConnection(deviceId)` only resolves
  ids from it**, otherwise it throws
  `StateError('Scan first before connecting to ...')`. Scan (or call
  `getConnectedDevices()`, which also fills the cache) before connecting; a
  `BluetoothDeviceId` rebuilt from a stored string does not work after a
  restart until it shows up in a scan again.
* Connecting: `connection.connect()` calls flutter_blue_plus with
  `License.nonprofit` and `autoConnect: false`. If the app is commercial,
  connect through flutter_blue_plus yourself with the licence you own rather
  than using this wrapper.
* `getServices()` discovers on first call and caches;
  `discoverServices()` forces a rediscovery. Services whose uuid cannot be
  parsed are skipped with a printed message. Always use the
  `BleBluetoothCharacteristic` objects you got from `getServices()`: lookup is
  by the `BleBluetoothService` instance and the characteristic uuid, and a
  hand-built one throws `StateError('Characteristic ... not found')`.
* Reads time out after 10 s. `readCharacteristic(bc)` gives a
  `BleBluetoothCharacteristicValue` (`value` is a `Uint8List`),
  `writeCharacteristic(bc.withValue(bytes))` writes,
  `registerCharacteristic(bc, true)` maps to `setNotifyValue(true)` and
  `onCharacteristicValueChanged(bc)` streams the values.
* `connection.onConnectionState` only ever emits
  `BluetoothDeviceConnectionState.connected` and `.disconnected` (iOS and
  Android no longer report connecting/disconnecting). `connection.close()` is a
  no-op; `disconnect()` is what releases the link.
* Testing: `flutter test` here only covers the `Guid`/`Uuid128` conversion.
  Unit test the app logic against `BluetoothManagerMock` from
  `package:tekartik_bluetooth/bluetooth_mock.dart` and inject the manager, so
  this package appears in one place only.

## Examples

### Scan with a service filter and list the devices

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';

final myServiceUuid = Uuid128('583df901-b22a-4b8b-aada-24b9517949cd');

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _manager = bluetoothManagerFlutterBlue;
  final _devices = <BluetoothDeviceId, BluetoothDevice>{};
  StreamSubscription<ScanResult>? _subscription;

  @override
  void initState() {
    super.initState();
    // No manager.init() here: it throws UnimplementedError on flutter_blue.
    _subscription = _manager.scan(withServices: [myServiceUuid]).listen((
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var devices = _devices.values.toList();
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(devices[index].name ?? '<no name>'),
        subtitle: Text('${devices[index].id}'),
      ),
    );
  }
}
```

### Check the adapter before scanning

```dart
import 'package:tekartik_app_platform/app_platform.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';

Future<bool> ensureBluetoothReady() async {
  platformInit(); // needed for isAndroid/isIOS/supportsEnable
  var adminManager = bluetoothAdminManagerFlutterBlue;
  var info = await adminManager.getAdminInfo();
  if (info.hasBluetoothBle != true) {
    return false;
  }
  if (info.isBluetoothEnabled != true) {
    if (adminManager.supportsEnable != true) {
      return false; // iOS: the user must enable it in Settings
    }
    try {
      await adminManager.enable(); // FlutterBluePlus.turnOn()
    } on StateError {
      return false;
    }
  }
  return true;
}
```

### Connect, read and subscribe

```dart
import 'dart:async';

import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';

final serviceUuid = Uuid128('583df901-b22a-4b8b-aada-24b9517949cd');
final readUuid = Uuid128('1755e4e0-179b-4e28-bcb7-b2544203ac04');
final notifyUuid = Uuid128('040473f7-2b60-450a-ae9d-36fb630e8a89');

Future<StreamSubscription<BleBluetoothCharacteristicValue>> openDevice(
  BluetoothDeviceId deviceId, // must come from a scan result
  void Function(List<int> value) onValue,
) async {
  var connection = await bluetoothManagerFlutterBlue.newConnection(deviceId);
  await connection.connect();
  var services = await connection.getServices(); // discovers on first call
  var service = services.firstWhere((s) => s.uuid == serviceUuid);
  var readBc = service.characteristics.firstWhere((c) => c.uuid == readUuid);
  var notifyBc = service.characteristics.firstWhere(
    (c) => c.uuid == notifyUuid,
  );

  var bcv = await connection.readCharacteristic(readBc);
  onValue(bcv.value);

  await connection.registerCharacteristic(notifyBc, true);
  return connection
      .onCharacteristicValueChanged(notifyBc)
      .listen((bcv) => onValue(bcv.value));
}
```

### Reconnect to an already connected device

```dart
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';

/// getConnectedDevices() also populates the internal scan cache, so the
/// returned ids can be passed to newConnection() without scanning.
Future<BluetoothDeviceConnection?> reuseConnected(String address) async {
  var devices = await bluetoothManagerFlutterBlue.getConnectedDevices();
  for (var device in devices) {
    if (device.address.toLowerCase() == address.toLowerCase()) {
      return bluetoothManagerFlutterBlue.newConnection(device.id);
    }
  }
  return null;
}
```

### Show the raw flutter_blue_plus adapter state

```dart
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' show BluetoothAdapterState;
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';

class AdapterStateText extends StatelessWidget {
  const AdapterStateText({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BluetoothAdapterState>(
      future: BluetoothFlutterBlue.bluetoothState,
      builder: (context, snapshot) => Text('bluetooth ${snapshot.data}'),
    );
  }
}
```

## Common mistakes

* Calling `bluetoothManagerFlutterBlue.init()`, `getInfo()`, `enable()` or
  `supportsEnable`: they throw `UnimplementedError`. Use
  `bluetoothAdminManagerFlutterBlue` for the adapter state.
* Calling `newConnection()` with an id that the current process never saw in a
  scan or in `getConnectedDevices()`: `StateError('Scan first ...')`.
* Starting a second `scan()` while one is running:
  `Exception('Another scan is already in progress')`.
* Importing `package:flutter_blue_plus/flutter_blue_plus.dart` without `show`
  next to this package: `ScanResult` and `BluetoothDevice` clash.
* Forgetting `platformInit()` and getting `isAndroid == false` everywhere.
* Shipping a commercial app on the built-in `License.nonprofit` connect call.
