import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:tekartik_test_menu_browser/test_menu_browser.dart';

Future main() async {
  await initTestMenuBrowser();

  item('isBluetoothApiSupported', () async {
    write(
        'isBluetoothApiSupported: ${FlutterWebBluetooth.instance.isBluetoothApiSupported}');
  });
  item('isAvailable', () async {
    write('waiting for available...');
    write('Available: ${await FlutterWebBluetooth.instance.isAvailable.first}');
  });
  item('requestDevice', () async {
    final device = await FlutterWebBluetooth.instance.requestDevice(
        RequestOptionsBuilder.acceptAllDevices(
            optionalServices: BluetoothDefaultServiceUUIDS.VALUES
                .map((e) => e.uuid)
                .toList()));
    write('Device got! ${device.name}, ${device.id}');
  });
}
