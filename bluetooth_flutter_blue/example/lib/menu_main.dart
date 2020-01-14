import 'package:tekartik_bluetooth_flutter_example/main.dart' as app_main;
import 'package:tekartik_test_menu_flutter/test.dart';

import 'menu_ble.dart';

void main() {
  initTestMenuFlutter(showConsole: true);
  item('app', () {
    app_main.main();
  });
  menuBle(androidEnableRequestCode: 1);
}
