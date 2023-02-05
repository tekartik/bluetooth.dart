import 'dart:io';
import 'dart:typed_data';

import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter.dart'
    show BluetoothFlutter;
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter_peripheral.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_flutter_example/ble_utils.dart';
import 'package:tekartik_bluetooth_flutter_example/constant.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_test_menu_flutter/test.dart';

void menuBle(
    {int? androidEnableRequestCode,
    int? androidCheckCoarseLocationPermissionRequestCode}) {
  androidEnableRequestCode ??= 1;
  androidCheckCoarseLocationPermissionRequestCode ??=
      androidEnableRequestCode + 1;

  @deprecated
  Future enableLogs() async {
    await bluetoothAdminManagerFlutter
        // ignore: deprecated_member_use
        .devSetOptions(BluetoothOptions()..logLevel = bluetoothLogLevelVerbose);
  }

  menu('ble_state', () {
    item('enable_verbose_logs', () async {
      // ignore: deprecated_member_use_from_same_package
      await enableLogs();
    });
    item('disable_logs', () async {
      await bluetoothAdminManagerFlutter
          // ignore: deprecated_member_use
          .devSetOptions(BluetoothOptions()..logLevel = bluetoothLogLevelNone);
    });
    item('init', () async {
      // await enableLogs();
      await bluetoothManagerFlutter.init();
    });
    item('get_info', () async {
      var info = await bluetoothManagerFlutter.getInfo();
      write(info.toString());
    });
    item('get_connected_devices', () async {
      var devices = await bluetoothManagerFlutter.getConnectedDevices();
      devices.forEach((device) {
        write(device.toString());
      });
    });
    item('bt_on', () async {
      var bluetoothStateService = await getBluetoothStateService();
      write('support enable: ${bluetoothStateService.supportsEnable}');
      await bluetoothStateService.enable().then((_) {
        write('enable done');
      }).catchError((e, st) {
        write('enable error $e');
        print(st);
      });
    });
    item('bt_on_request', () async {
      var bluetoothStateService = await getBluetoothStateService();
      write('support enable: ${bluetoothStateService.supportsEnable}');
      await bluetoothStateService
          .enable(androidRequestCode: enableBluetoothRequestCode)
          .then((_) {
        write('enable with request done');
      }).catchError((e, st) {
        write('enable with request error $e');
        stdout.writeln(st);
        print(st);
        write(st);
      });
    });
    item('checkCoarseLocation', () async {
      var info =
          // ignore: deprecated_member_use
          await bluetoothAdminManagerFlutter.checkCoarseLocationPermission(
              androidRequestCode:
                  androidCheckCoarseLocationPermissionRequestCode);
      write(info.toString());
    });
    item('checkBluetoothPermissions(scan & connect)', () async {
      var info = await bluetoothAdminManagerFlutter.checkBluetoothPermissions();
      write(info.toString());
    });
    item('checkBluetoothPermissions(advertise)', () async {
      var info = await bluetoothAdminManagerFlutter.checkBluetoothPermissions(
          options: BluetoothPermissionsOptions(advertise: true));
      write(info.toString());
    });
    item('bt_off', () async {
      var bluetoothStateService = await getBluetoothStateService();
      write('support enable: ${bluetoothStateService.supportsEnable}');
      bluetoothStateService.disable().then((_) {
        write('disable done');
      }).catchError((e, st) {
        write('disable error $e');
        stdout.writeln(st);
      });
    });
  });

  menu('ble_scan', () {
    void _menu(String name) {
      StreamSubscription? scanSubscription;
      void _cancelSubscription() {
        scanSubscription?.cancel();
        scanSubscription = null;
      }

      item('scan_$name', () {
        scanSubscription?.cancel();
        scanSubscription = bluetoothManagerFlutter.scan().listen((result) {
          write(
              'scan_$name: ${result.device.address} ${result.device.name} ${result.rssi}');
        }, onDone: () {
          write('scan_$name: done');
        }, onError: (e, st) {
          write('scan_$name: error $e');
          print(st);
        });
      });

      item('stop_scan_$name', _cancelSubscription);
    }

    _menu("1");
    _menu("2");
  });

  menu('ble_peripheral', () {
    var serviceUuid = Uuid128('0000f001-0000-1000-8000-00805f9b34fb');
    var characteristicUuid = Uuid128('0000f002-0000-1000-8000-00805f9b34fb');
    late BluetoothPeripheral peripheral;
    StreamSubscription? subscription;
    enter(() {
      subscription = BluetoothFlutter.onSlaveConnectionChanged()
          .listen((BluetoothSlaveConnection connection) {
        write('${connection.address} ${connection.connected}');
      });
    });
    leave(() {
      subscription?.cancel();
      subscription = null;
    });
    item('startAdvertising', () async {
      write('setting peripheral');
      var services = <BluetoothGattService>[
        BluetoothGattService(
            uuid: serviceUuid,
            characteristics: <BluetoothGattCharacteristic>[
              BluetoothGattCharacteristic(
                  uuid: characteristicUuid,
                  properties: BluetoothGattCharacteristic.propertyNotify |
                      BluetoothGattCharacteristic.propertyRead,
                  permissions: BluetoothGattCharacteristic.permissionRead)
            ])
      ];
      peripheral = await BluetoothFlutter.initPeripheral(services: services);
      write(jsonPretty(peripheral.toMap())!);
      write('starting');
      var advertiseData = AdvertiseData(services: [
        AdvertiseDataService(uuid: Uuid128(demoAdvertiseDataServiceUuid))
      ]);
      await BluetoothFlutter.startAdvertising(advertiseData: advertiseData);
      write('Started');
    });

    item('stopAdvertising', () async {
      write('stopping');
      await BluetoothFlutter.stopAdvertising();
      write('Stopped');
    });

    item('setValue [1]', () async {
      var result = await peripheral.setCharacteristicValue(
          serviceUuid: serviceUuid,
          characteristicUuid: characteristicUuid,
          value: Uint8List.fromList([1]));
      write(result);
    });

    item('setValue [2]', () async {
      var result = await peripheral.setCharacteristicValue(
          serviceUuid: serviceUuid,
          characteristicUuid: characteristicUuid,
          value: Uint8List.fromList([2]));
      write(result);
    });

    item('getValue', () async {
      var result = await peripheral.getCharacteristicValue(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );
      write(result);
    });
  });

  menu('ble_connect', () {
    List<BluetoothDeviceId> deviceIds = [];
    Map<BluetoothDeviceId, BluetoothDevice> _devices = {};
    void _menu(String name) {
      StreamSubscription? scanSubscription;
      BluetoothDeviceConnection? deviceConnection;
      // StreamSubscription? stateChangeSubscription;

      void _cancelScanSubscription() {
        scanSubscription?.cancel();
        scanSubscription = null;
      }

      item('connect_$name', () async {
        scanSubscription?.cancel();
        scanSubscription = bluetoothManagerFlutter.scan().listen((result) {
          var id = result.device.id;
          if (!deviceIds.contains(id)) {
            write(
                '[${_devices.length}] scan_$name: ${result.device.id} ${result.device.name} ${result.rssi}');
            deviceIds.add(id);
            _devices[id] = result.device;
          }
        }, onDone: () {
          write('scan_$name: done');
        }, onError: (e, st) {
          write('scan_$name: error $e');
          print(st);
        });

        for (int i = 0; i < deviceIds.length; i++) {
          var device = _devices[deviceIds[i]]!;
          write('[$i]: ${device.id} ${device.name}');
        }
        int? index = parseInt(await prompt('Enter connect_$name index'));
        if (index != null) {
          var deviceId = deviceIds[index];

          _cancelScanSubscription();
          /*
          stateChangeSubscription?.cancel();
          stateChangeSubscription = device.state.listen((state) {
            write('onStateChanged_$name $state');
          }, onDone: () {
            write('onStateChanged_$name done');
          });
          write('get_state_$name ${await device.state.first}');

          write('connecting ${device.id}');
          connectSubscription = device.state.listen((state) {
            write('state_$name: $state');
          }, onDone: () {
            write('scan_$name: connect done');
          }, onError: (e, st) {
            write('scan_$name: connect error $e');
            print(st);
          });
           */
          // device.connect(autoConnect: true, timeout: Duration(seconds: 30));
          deviceConnection =
              await bluetoothManagerFlutter.newConnection(deviceId);
          deviceConnection!.onConnectionState.listen((state) {
            write('connect state: $state');
          });
        }
      });

      item('disconnect_$name', () async {
        _cancelScanSubscription();
        deviceConnection!.disconnect();
      });

      item('close $name', () async {
        _cancelScanSubscription();
        deviceConnection?.close();
        deviceConnection = null;
      });

      item('stop_scan_$name', _cancelScanSubscription);
    }

    _menu("1");
    _menu("2");
  });
}
