import 'package:tekartik_bluetooth_flutter_example/main.dart' as app_main;
import 'package:tekartik_test_menu_flutter/test_menu_flutter.dart';

import 'menu_flutter_blue.dart';

void main() {
  initTestMenuFlutter(showConsole: true);
  item('app', () {
    app_main.main();
  });
  menuFlutterBlue();
}
