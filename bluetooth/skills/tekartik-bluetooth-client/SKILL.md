---
name: tekartik-bluetooth-client
description: >-
  Use when writing Dart or Flutter code that scans for, connects to and talks
  to BLE devices through the tekartik_bluetooth abstraction (central role):
  BluetoothManager, scan/ScanResult/ScanMode, BluetoothDevice/BluetoothDeviceId,
  newConnection/BluetoothDeviceConnection/BluetoothDeviceConnectionState,
  getServices, readCharacteristic/writeCharacteristic, registerCharacteristic/
  onCharacteristicValueChanged, BleBluetoothService/BleBluetoothCharacteristic/
  BleBluetoothCharacteristicValue, Uuid128/Uuid16/Uuid32, BluetoothInfo,
  BluetoothAdminManager/BluetoothPermissionsOptions, BluetoothStateService,
  the bluetooth_device.dart / bluetooth.dart / ble.dart / uuid.dart imports,
  and choosing a platform manager (bluez, flutter, flutter_blue, web, mock).
---

# tekartik_bluetooth: central role (scan, connect, GATT)

`tekartik_bluetooth` is the platform independent API of the bluetooth.dart
repository. It only defines interfaces and value classes; a platform package
provides the `BluetoothManager` instance: `bluetoothManagerBluez` (Linux,
`tekartik_bluetooth_bluez`), `bluetoothManagerFlutter` (Android plugin,
`tekartik_bluetooth_flutter`), `bluetoothManagerFlutterBlue` (Android and iOS
through flutter_blue_plus, `tekartik_bluetooth_flutter_blue`),
`bluetoothManagerWeb` (Web Bluetooth, `tekartik_bluetooth_web`) or
`BluetoothManagerMock` (tests, this package). Write application code against
the interfaces and inject the manager.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_bluetooth:
      git:
        url: https://github.com/tekartik/bluetooth.dart
        path: bluetooth
  ```
* Imports: `package:tekartik_bluetooth/bluetooth_device.dart` is the widest
  client import (`BluetoothManager`, `BluetoothAdminManager`,
  `BluetoothPermissionsOptions`, `BluetoothDevice`, `BluetoothDeviceType`,
  `BluetoothDeviceId`, `ScanResult`, `ScanMode`, `BluetoothDeviceConnection`,
  `BluetoothDeviceConnectionState`, `BluetoothInfo`, `BluetoothAdminInfo`).
  `package:tekartik_bluetooth/bluetooth.dart` is the same minus
  `BluetoothDevice`/`BluetoothDeviceId`. `package:tekartik_bluetooth/ble.dart`
  holds the GATT model (`BleBluetoothService`, `BleBluetoothCharacteristic`,
  `BleBluetoothCharacteristicValue`, `BleBluetoothDescriptor`,
  `BleCharacteristicPropertyFlag`, the `blePropertyRead`... constants and the
  `ble*Timeout` durations). `package:tekartik_bluetooth/uuid.dart` gives
  `Uuid128`, `Uuid16`, `Uuid32`; `package:tekartik_bluetooth/bluetooth_state_service.dart`
  gives `BluetoothStateService` (`supportsEnable`, `enable`, `disable`), which
  every manager implements.
* Uuids: `Uuid128('0000180f-0000-1000-8000-00805f9b34fb')` parses a text uuid
  (non strict, so vendor uuids that are not RFC 4122 compliant are accepted);
  `Uuid128.bytes(bytes)` wraps 16 bytes; `uuid.bytes` reads them back. Build a
  Bluetooth SIG 16-bit id in 128-bit form with
  `Uuid128('00000000-0000-1000-8000-00805f9b34fb').withUuid16(Uuid16.fromValue(0x180f))`
  and read the short id with `uuid128.shortNumberUuid16.value`.
  `Uuid16.fromText('180f')`, `Uuid16.fromValue(0x180f)`,
  `Uuid16.fromBytes(bytes)`, `Uuid32('1234abcd')`, `uuid128.withUuid32(uuid32)`.
  Uuids compare by value with `==` and print lowercase.
* Manager lifecycle: `await manager.init()` at startup (on Android it cancels
  a scan left running by a hot restart), `await manager.stop()` when leaving
  the feature (cancels scan and connections), `await manager.getInfo()` for a
  `BluetoothInfo` (`hasBluetooth`, `hasBluetoothBle`, `isBluetoothEnabled`,
  `isScanning`, all `bool?`). `close()` is meant for the server side only.
* Adapter state: `manager.supportsEnable` (`bool?`, true on Android only),
  `manager.enable(androidRequestCode: ...)`, `manager.disable()` (no longer
  works on Android 13+). Where a `BluetoothAdminManager` exists
  (`bluetoothAdminManagerFlutter`, `bluetoothAdminManagerFlutterBlue`, the
  bluez and web managers implement it too) call
  `await adminManager.checkBluetoothPermissions()` on Android before scanning
  (`options: BluetoothPermissionsOptions(advertise: true)` when the app will
  advertise as a peripheral) and `getAdminInfo()` for `hasBluetooth`,
  `hasBluetoothBle`, `isBluetoothEnabled`.
* Scanning: `manager.scan({scanMode = ScanMode.lowLatency, withServices})`
  returns a `Stream<ScanResult>` (`result.device`, `result.rssi`). The scan
  starts on listen and stops when the subscription is cancelled: keep the
  `StreamSubscription` and cancel it. One scan at a time per manager (a new
  `scan()` replaces the previous stream). The same device is reported many
  times: dedupe on `device.id`. `scanMode` values: `lowPower`, `balanced`,
  `lowLatency`, `opportunistic` (Android only); `withServices` filters on
  advertised service uuids where supported.
* Devices: `BluetoothDevice` has `name` (`String?`), `address`, `id`
  (`BluetoothDeviceId`, `==` is case insensitive on `id.id`, `toString()` is
  the id) and `type` (`BluetoothDeviceType.le` by default). Keep the
  `BluetoothDeviceId` from the scan result to connect later.
  `BluetoothDeviceId('...')` rebuilds one from a stored string, but most
  implementations only accept ids seen in the current scan or returned by
  `getConnectedDevices()`.
* Connection: `var connection = await manager.newConnection(deviceId)` builds
  the object; `await connection.connect()` connects (returns or throws);
  `connection.onConnectionState` streams `BluetoothDeviceConnectionState`
  (`.connected`, `.disconnected`, `.connecting`, `.disconnecting`, `.unknown`;
  compare with `==`; `connecting`/`disconnecting` are not reported on Android
  and iOS); `await connection.disconnect()`, then `connection.close()` to
  release it.
* Services: `await connection.getServices()` returns
  `List<BleBluetoothService>` (most implementations discover on first call;
  `discoverServices()` forces it). A service has `uuid`, `characteristics`,
  `shortNumber`. A `BleBluetoothCharacteristic` has `service`, `uuid`,
  `properties` (int flags: `blePropertyRead`, `blePropertyWrite`,
  `blePropertyWriteNoResponse`, `blePropertyNotify`, `blePropertyIndicate`...),
  `propertyFlags` (`Set<BleCharacteristicPropertyFlag>`), `descriptors`,
  `shortNumber` and `ref` (`BleBluetoothCharacteristicRef`, a value object
  usable as map key). Use the characteristics returned by `getServices()`
  rather than hand built ones: implementations look their native object up by
  service and characteristic uuid, and a `BleBluetoothService(uuid:)` created
  without `characteristics:` throws when `.characteristics` is read.
* Read and write: `var bcv = await connection.readCharacteristic(bc)`;
  `bcv.value` is a `Uint8List`, plus `bcv.bc`, `bcv.service`, `bcv.uuid`.
  Write with `connection.writeCharacteristic(bc.withValue(bytes))` or
  `BleBluetoothCharacteristicValue(bc: bc, value: bytes)` (`service:` and
  `uuid:` instead of `bc:` also work). Byte helpers in
  `package:tekartik_bluetooth/utils/byte_utils.dart`: `uint16GetBytes`,
  `uint32GetBytes`, `bytesGetUint16`, `bytesGetUint32`, `toLowerHexString`.
  `propertiesValueToPropertyFlags` / `propertyFlagsToPropertyValue` in
  `utils/ble_utils.dart` convert between the int and the flag set.
* Notifications: `await connection.registerCharacteristic(bc, true)` enables
  notify/indicate on the device, then listen to
  `connection.onCharacteristicValueChanged(bc)`
  (`Stream<BleBluetoothCharacteristicValue>`); cancel the subscription and
  call `registerCharacteristic(bc, false)` when done.
* Errors and timeouts are implementation specific (`StateError` for unknown
  device or characteristic, platform errors otherwise). Defaults in
  `ble.dart`: `bleConnectedTimeout` 30 s, `bleDiscoverServicesTimeout` 30 s,
  `bleReadCharacteristicTimeout` 5 s, `bleDisconnectedTimeout` 5 s. Wrap
  `connect()` and reads in `try`/`catch` and disconnect in `finally`.
* Testing: unit test your logic against `BluetoothManagerMock` from
  `package:tekartik_bluetooth/bluetooth_mock.dart` (see the
  [tekartik-bluetooth-mock](../tekartik-bluetooth-mock/SKILL.md) skill);
  hardware tests live in the platform packages. `dart test` in this package runs the mock and uuid tests.

## Examples

### Scan, dedupe, stop after a delay

```dart
import 'dart:async';

