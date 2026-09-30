---
name: tekartik-bluetooth-server-flutter-client
description: >-
  Use when a Flutter program (an app, a flutter test) needs a BluetoothManager
  whose radio is on another device running the tekartik bluetooth server, with
  tekartik_bluetooth_server_flutter: BluetoothServerFlutterService.create(url,
  webSocketChannelClientFactory), its BluetoothManager API forwarded over web
  socket JSON-RPC (getInfo, getConnectedDevices, newConnection, invokeMethod,
  isAndroid, isIOS, close), the src/service_flutter.dart import, how it relates
  to tekartik_bluetooth_server (BluetoothServer.serve, BluetoothServerContext,
  BluetoothServerService) and tekartik_bluetooth_flutter, adb forward, and
  in-process tests over webSocketChannelFactoryMemory.
---

# tekartik_bluetooth_server_flutter: remote BluetoothManager for Flutter

One class, `BluetoothServerFlutterService`: a `BluetoothManager` that lives in
a Flutter program but forwards every call over a web socket (JSON-RPC) to the
`tekartik_bluetooth_server` running on a phone, which executes it on its own
radio. It is the Flutter side twin of `BluetoothServerService` (the pure Dart
client of `tekartik_bluetooth_server`): same connection, same forwarding, plus
the `newConnection` implementation of `tekartik_bluetooth_flutter`, which
needs Flutter. Despite the package description, nothing here serves: the
server is `BluetoothServer.serve` from `tekartik_bluetooth_server`, hosted by
the `bluetooth_server_app` of the repo.

```dart
import 'package:tekartik_bluetooth/bluetooth_manager.dart';
// The only library of the package is under src/.
// ignore: implementation_imports
import 'package:tekartik_bluetooth_server_flutter/src/service_flutter.dart';

/// Null when no server answers on [url] (the cause is printed).
Future<BluetoothManager?> connectRemoteBluetooth(String url) =>
    BluetoothServerFlutterService.create(url);
```

## Guidelines

* Dependency (git, not on pub.dev). Add `tekartik_bluetooth` for the
  `BluetoothManager` API and `tekartik_bluetooth_server` for the server side
  and the url helpers:

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
    tekartik_bluetooth_server_flutter:
      git:
        url: https://github.com/tekartik/bluetooth.dart
        path: bluetooth_server_flutter
  ```

  It pulls `tekartik_bluetooth_flutter` (the Tekartik Android plugin) and
  `tekartik_bluetooth_flutter_blue` (flutter_blue_plus) as dependencies, so it
  only builds in a Flutter project.
* Import `package:tekartik_bluetooth_server_flutter/src/service_flutter.dart`
  with `// ignore: implementation_imports`: there is no public library, the
  class is only exported from `lib/src/`.
* The repo packages and where this one sits:
  * `tekartik_bluetooth`: the interfaces (`BluetoothManager`,
    `BluetoothDeviceConnection`, `ScanResult`, `BluetoothException`) and
    `BluetoothManagerMock`.
  * `tekartik_bluetooth_flutter` (Android plugin, `bluetoothManagerFlutter`)
    and `tekartik_bluetooth_flutter_blue` (flutter_blue_plus): real radios on
    the phone.
  * `tekartik_bluetooth_server`: `BluetoothServer.serve` publishes the phone's
    `serverBluetoothManager` over JSON-RPC; `BluetoothServerContext` and
    `BluetoothServerService` (`initBluetoothClientService()`) are the client
    for a Dart VM program.
  * this package: the same client for a Flutter program. Use it when the
    program that drives the phone is itself a Flutter app (desktop tooling, a
    test app); use `tekartik_bluetooth_server` alone from a plain Dart program.
* `BluetoothServerFlutterService.create(url, {webSocketChannelClientFactory})`
  returns `null` on any failure (no server, wrong server, refused socket) and
  prints the cause with the `adb forward` hint: always null check, never
  expect an exception. The default factory is the `dart:io` web socket client;
  the phone's port is reached through `adb forward tcp:<port> tcp:<port>` on
  Android, or its LAN address elsewhere. Build the url with
  `getBluetoothServerUrl(port:)` from
  `package:tekartik_bluetooth_server/bluetooth_client.dart`
  (`ws://localhost:8502` by default).
* Every `BluetoothManager` call becomes `invokeMethod(method, arguments)`,
  sent as one JSON-RPC request and run on the phone's `serverBluetoothManager`.
  An error there comes back as a `BluetoothException` (`message`, `result`)
  carrying the remote message: a phone that serves without assigning
  `serverBluetoothManager` answers every call with the remote
  `LateInitializationError` text. The type is only in
  `package:tekartik_bluetooth/src/exception.dart` (no public export): import
  it with `// ignore: implementation_imports` to catch it, or catch
  `Exception`.
