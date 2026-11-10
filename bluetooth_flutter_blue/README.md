# tekartik_bluetooth_flutter_blue

The [tekartik_bluetooth](../bluetooth/README.md) central API (scan, connect,
read, write, notifications) on top of
[flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus): the same
application code on Android, iOS and macOS. A plain Dart package, not a
plugin: the native side and its platform setup are flutter_blue_plus'.

## Getting started

Not on pub.dev, add it (and the common API) as git dependencies:

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

Do the platform setup of flutter_blue_plus in the app (Android
`BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` permissions, iOS and macOS
`NSBluetoothAlwaysUsageDescription`), then scan:

```dart
import 'dart:async';

import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';

/// Scans for [duration] and returns the devices found.
Future<List<BluetoothDevice>> scanDevices({
  Duration duration = const Duration(seconds: 5),
}) async {
  var devices = <BluetoothDeviceId, BluetoothDevice>{};
  var subscription = bluetoothManagerFlutterBlue.scan().listen((result) {
    devices[result.device.id] = result.device;
  });
  await Future<void>.delayed(duration);
  await subscription.cancel(); // stops the native scan
  return devices.values.toList();
}
```

Then connect and read a characteristic:

```dart
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';

/// The battery service and its level characteristic (16 bit uuids, given
/// in full).
final batteryServiceUuid = Uuid128('0000180f-0000-1000-8000-00805f9b34fb');
final batteryLevelUuid = Uuid128('00002a19-0000-1000-8000-00805f9b34fb');

/// Reads the battery level of [device] (found by a scan).
Future<int> readBatteryLevel(BluetoothDevice device) async {
  var connection = await bluetoothManagerFlutterBlue.newConnection(device.id);
  try {
    await connection.connect();
    var services = await connection.getServices(); // discovers on first call
    var service = services.firstWhere((s) => s.uuid == batteryServiceUuid);
    var characteristic = service.characteristics.firstWhere(
      (c) => c.uuid == batteryLevelUuid,
    );
    var value = await connection.readCharacteristic(characteristic);
    return value.value.first;
  } finally {
    await connection.disconnect();
  }
}
```

## What works

* `bluetoothManagerFlutterBlue`: `scan()` (`withServices` applied natively,
  `scanMode` ignored), `stop()`, `getConnectedDevices()`, `newConnection()`,
  `isAndroid`, `isIOS`. `init()`, `getInfo()`, `close()`, `enable()`,
  `disable()` and `supportsEnable` throw `UnimplementedError`.
* A connection: `connect()`, `disconnect()`, `discoverServices()`,
  `getServices()`, `readCharacteristic()`, `writeCharacteristic()`,
  `registerCharacteristic()` + `onCharacteristicValueChanged()`,
  `onConnectionState` (connected or disconnected only).
* The adapter: `bluetoothAdminManagerFlutterBlue.getAdminInfo()` (supported,
  on), `enable()` (`FlutterBluePlus.turnOn()`, Android),
  `BluetoothFlutterBlue.bluetoothState`.

## Good to know

* **License**: flutter_blue_plus 2.x is free for personal use, nonprofits
  and education only; a for-profit organization needs its commercial
  license, and its build sends a license ping. `connect()` here declares
  `License.nonprofit`.
* `newConnection(id)` only knows the devices seen by a scan or
  `getConnectedDevices()` in this process (`StateError` otherwise).
* A new `scan()` replaces the running one: the previous stream ends. A scan
  ends with `stop()`; a start error (permission, adapter off) is an error of
  its stream.
* 16 and 32 bit uuids are given in full (`0000180f-0000-1000-8000-00805f9b34fb`
  for the battery service): compare with full `Uuid128`s.
* Reads time out after 10 s. `connection.close()` does nothing:
  `disconnect()` releases the link.
* Tests: unit test the app against `BluetoothManagerMock`
  (`package:tekartik_bluetooth/bluetooth_mock.dart`); this package's tests
  fake the flutter_blue_plus platform (`test/src/fake_flutter_blue_plus.dart`).

The package skill (`skills/tekartik-bluetooth-flutter-blue-setup`) has more
examples.
