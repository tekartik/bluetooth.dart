# tekartik_bluetooth_web

The browser implementation of the [tekartik_bluetooth](../bluetooth/README.md)
API, on Web Bluetooth (through a fork of `flutter_web_bluetooth`). Partial: the
user picks a device in the browser's chooser, the app connects and
disconnects; the GATT operations (services, read, write, notify) are not
implemented yet.

## Getting started

The package is not on pub.dev, add it (and the common API) as git
dependencies:

```yaml
dependencies:
  tekartik_bluetooth:
    git:
      url: https://github.com/tekartik/bluetooth.dart
      path: bluetooth
  tekartik_bluetooth_web:
    git:
      url: https://github.com/tekartik/bluetooth.dart
      path: bluetooth_web
```

Ask the user for a device (from a click handler), then connect:

```dart
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_web/bluetooth_web.dart';

final batteryServiceUuid = Uuid128('0000180f-0000-1000-8000-00805f9b34fb');

/// Call it from a click: the chooser needs a user gesture.
Future<BluetoothDeviceConnection?> pickAndConnect() async {
  var info = await bluetoothManagerWeb.getInfo();
  if (info.hasBluetoothBle != true) {
    return null; // no Web Bluetooth in this browser
  }
  BluetoothDevice device;
  try {
    device = await bluetoothManagerWeb.webRequestDevice(
      BluetoothRequestDeviceOptionsWeb(
        acceptAllDevices: true,
        // Every service the page uses must be declared here.
        optionalServices: [batteryServiceUuid.toString()],
      ),
    );
  } catch (_) {
    return null; // chooser cancelled
  }
  var connection = await bluetoothManagerWeb.newConnection(device.id);
  await connection.connect(); // throws when the connection fails
  return connection;
}
```

## Platforms

* Chrome, Edge and other Chromium browsers (desktop, Android), on https or
  `http://localhost`. Firefox and Safari have no Web Bluetooth.
* dart2js only: under dart2wasm (Flutter `--wasm`) the plugin fork uses its
  unsupported implementation and reports no Bluetooth.
* Debugging: `chrome://bluetooth-internals`, `chrome://flags`
  ([doc/bluetooth_web_info.md](doc/bluetooth_web_info.md)).

## Common pitfalls

* `webRequestDevice()` outside a user gesture throws a `SecurityError`.
* `scan()` does not scan the radio: it lists the devices this origin was
  already granted (`rssi` is 0, `withServices` and `scanMode` are ignored).
* `getServices()`, `readCharacteristic()`, `writeCharacteristic()` and the
  notifications throw `UnimplementedError`: use `flutter_web_bluetooth`
  directly for GATT traffic.

The demo page `web/main.dart` (a `tekartik_test_menu_browser` menu) runs with
`dart run build_runner serve web:8080`. Agent skill:
[skills/tekartik-bluetooth-web-setup](skills/tekartik-bluetooth-web-setup/SKILL.md).
