---
name: tekartik-bluetooth-server-host
description: >-
  Use when exposing a device's Bluetooth radio over a web socket JSON-RPC
  server with tekartik_bluetooth_server: BluetoothServer.serve (address, port,
  notifyCallback, webSocketChannelServerFactory), server.url/port/close,
  BluetoothServerNotifyCallback, the serverBluetoothManager and
  serverBluetoothAdminManager globals that must be assigned first,
  BluetoothContext, bluetoothServerDefaultPort, getBluetoothServerUrl, the
  bluetooth_server.dart import, and testing over
  webSocketChannelFactoryMemory.
---

# tekartik_bluetooth_server: the server side

`BluetoothServer` publishes a `BluetoothManager` over a web socket JSON-RPC
endpoint so another process (typically a desktop Dart program: see the
[tekartik-bluetooth-server-client](../tekartik-bluetooth-server-client/SKILL.md)
skill) can drive this device's Bluetooth radio. It is normally hosted by a small
Flutter app on the phone, but it works in any Dart VM program that has a real
manager.

## Guidelines

* Dependency (git, not on pub.dev):
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
  Add `tekartik_web_socket` (`https://github.com/tekartik/web_socket.dart`,
  `path: web_socket`) when you inject a factory, for instance the in-memory one
  in tests.
* Import `package:tekartik_bluetooth_server/bluetooth_server.dart`: it gives
  `BluetoothServer`, `BluetoothServerNotifyCallback`,
  `bluetoothServerDefaultPort` (8502), `getBluetoothServerUrl({port})` and the
  two globals `serverBluetoothManager` / `serverBluetoothAdminManager`.
  `package:tekartik_bluetooth_server/bluetooth_context.dart` has the tiny
  `BluetoothContext` interface (`isAndroid`, `isIOS`).
* **Assign `serverBluetoothManager` before serving.** It is a `late
  BluetoothManager` global and the JSON-RPC handler forwards every remote call
  to it by casting it to `BluetoothServiceInvokable`, so the instance must
  implement `invokeMethod` and it must be a manager that really answers:
  `bluetoothManagerFlutter` from `tekartik_bluetooth_flutter` (the Android
  plugin) is the intended one. `bluetoothManagerBluez` and
  `bluetoothManagerFlutterBlue` mix the interface in but their `invokeMethod`
  throws `UnimplementedError`, so they cannot back a server.
  `serverBluetoothAdminManager` is the matching slot for the admin manager;
  assign it too if your app reads it.
* Start with
  `var server = await BluetoothServer.serve(port: bluetoothServerDefaultPort)`.
  All parameters are optional: `address` and `port` (`null`/`0` picks a free
  port, read it back with `server.port`), `notifyCallback` for tracing, and
  `webSocketChannelServerFactory` (defaults to `webSocketChannelServerFactoryIo`,
  i.e. `dart:io` sockets). `server.url` is the `ws://...` url to hand to the
  client, `await server.close()` stops it.
* One `BluetoothServerChannel` is created per connected client and they all
  share the single `serverBluetoothManager`: concurrent clients fight over the
  one radio (one scan at a time). Keep it to one client, or serialise on your
  side.
* `BluetoothServerNotifyCallback` is
  `void Function(bool response, String method, dynamic params)`: it is called
  once with `response: false` and the incoming params, then with
  `response: true` and the result, for both `bluetoothGetServerInfo` and the
  generic `bluetooth` method. Use it to log the traffic in the host app's UI;
  do not throw from it.
* Restarting: keep a nullable `BluetoothServer?`, `close()` the previous one
  before serving again, otherwise the port stays bound.
* Security: there is no authentication and no TLS. Bind it on a development
  device only and reach it through `adb forward`, never expose the port on a
  network.
* `BluetoothContext` (`isAndroid`, `isIOS`) is the interface the client and the
  server share to describe the hosting device; the server reports those flags in
  the `bluetoothGetServerInfo` handshake.
* Testing: serve over the in-memory transport to exercise the protocol without
  a socket or a radio, with `webSocketChannelFactoryMemory` from
  `package:tekartik_web_socket/web_socket.dart`
  (`factory.server` / `factory.client`). See
  `test/bluetooth_server_test.dart` in this package.

## Examples

### Install the manager and serve

The host app calls this with `bluetoothManagerFlutter` and
`bluetoothAdminManagerFlutter` from
`package:tekartik_bluetooth_flutter/bluetooth_manager.dart` (a dependency of
the host app, not of this package).

```dart
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_server/bluetooth_server.dart';

BluetoothServer? _server;

/// Call once, after the bluetooth permissions have been granted.
Future<BluetoothServer> startBluetoothServer(
  BluetoothManager manager,
  BluetoothAdminManager adminManager, {
  int port = bluetoothServerDefaultPort,
}) async {
  // The globals must be set before any client connects.
  serverBluetoothManager = manager;
  serverBluetoothAdminManager = adminManager;

  await stopBluetoothServer();
  var server = _server = await BluetoothServer.serve(port: port);
  // ignore: avoid_print
  print('bluetooth server on ${server.url} (adb forward tcp:$port tcp:$port)');
  return server;
}

Future<void> stopBluetoothServer() async {
  var server = _server;
  _server = null;
  await server?.close();
}
```

### Trace every forwarded call

```dart
import 'package:tekartik_bluetooth_server/bluetooth_server.dart';

Future<BluetoothServer> serveWithLog(void Function(String line) write) {
  return BluetoothServer.serve(
    port: bluetoothServerDefaultPort,
    notifyCallback: (response, method, params) {
      write('${response ? '<-' : '->'} $method $params');
    },
  );
}
```

### Serve on a free port and print the url

```dart
import 'dart:io';

import 'package:tekartik_bluetooth_server/bluetooth_server.dart';

Future<void> main(List<String> args) async {
  var port = args.isEmpty ? 0 : int.parse(args.first);
  var server = await BluetoothServer.serve(port: port);
  stdout.writeln('listening on ${server.url} port ${server.port}');
  await ProcessSignal.sigint.watch().first;
  await server.close();
}
```

### Protocol test over the memory transport

```dart
import 'package:tekartik_bluetooth_server/bluetooth.dart';
import 'package:tekartik_bluetooth_server/bluetooth_server.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_web_socket/web_socket.dart';
import 'package:test/test.dart';

void main() {
  test('serve and connect in memory', () async {
    var factory = webSocketChannelFactoryMemory;
    var server = await BluetoothServer.serve(
      webSocketChannelServerFactory: factory.server,
    );
    var context = await BluetoothServerContext.connect(
      server.url,
      webSocketChannelClientFactory: factory.client,
    );
    expect(context, isNotNull);
    await context!.close();
    await server.close();
  });
}
```

## Common mistakes

* Serving before assigning `serverBluetoothManager`: the first forwarded call
  throws a `LateInitializationError`.
* Assigning a manager whose `invokeMethod` is not implemented
  (`bluetoothManagerBluez`, `bluetoothManagerFlutterBlue`): every call fails
  with `UnimplementedError`.
* Serving again without closing the previous `BluetoothServer`.
* Letting several clients connect and expecting independent scans: there is a
  single shared radio.
* Exposing the port beyond `adb forward`: the endpoint is unauthenticated.
