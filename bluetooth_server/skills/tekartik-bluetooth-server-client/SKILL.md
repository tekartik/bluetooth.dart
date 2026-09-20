---
name: tekartik-bluetooth-server-client
description: >-
  Use when a Dart VM program or test drives the Bluetooth radio of a remote
  device (a phone running the bluetooth server app) over web socket JSON-RPC
  with tekartik_bluetooth_server: initBluetoothClientService,
  BluetoothServerContext (connect, connectClient, invoke, sendRequest, close),
  bluetoothServerContext, getBluetoothServerUrl,
  bluetoothServerDefaultPort, parseBluetoothServerUrlPort, the
  TEKARTIK_BLUETOOTH_SERVER_URL / TEKARTIK_BLUETOOTH_SERVER_PORT defines, the
  bluetooth.dart and bluetooth_client.dart imports, adb forward, and getting a
  remote BluetoothManager for scan/newConnection.
---

# tekartik_bluetooth_server: the client side

`tekartik_bluetooth_server` lets a program that has no Bluetooth radio (a
desktop Dart VM program, a `dart test` run, a CI job) use the radio of a phone.
The phone runs the server app; this side connects over a web socket with
JSON-RPC and gets a plain `BluetoothManager` whose method calls are forwarded.
The server side is covered by the
[tekartik-bluetooth-server-host](../tekartik-bluetooth-server-host/SKILL.md)
skill.

## Guidelines

* Dependency (git, not on pub.dev). Add it under `dev_dependencies` when it is
  only used by tests:
  ```yaml
  dependencies:
    tekartik_bluetooth:
      git:
        url: https://github.com/tekartik/bluetooth.dart
        path: bluetooth
    tekartik_bluetooth_server:
      git:
        url: https://github.com/tekartik/bluetooth.dart
        path: bluetooth_server
  ```
  It brings `tekartik_web_socket_io` and `json_rpc_2`. Add
  `tekartik_web_socket` (`https://github.com/tekartik/web_socket.dart`,
  `path: web_socket`) explicitly if you pass your own
  `WebSocketChannelClientFactory`.
* VM only: the transport is `webSocketChannelClientFactoryIo` from
  `tekartik_web_socket_io`, so this does not run in a browser unless you inject
  a browser factory.
* Imports: `package:tekartik_bluetooth_server/bluetooth.dart` for
  `initBluetoothClientService()`, `BluetoothServerContext`,
  `bluetoothServerContext`, `bluetoothServerDefaultUrl`,
  `parseBluetoothServerUrlPort()` and the two env keys;
  `package:tekartik_bluetooth_server/bluetooth_client.dart` for
  `bluetoothServerDefaultPort` (8502) and `getBluetoothServerUrl({port})`;
  `package:tekartik_bluetooth/bluetooth_device.dart` (and `ble.dart`,
  `uuid.dart`) for the `BluetoothManager` API itself.
* One call does everything: `var manager = await initBluetoothClientService();`
  returns a `BluetoothManager?`. It is `null` when nothing answers, and it
  prints the `adb forward` hint instead of throwing, so always null-check and
  `skip:` the tests when it is null.
* The url it dials is `ws://localhost:<bluetoothServerDefaultPort>`, overridden
  by the **compile-time** declarations `TEKARTIK_BLUETOOTH_SERVER_URL`
  (`bluetoothServerUrlEnvKey`) and `TEKARTIK_BLUETOOTH_SERVER_PORT`
  (`bluetoothServerPortEnvKey`). They are read with
  `const String.fromEnvironment`, so pass them with `-D`/`--define` on
  `dart run` or `dart test`, not through the shell environment:
  ```
  dart test -DTEKARTIK_BLUETOOTH_SERVER_PORT=8502 test/ble_test.dart
  ```
  To pick the url at runtime instead, call
  `BluetoothServerContext.connect(url)` yourself.
* Android plumbing: the phone's server port is not reachable from the host
  until you forward it, once per device:
  `adb forward tcp:8502 tcp:8502` (use the port the app prints). On iOS there
  is no equivalent, use the LAN address of the phone with an explicit url.
