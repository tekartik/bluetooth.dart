import 'package:flutter_blue/flutter_blue.dart' as fbl;
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_test_app/ble/app_ble.dart';
import 'package:tekartik_bluetooth_test_app/src/ble_setup.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_platform_io/context_io.dart';
import 'package:tekartik_test_menu_flutter/test_menu_flutter.dart';

import 'main.dart' as app_main;

void main() {
  BluetoothDevice? bleDevice;
  BluetoothDeviceConnection? bleConnection;

  mainMenu(() {
    enter(() async {
      if (platformContextIo.io?.isLinux ?? false) {
        write('Using bluez');
        initWithBluez();
      } else {
        initWithFlutterBlue();
      }
    });
    /*
  test('crash', () {
    fail('fail');
  });
  */
    item('Use flutter blue', () {
      initWithFlutterBlue();
    });
    item('Use bluez', () {
      initWithBluez();
    });

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

    item('newConnection', () async {
      if (bleDevice != null) {
        try {
          await bleConnection?.disconnect();
        } catch (_) {}
        bleConnection =
            await deviceBluetoothManager.newConnection(bleDevice!.id);
      }
    });
    item('discover services', () async {
      if (bleDevice != null) {
        await bleConnection!.discoverServices();
        var services = await bleConnection!.getServices();
        for (var service in services) {
          write('service: $service');
          for (var characteristic
              in service.characteristics ?? <BleBluetoothCharacteristic>[]) {
            write('  characteristic: $characteristic');
          }
        }
      }
    });
    menu('Scan', () {
      StreamSubscription? subscription;

      var deviceMap = <BluetoothDeviceId, ScanResult>{};
      item('startScan', () {
        deviceMap.clear();
        write('Start scanning');
        subscription?.cancel();
        subscription = deviceBluetoothManager.scan().listen((result) {
          write('${result.device.id} $result');
          deviceMap[result.device.id] = result;
        });
      });
      item('select device', () {
        showMenu(() {
          for (var result in deviceMap.values) {
            item('scan $result', () {
              bleDevice = result.device;
            });
          }
        });
      });
      item('stopScan', () {
        subscription?.cancel();
      });
    });
  }, showConsole: true);
}
