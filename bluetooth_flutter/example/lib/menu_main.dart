import 'package:flutter/cupertino.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_flutter_example/main.dart' as app_main;
import 'package:tekartik_test_menu_flutter/test.dart';

import 'menu_ble.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bluetoothAdminManagerFlutter
      // ignore: deprecated_member_use
      .devSetOptions(BluetoothOptions(logLevel: bluetoothLogLevelVerbose));
  mainMenuFlutter(() {
    item('app', () {
      app_main.main();
    });
    menuBle(androidEnableRequestCode: 1);
  }, showConsole: true);
}
