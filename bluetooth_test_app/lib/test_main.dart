import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbl;
import 'package:tekartik_app_platform/app_platform.dart';
import 'package:tekartik_bluetooth_test_app/ble/app_ble.dart';
import 'package:tekartik_bluetooth_test_app/import/common_import.dart';
import 'package:tekartik_bluetooth_test_app/src/ble_setup.dart';
import 'package:tekartik_platform_io/context_io.dart';

import 'import/import_bluetooth.dart';
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
        write('Using flutter blue');
        initWithFlutterBlue();
      }
    });
    /*
  test('crash', () {
    fail('fail');
  });
  */
    if (platformContext.io?.isLinux ?? false) {
      item('Use bluez', () {
        initWithBluez();
      });
    } else {
      item('Use flutter blue', () {
        initWithFlutterBlue();
      });
    }

    menu('Bluetooth init', () {
      item('getInfo', () async {
        var info = await initBluetoothManager.getAdminInfo();
        write('success $info');
      });
      item('enablePermissions', () async {
        await initBluetoothManager.checkBluetoothPermissions();
        write('success');
      });

      item('enablePeripheralPermissions', () async {
        await initBluetoothManager.checkBluetoothPermissions(
            options: BluetoothPermissionsOptions(advertise: true));
        write('success');
      });
      item('enable', () async {
        await initBluetoothManager.enable();
        write('success');
      });
    });
    item('Start app', () {
      app_main.main();
    });

    menu('Peripheral (android only)', () {
      BluetoothPeripheral? peripheral;

      item('initPeripheral', () async {
        //Periphe
        peripheral = await BluetoothFlutter.initPeripheral(
            deviceName: 'Test app peripheral');
        write('initPeripheral: $peripheral');
      });

      item('startAdvertising', () async {
        //Periphe
        await peripheral?.startAdvertising();
        write('startAdvertising: $peripheral');
      });
      item('stopAdvertising', () async {
        //Periphe
        await peripheral?.stopAdvertising();
        write('stopAdvertising: $peripheral');
      });
    });

    menu('BluetoothFlutter', () {
      item('Enable bluetooth', () async {
        await BluetoothFlutter.enableBluetooth(requestCode: 1234);
        write('success');
      });
    });

    menu('Flutter blue', () {
      item('Current state', () async {
        var state = await fbl.FlutterBluePlus.instance.state.first;
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
          for (var characteristic in service.characteristics) {
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
