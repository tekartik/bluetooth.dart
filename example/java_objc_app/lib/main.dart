import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_test_menu_flutter/test_menu_flutter.dart';

void main() {
  mainMenuFlutter(() {
    //devPrint('MAIN_');
    item('getInfo', () async {
      write(await bluetoothAdminManagerFlutter.getAdminInfo());
    });
  }, showConsole: true);
}