* `isAndroid` and `isIOS` are `null` with the current server: the handshake
  only carries the server name and version. Do not branch on them, and note
  that `supportsEnable` (`isAndroid`) is `null` too.
* The transport is request/response only: nothing on the phone pushes to the
  client. Calls that return a value (`getInfo()`, `getConnectedDevices()`,
  `init()`, `stop()`, `enable()`, `disable()`, `newConnection()`, raw
  `invokeMethod`) work; what the phone plugin delivers by callback does not
  arrive: `scan()` starts the scan on the phone but its stream stays silent
  (cancel the subscription to stop the remote scan), `connection.connect()`
  waits for a connected event and times out, `onConnectionState` never emits.
* `await manager.close()` closes the web socket and is the only cleanup; a
  test or a tool that skips it stays alive. `close()` never fails when the
  socket is already gone.
* Testing: serve in the same process over `webSocketChannelFactoryMemory`
  (`package:tekartik_web_socket/web_socket.dart`, `factory.server` for
  `BluetoothServer.serve`, `factory.client` for `create`) under
  `flutter test`, never `dart test` (the class depends on Flutter). Without a
  real manager assigned to `serverBluetoothManager` on the server side this
  only covers the handshake and the error path; `BluetoothManagerMock` cannot
  back a server (its `invokeMethod` throws `UnsupportedError`).

## Examples

### Drive a phone through adb forward from a Flutter tool

```dart
// BluetoothException has no public export either.
// ignore: implementation_imports
import 'package:tekartik_bluetooth/src/exception.dart';
import 'package:tekartik_bluetooth_server/bluetooth_client.dart';
// ignore: implementation_imports
import 'package:tekartik_bluetooth_server_flutter/src/service_flutter.dart';

/// adb forward tcp:8502 tcp:8502 first, the phone runs bluetooth_server_app.
Future<List<String>> listPhoneConnectedDevices({int? port}) async {
  var url = getBluetoothServerUrl(port: port ?? bluetoothServerDefaultPort);
  var manager = await BluetoothServerFlutterService.create(url);
  if (manager == null) {
    return const []; // no server, the hint was printed
  }
  try {
    var info = await manager.getInfo();
    if (info.isBluetoothEnabled != true) {
      return const [];
    }
    var devices = await manager.getConnectedDevices();
    return [for (var device in devices) '${device.id} ${device.name}'];
  } on BluetoothException catch (e) {
    // Raised on the phone (no serverBluetoothManager, radio off...).
    return ['remote error: ${e.message}'];
  } finally {
    await manager.close();
  }
}
```

### Keep one remote manager for the whole app

```dart
import 'package:tekartik_bluetooth/bluetooth_manager.dart';
// ignore: implementation_imports
import 'package:tekartik_bluetooth_server_flutter/src/service_flutter.dart';

BluetoothManager? _remote;

/// Connected once, reused, null while the phone is unreachable.
Future<BluetoothManager?> remoteBluetoothManager(String url) async =>
    _remote ??= await BluetoothServerFlutterService.create(url);

Future<void> disposeRemoteBluetoothManager() async {
  var remote = _remote;
  _remote = null;
  await remote?.close();
}
```

### In-process handshake test over the memory transport

```dart
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:tekartik_bluetooth/src/exception.dart';
import 'package:tekartik_bluetooth_server/bluetooth_server.dart';
// ignore: implementation_imports
import 'package:tekartik_bluetooth_server_flutter/src/service_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_web_socket/web_socket.dart';

void main() {
  test('connect, forward, close', () async {
    var factory = webSocketChannelFactoryMemory;
    var server = await BluetoothServer.serve(
      webSocketChannelServerFactory: factory.server,
    );
    var manager = await BluetoothServerFlutterService.create(
      server.url,
      webSocketChannelClientFactory: factory.client,
    );
    expect(manager, isNotNull);
    expect(manager!.isAndroid, isNull); // not in the handshake
    // serverBluetoothManager is not assigned: the remote error comes back.
    await expectLater(manager.getInfo(), throwsA(isA<BluetoothException>()));
    await manager.close();
    await server.close();
  });

  test('no server gives null', () async {
    expect(await BluetoothServerFlutterService.create('ws://localhost:1'), isNull);
  });
}
```

## Common mistakes

* `Import of a library in the 'lib/src' directory` lint: expected, there is
  no other library; keep the `// ignore: implementation_imports`.
* Waiting for scan results or `connection.connect()` through the server: the
  protocol has no notifications, only request/response calls complete.
* Branching on `manager.isAndroid`: it is `null`, the server does not send it.
* Catching a `StateError` or `SocketException` from `create`: it returns
  `null` instead and prints.
* Forgetting `close()`: the web socket keeps the test or tool alive.

## More

* Package README for the dependency snippet, CHANGELOG for the versions.
