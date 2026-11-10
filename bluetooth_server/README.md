# tekartik_bluetooth_server

Use the Bluetooth radio of a phone from a desktop Dart program or a test: the
phone runs a `BluetoothServer` (web socket JSON-RPC, in the
`bluetooth_server_app` Flutter app of this repo), the program connects to it
and gets a `BluetoothManager` whose calls are forwarded to the phone.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_bluetooth_server:
    git:
      url: https://github.com/tekartik/bluetooth.dart
      path: bluetooth_server
```

Client side, with the server app running on an Android phone (after
`adb forward tcp:8502 tcp:8502`):

```dart
import 'package:tekartik_bluetooth_server/bluetooth.dart';

Future<void> main() async {
  // null (with a hint printed) when no server answers on ws://localhost:8502
  var manager = await initBluetoothClientService();
  if (manager == null) {
    return;
  }
  try {
    var info = await manager.getInfo();
    print('ble: ${info.hasBluetoothBle}, enabled: ${info.isBluetoothEnabled}');
  } finally {
    await manager.close();
  }
}
```

Server and client in one process, no radio needed
([example/main.dart](example/main.dart), `dart run example/main.dart`):

```dart
import 'package:tekartik_bluetooth_server/bluetooth.dart';
import 'package:tekartik_bluetooth_server/bluetooth_server.dart';

Future<void> main() async {
  // On the phone, serverBluetoothManager must be set first (the Flutter
  // plugin manager): every remote call is forwarded to it.
  var server = await BluetoothServer.serve(port: 0); // 0: a free port
  var context = await BluetoothServerContext.connect(server.url);
  print('connected to ${server.url}, android: ${context?.isAndroid}');
  await context?.close();
  await server.close();
}
```

## Platforms

Dart VM (client and server, `dart:io` web sockets); the server is meant to run
in a Flutter app on the phone, with `serverBluetoothManager` set to
`bluetoothManagerFlutter` (`tekartik_bluetooth_flutter`).

## What works through the server

Request/response calls of the remote manager: `getInfo()`,
`getConnectedDevices()`, `init()`, `stop()`, `enable()`, `disable()`.

Not supported: the protocol has no server to client message, so `scan()`
starts a scan on the phone but its stream never emits, and `newConnection()`
throws `UnimplementedError`.

## Common pitfalls

* The url and port are compile time defines
  (`-DTEKARTIK_BLUETOOTH_SERVER_URL=...`, `-DTEKARTIK_BLUETOOTH_SERVER_PORT=...`),
  not environment variables. The default is `ws://localhost:8502`.
* Android: forward the port first, `adb forward tcp:8502 tcp:8502`.
* No authentication and no TLS: keep the server behind `adb forward`.
* Close the manager or the context, the web socket keeps the program alive.

## Testing

```bash
dart test
```

`test/bluetooth_client_test.dart` is skipped when no server app is reachable.
