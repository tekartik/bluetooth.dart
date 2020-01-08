import 'package:flutter/material.dart';
import 'package:tekartik_bluetooth_server_app/main.dart';
import 'package:tekartik_bluetooth_server_app/src/app.dart';
import 'package:tekartik_bluetooth_server_app/src/test/server_main.dart'
    as server;
import 'package:tekartik_test_menu_flutter/test.dart';

void main() {
  mainMenu(() {
    // dumpSetPrint(write);
    menu('run', () {
      item('go home', () {
        Navigator.of(buildContext).push<dynamic>(homePageRoute);
      });
      item('go home (restart app)', () async {
        await clearApp();
        await Navigator.of(buildContext).push<dynamic>(homePageRoute);
      });
      item('app', () {
        run();
      });
      server.main();
    });
  });
}