* The returned manager is a real `BluetoothManager`: `scan()`,
  `getConnectedDevices()`, `newConnection()`, `getInfo()`, `init()`, `stop()`
  and the whole `BluetoothDeviceConnection` API work exactly as on the phone,
  because every call is forwarded to the phone's manager. Errors raised there
  come back as `BluetoothException` (from
  `package:tekartik_bluetooth/bluetooth.dart`'s implementation) carrying the
  remote message. Latency is a web socket round trip: keep the scan filters
  tight.
* `await manager.close()` closes the web socket. Always do it in `tearDownAll`
  or a `finally`, otherwise the VM stays alive.
* `BluetoothServerContext` is the lower level: `await BluetoothServerContext.connect(url)`
  returns a context or `null`, `context.invoke<T>(method, param)` forwards one
  method to the phone's `BluetoothManager.invokeMethod`,
  `context.sendRequest<T>(method, param)` sends a raw JSON-RPC request,
  `context.isAndroid` / `context.isIOS` come from the server handshake, and
  `context.close()` disconnects. The process-wide `bluetoothServerContext`
  getter returns a lazily created, initially unconnected context: call
  `connectClient(url)` on it before use.
* Version handshake: connecting checks that the peer answers
  `bluetoothGetServerInfo` with the name `tekartik_bluetooth_server` and a
  version `>= 0.0.1`, and throws a `StateError` otherwise. Pointing the client
  at another web socket server fails there.
* Testing: this is the standard way to run BLE integration tests from a
  desktop. Write the test suite against `BluetoothManager` so the same code can
  run against `BluetoothManagerMock`
  (`package:tekartik_bluetooth/bluetooth_mock.dart`) with no device. To test
  the plumbing itself without any radio, serve in the same process over the
  memory transport (`webSocketChannelFactoryMemory` from
  `package:tekartik_web_socket/web_socket.dart`).

## Examples

### Integration test skipped when no phone is connected

```dart
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_server/bluetooth.dart';
import 'package:test/test.dart';

// dart test -DTEKARTIK_BLUETOOTH_SERVER_PORT=8502
// (adb forward tcp:8502 tcp:8502 first)
Future<void> main() async {
  var manager = await initBluetoothClientService();

  tearDownAll(() async {
    await manager?.close();
  });

  group('remote bluetooth', () {
    test('scan', () async {
      var devices = <BluetoothDeviceId, BluetoothDevice>{};
      var subscription = manager!.scan().listen((result) {
        devices[result.device.id] = result.device;
      });
      await Future<void>.delayed(const Duration(seconds: 5));
      await subscription.cancel();
      expect(devices, isNotEmpty);
    });
  }, skip: manager == null ? 'no bluetooth server' : null);
}
```

### Connect to an explicit url instead of the compile-time define

```dart
import 'dart:io';

import 'package:tekartik_bluetooth_server/bluetooth.dart';
import 'package:tekartik_bluetooth_server/bluetooth_client.dart';

Future<BluetoothServerContext> connectToPhone({
  String host = 'localhost',
  int? port,
}) async {
  var url = host == 'localhost'
      ? getBluetoothServerUrl(port: port) // ws://localhost:8502
      : 'ws://$host:${port ?? bluetoothServerDefaultPort}';
  var context = await BluetoothServerContext.connect(url);
  if (context == null) {
    stderr.writeln('no server on $url, run: adb forward tcp:'
        '${parseBluetoothServerUrlPort(url, defaultValue: bluetoothServerDefaultPort)}'
        ' tcp:${bluetoothServerDefaultPort}');
    exit(1);
  }
  // ignore: avoid_print
  print('connected, android: ${context.isAndroid} ios: ${context.isIOS}');
  return context;
}
```

### Command line tool that lists the phone's connected devices

```dart
import 'dart:io';

import 'package:tekartik_bluetooth_server/bluetooth.dart';

Future<void> main() async {
  var manager = await initBluetoothClientService();
  if (manager == null) {
    exit(1); // the helper already printed the adb forward hint
  }
  try {
    var info = await manager.getInfo();
    // ignore: avoid_print
    print('ble ${info.hasBluetoothBle} enabled ${info.isBluetoothEnabled}');
    for (var device in await manager.getConnectedDevices()) {
      // ignore: avoid_print
      print('${device.id} ${device.name}');
    }
  } finally {
    await manager.close();
  }
}
```

### Shared process-wide context

```dart
import 'package:tekartik_bluetooth_server/bluetooth.dart';

/// bluetoothServerContext is created unconnected: connect it once at startup.
Future<void> initRemoteBluetooth() async {
  var client = await bluetoothServerContext.connectClient(
    bluetoothServerDefaultUrl,
  );
  if (client == null) {
    throw StateError('bluetooth server not reachable');
  }
}

Future<void> disposeRemoteBluetooth() => bluetoothServerContext.close();
```

## Common mistakes

* Setting `TEKARTIK_BLUETOOTH_SERVER_PORT` as a shell variable: it is a
  `String.fromEnvironment` compile-time define, pass `-D`.
* Forgetting `adb forward tcp:<port> tcp:<port>`: `initBluetoothClientService()`
  quietly returns `null`.
* Treating a `null` result as an error to throw: the helper already printed a
  full diagnostic, `skip` the test or exit.
* Never calling `close()`: the web socket keeps the VM alive.
* Pointing the client at an unrelated web socket server: the
  `bluetoothGetServerInfo` handshake throws a `StateError`.