import 'package:tekartik_bluetooth/bluetooth_device.dart';

Future<List<BluetoothDevice>> scanDevices(
  BluetoothManager manager, {
  Duration duration = const Duration(seconds: 5),
}) async {
  var devices = <BluetoothDeviceId, BluetoothDevice>{};
  var subscription = manager.scan(scanMode: ScanMode.lowLatency).listen((
    result,
  ) {
    devices.putIfAbsent(result.device.id, () => result.device);
    print('${result.device.id} ${result.device.name} rssi ${result.rssi}');
  });
  await Future<void>.delayed(duration);
  await subscription.cancel(); // stops the scan
  return devices.values.toList();
}
```

### Connect, read the battery level, disconnect

```dart
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';

final sigBaseUuid = Uuid128('00000000-0000-1000-8000-00805f9b34fb');
final batteryServiceUuid = sigBaseUuid.withUuid16(Uuid16.fromValue(0x180f));
final batteryLevelUuid = sigBaseUuid.withUuid16(Uuid16.fromValue(0x2a19));

Future<int?> readBatteryLevel(
  BluetoothManager manager,
  BluetoothDeviceId deviceId,
) async {
  var connection = await manager.newConnection(deviceId);
  try {
    await connection.connect();
    var services = await connection.getServices();
    var service = services.firstWhere((s) => s.uuid == batteryServiceUuid);
    var bc = service.characteristics.firstWhere(
      (c) => c.uuid == batteryLevelUuid,
    );
    if (!bc.propertyFlags.contains(BleCharacteristicPropertyFlag.read)) {
      return null;
    }
    var bcv = await connection.readCharacteristic(bc);
    return bcv.value.first;
  } finally {
    await connection.disconnect();
    connection.close();
  }
}
```

### Subscribe to notifications

```dart
import 'dart:async';

