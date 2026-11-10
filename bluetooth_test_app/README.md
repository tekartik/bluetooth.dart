# bluetooth_test_app

A Flutter app to try the [tekartik_bluetooth](../bluetooth/README.md)
implementations on a real device: scan, pick a device, connect, list its
services, read, write and subscribe to its characteristics, and (Android) act
as a simple peripheral.

| Platform | Manager used |
|---|---|
| Android | `bluetoothManagerFlutterBlue` (scan, GATT), `bluetoothAdminManagerFlutter` (permissions, enable), the `tekartik_bluetooth_flutter` peripheral |
| iOS | `bluetoothManagerFlutterBlue`, `bluetoothAdminManagerFlutterBlue` |
| Web | `bluetoothManagerWeb` (Chrome, a device chosen with Web.requestDevice) |
| Linux | `bluetoothManagerBluez` (no `linux/` folder committed: `flutter create --platforms linux .` first) |

## Run it

`flutter run -d <device>` from this folder. On Android, grant the Bluetooth
permissions when asked. The start screen has the scan, the simple peripheral
(Android only) and a test menu (`lib/test_main.dart`).

`dart run tool/test_app_build_menu.dart` opens a build menu.
