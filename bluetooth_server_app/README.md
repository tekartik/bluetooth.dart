# bluetooth_server_app

The phone side of [tekartik_bluetooth_server](../bluetooth_server/README.md):
an Android app running a `BluetoothServer` (web socket JSON-RPC, port 8502 by
default) that forwards the remote calls to the phone's Bluetooth plugin
([tekartik_bluetooth_flutter](../bluetooth_flutter/README.md), Android only).
A desktop Dart program or a test then uses the phone's Bluetooth radio.

## Run it

1. `flutter run` on an Android phone. The `android/` folder predates
   Flutter 3: regenerate it first (`flutter create --platforms android .`)
   if the build fails.
2. Press START (the port is kept, and the server starts again on the next
   launch). The log shows the url.
3. On the computer: `adb forward tcp:8502 tcp:8502`, then connect with
   `initBluetoothClientService()` of `tekartik_bluetooth_server`.

`lib/test_main.dart` is a test menu starting and stopping the server.

## What works

The request/response calls of the remote manager (`getInfo()`,
`getConnectedDevices()`, `init()`, `stop()`, `enable()`, `disable()`). The
protocol has no server to client message: a remote `scan()` starts the scan on
the phone but gives no result, and `newConnection()` is not supported.

No authentication and no TLS: keep it behind `adb forward`.

## Test

`flutter test`: a client reads the info of a faked Bluetooth plugin through
the app's server.
