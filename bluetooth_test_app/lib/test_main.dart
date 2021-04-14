import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart' as fbl;
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_test_app/ble/app_ble.dart';
import 'package:tekartik_bluetooth_test_app/src/ble_setup.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_test_menu_flutter/demo/demo.dart';
import 'package:tekartik_test_menu_flutter/demo/demo_test_menu_flutter.dart'
    as demo;
import 'package:tekartik_test_menu_flutter/test.dart';

import 'main.dart' as app_main;

void main() {
  mainMenu(() {
    /*
  test('crash', () {
    fail('fail');
  });
  */
    initWithFlutterBlue();

    menu('Bluetooth init', () {
      item('enablePermissions', () async {
        var info = await initBluetoothManager.getInfo();
        write('success $info');
      });
      item('enablePermissions', () async {
        await initBluetoothManager.checkCoarseLocationPermission(
            androidRequestCode: 1234);
        write('success');
      });
      item('enable', () async {
        await initBluetoothManager.enable(androidRequestCode: 1235);
        write('success');
      });
    });
    item('Start app', () {
      app_main.main();
    });

    menu('BluetoothFlutter', () {
      item('Enable bluetooth', () async {
        await BluetoothFlutter.enableBluetooth(requestCode: 1234);
        write('success');
      });
    });

    menu('Flutter blue', () {
      item('Enable bluetooth', () async {
        var state = await fbl.FlutterBlue.instance.state.first;
        write('state: $state');
      });

      item('Current state', () async {
        var state = await fbl.FlutterBlue.instance.state.first;
        write('state: $state');
      });
    });

    menu('Scan', () {
      StreamSubscription? subscription;

      item('startScan', () {
        subscription?.cancel();
        subscription = deviceBluetoothManager.scan().listen((result) {
          write('${result.device.id} $result');
        });
      });
      item('stopScan', () {
        subscription?.cancel();
      });
    });

    demo.main();

    menu('custom', () {
      item('do it', () {
        write('ok');
        write('or no');
      });
      test('success', () {
        expect(true, isTrue);
        write('success');
      });
    });
    menu('group', () {
      test('failure', () {
        fail('failure');
      });

      test('expect_failure', () {
        write('failure');
        expect(true, isFalse);
      });
      test('success', () {
        expect(true, isTrue);
        write('success');
      });

      test('throw', () {
        throw 'error thrown';
      });
    });
    item('root_item', () {
      write('from root item');
    });
    item('sleep 1000', () async {
      write('before sleep');
      await sleep(2000);
      write('after sleep 2000');
    });
    item('navigate', () {
      Navigator.push(buildContext!,
          MaterialPageRoute(builder: (BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('test')),
            body: demoSimpleList(context));
      }));
    });
  }, showConsole: true);
}
