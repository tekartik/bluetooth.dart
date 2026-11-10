# tekartik_bluetooth_server_flutter

A `BluetoothManager` for a Flutter program whose Bluetooth radio is on
another device: a phone running the bluetooth server
(`bluetooth_server_app` of this repository, built on
`tekartik_bluetooth_server`). Every call goes over a web socket (JSON-RPC)
and runs on the phone. Use it to drive a phone's Bluetooth from a desktop
Flutter tool or a `flutter test`.

## Getting started

Flutter only (it pulls the Flutter Bluetooth plugins), not on pub.dev:

```yaml
dependencies:
  tekartik_bluetooth:
    git:
      url: https://github.com/tekartik/bluetooth.dart
      path: bluetooth
  tekartik_bluetooth_server_flutter:
    git:
      url: https://github.com/tekartik/bluetooth.dart
      path: bluetooth_server_flutter
```

On the phone, run `bluetooth_server_app` and press START (port 8502). With
the phone on USB: `adb forward tcp:8502 tcp:8502`. Then:

```dart
import 'package:tekartik_bluetooth/bluetooth_manager.dart';
// The class is only in lib/src (no public library).
// ignore: implementation_imports
import 'package:tekartik_bluetooth_server_flutter/src/service_flutter.dart';

Future<void> printPhoneInfo() async {
  BluetoothManager? manager = await BluetoothServerFlutterService.create(
    'ws://localhost:8502',
  );
  if (manager == null) {
    return; // no server: the cause and the adb hint were printed
  }
  try {
    var info = await manager.getInfo();
    print('enabled: ${info.isBluetoothEnabled}');
  } finally {
    await manager.close();
  }
}
```

## What works, what does not

The protocol is request/response only: the server never sends anything on
its own.

* Works: `getInfo()`, `getConnectedDevices()`, `enable()`, `disable()`,
  `init()`, `stop()`, `invokeMethod()`, and `isAndroid` / `isIOS` (the
  phone's platform, null with a server app built before 2026-11).
* Does not work:
  * `newConnection()` throws `UnimplementedError`: the base mixin's
    `newConnection` hides the Flutter one, and using the Flutter one would
    only time out in `connect()` (30 s), as the phone cannot send the
    connection state back. Both wait for server to client messages in the
    server protocol.
  * `scan()` starts the scan on the phone but its stream stays silent
    (cancel it to stop the remote scan).
* A call failing on the phone throws a `BluetoothException` (from
  `package:tekartik_bluetooth/src/exception.dart`) with the remote message.

## Pitfalls

* `create` returns null instead of throwing when no server answers.
* Always `close()`: the web socket keeps a program or a test alive.
* From a plain Dart program (no Flutter), use `BluetoothServerService` or
  `initBluetoothClientService()` of `tekartik_bluetooth_server` instead: the
  same calls.
* Tests: serve in process over `webSocketChannelFactoryMemory`
  (`package:tekartik_web_socket/web_socket.dart`), under `flutter test`; see
  the skill below.

## More

* Agent skill: `skills/tekartik-bluetooth-server-flutter-client/SKILL.md`.
* The server side: `bluetooth_server` and `bluetooth_server_app` in this
  repository.