import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';

Future<StreamSubscription<BleBluetoothCharacteristicValue>> listenTo(
  BluetoothDeviceConnection connection,
  Uuid128 serviceUuid,
  Uuid128 characteristicUuid,
) async {
  var services = await connection.getServices();
  var bc = services
      .firstWhere((s) => s.uuid == serviceUuid)
      .characteristics
      .firstWhere((c) => c.uuid == characteristicUuid);
  await connection.registerCharacteristic(bc, true);
  return connection.onCharacteristicValueChanged(bc).listen((bcv) {
    print('${bcv.uuid}: ${bcv.value}');
  });
}
```

### Write a 16-bit command

```dart
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/utils/byte_utils.dart';

Future<void> sendCommand(
  BluetoothDeviceConnection connection,
  BleBluetoothCharacteristic commandCharacteristic,
  int value,
) async {
  if (!commandCharacteristic.propertyFlags.contains(
    BleCharacteristicPropertyFlag.write,
  )) {
    throw StateError('$commandCharacteristic is not writable');
  }
  await connection.writeCharacteristic(
    commandCharacteristic.withValue(uint16GetBytes(value)),
  );
}
```

### Adapter checks before scanning

```dart
import 'package:tekartik_bluetooth/bluetooth_device.dart';

Future<bool> ensureBluetoothReady(
  BluetoothManager manager,
  BluetoothAdminManager adminManager,
) async {
  var adminInfo = await adminManager.getAdminInfo();
  if (adminInfo.hasBluetoothBle != true) {
    return false;
  }
  if (manager.isAndroid == true) {
    if (!await adminManager.checkBluetoothPermissions()) {
      return false;
    }
  }
  if (adminInfo.isBluetoothEnabled != true) {
    if (manager.supportsEnable == true) {
      await manager.enable();
    } else {
      return false;
    }
  }
  await manager.init();
  return true;
}
```

## Common mistakes

* Forgetting to cancel the scan subscription: the radio keeps scanning and
  the next `scan()` on some platforms throws "another scan in progress".
* Connecting with a `BluetoothDeviceId` that was never seen by the current
  manager (`StateError`): scan first, or use `getConnectedDevices()`.
* Building `BleBluetoothCharacteristic`/`BleBluetoothService` by hand and
  passing them to `readCharacteristic`: use the objects from `getServices()`.
* Expecting `connecting`/`disconnecting` states on Android or iOS.
