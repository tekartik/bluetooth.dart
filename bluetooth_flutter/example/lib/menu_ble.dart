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

void menuBle({
  int? androidEnableRequestCode,
  int? androidCheckCoarseLocationPermissionRequestCode,
}) {
  androidEnableRequestCode ??= 1;
  androidCheckCoarseLocationPermissionRequestCode ??=
      androidEnableRequestCode + 1;

  @Deprecated('do not use')
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
      writeln(info.toString());
    });
    item('get_connected_devices', () async {
      var devices = await bluetoothManagerFlutter.getConnectedDevices();
      for (var device in devices) {
        writeln(device.toString());
      }
    });
    item('bt_on', () async {
      var bluetoothStateService = await getBluetoothStateService();
      writeln('support enable: ${bluetoothStateService.supportsEnable}');
      await bluetoothStateService
          .enable()
          .then((_) {
            writeln('enable done');
          })
          .catchError((Object e, StackTrace st) {
            writeln('enable error $e');
            writeln(st);
          });
    });
    item('bt_on_request', () async {
      var bluetoothStateService = await getBluetoothStateService();
      writeln('support enable: ${bluetoothStateService.supportsEnable}');
      await bluetoothStateService
          .enable(androidRequestCode: enableBluetoothRequestCode)
          .then((_) {
            writeln('enable with request done');
          })
          .catchError((Object e, StackTrace st) {
            writeln('enable with request error $e');
            stdout.writeln(st);
            writeln(st);
            writeln(st);
          });
    });
    item('checkCoarseLocation', () async {
      var info =
          // ignore: deprecated_member_use
          await bluetoothAdminManagerFlutter.checkCoarseLocationPermission(
            androidRequestCode: androidCheckCoarseLocationPermissionRequestCode,
          );
      writeln(info.toString());
    });
    item('checkBluetoothPermissions(scan & connect)', () async {
      var info = await bluetoothAdminManagerFlutter.checkBluetoothPermissions();
      writeln(info.toString());
    });
    item('checkBluetoothPermissions(advertise)', () async {
      var info = await bluetoothAdminManagerFlutter.checkBluetoothPermissions(
        options: BluetoothPermissionsOptions(advertise: true),
      );
      writeln(info.toString());
    });
    item('bt_off', () async {
      var bluetoothStateService = await getBluetoothStateService();
      writeln('support enable: ${bluetoothStateService.supportsEnable}');
      await bluetoothStateService
          .disable()
          .then((_) {
            writeln('disable done');
          })
          .catchError((Object e, StackTrace st) {
            writeln('disable error $e');
            stdout.writeln(st);
          });
    });
  });

  menu('ble_scan', () {
    void scanMenu(String name) {
      StreamSubscription? scanSubscription;
      void cancelSubscription() {
        scanSubscription?.cancel();
        scanSubscription = null;
      }

      item('scan_$name', () {
        scanSubscription?.cancel();
        scanSubscription = bluetoothManagerFlutter.scan().listen(
          (result) {
            writeln(
              'scan_$name: ${result.device.address} ${result.device.name} ${result.rssi}',
            );
          },
          onDone: () {
            writeln('scan_$name: done');
          },
          onError: (Object e, StackTrace st) {
            writeln('scan_$name: error $e');
            writeln(st);
          },
        );
      });

      item('stop_scan_$name', cancelSubscription);
    }

    scanMenu('1');
    scanMenu('2');
  });

  menu('ble_peripheral', () {
    var serviceUuid = Uuid128('0000f001-0000-1000-8000-00805f9b34fb');
    var characteristicUuid = Uuid128('0000f002-0000-1000-8000-00805f9b34fb');
    late BluetoothPeripheral peripheral;
    StreamSubscription? subscription;
    enter(() {
      subscription = BluetoothFlutter.onSlaveConnectionChanged().listen((
        BluetoothSlaveConnection connection,
      ) {
        writeln('${connection.address} ${connection.connected}');
      });
    });
    leave(() {
      subscription?.cancel();
      subscription = null;
    });
    item('startAdvertising', () async {
      writeln('setting peripheral');
      var services = <BluetoothGattService>[
        BluetoothGattService(
          uuid: serviceUuid,
          characteristics: <BluetoothGattCharacteristic>[
            BluetoothGattCharacteristic(
              uuid: characteristicUuid,
              properties:
                  BluetoothGattCharacteristic.propertyNotify |
                  BluetoothGattCharacteristic.propertyRead,
              permissions: BluetoothGattCharacteristic.permissionRead,
            ),
          ],
        ),
      ];
      peripheral = await BluetoothFlutter.initPeripheral(services: services);
      writeln(jsonPretty(peripheral.toMap())!);
      writeln('starting');
      var advertiseData = AdvertiseData(
        services: [
          AdvertiseDataService(uuid: Uuid128(demoAdvertiseDataServiceUuid)),
        ],
      );
      await BluetoothFlutter.startAdvertising(advertiseData: advertiseData);
      writeln('Started');
    });

    item('stopAdvertising', () async {
      writeln('stopping');
      await BluetoothFlutter.stopAdvertising();
      writeln('Stopped');
    });

    item('setValue [1]', () async {
      var result = await peripheral.setCharacteristicValue(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        value: Uint8List.fromList([1]),
      );
      writeln(result);
    });

    item('setValue [2]', () async {
      var result = await peripheral.setCharacteristicValue(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        value: Uint8List.fromList([2]),
      );
      writeln(result);
    });

    item('getValue', () async {
      var result = await peripheral.getCharacteristicValue(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );
      writeln(result);
    });
  });

  menu('ble_connect', () {
    var deviceIds = <BluetoothDeviceId>[];
    var devices0 = <BluetoothDeviceId, BluetoothDevice>{};
    void scanMenu(String name) {
      StreamSubscription? scanSubscription;
      BluetoothDeviceConnection? deviceConnection;
      // StreamSubscription? stateChangeSubscription;

      void cancelScanSubscription() {
        scanSubscription?.cancel();
        scanSubscription = null;
      }

      item('connect_$name', () async {
        await scanSubscription?.cancel();
        scanSubscription = bluetoothManagerFlutter.scan().listen(
          (result) {
            var id = result.device.id;
            if (!deviceIds.contains(id)) {
              writeln(
                '[${devices0.length}] scan_$name: ${result.device.id} ${result.device.name} ${result.rssi}',
              );
              deviceIds.add(id);
              devices0[id] = result.device;
            }
          },
          onDone: () {
            writeln('scan_$name: done');
          },
          onError: (Object e, StackTrace st) {
            writeln('scan_$name: error $e');
            writeln(st);
          },
        );

        for (var i = 0; i < deviceIds.length; i++) {
          var device = devices0[deviceIds[i]]!;
          writeln('[$i]: ${device.id} ${device.name}');
        }
        var index = parseInt(await prompt('Enter connect_$name index'));
        if (index != null) {
          var deviceId = deviceIds[index];

          cancelScanSubscription();
          /*
          stateChangeSubscription?.cancel();
          stateChangeSubscription = device.state.listen((state) {
            writeln('onStateChanged_$name $state');
          }, onDone: () {
            writeln('onStateChanged_$name done');
          });
          writeln('get_state_$name ${await device.state.first}');

          writeln('connecting ${device.id}');
          connectSubscription = device.state.listen((state) {
            writeln('state_$name: $state');
          }, onDone: () {
            writeln('scan_$name: connect done');
          }, onError: (Object e, StackTrace st) {
            writeln('scan_$name: connect error $e');
            writeln(st);
          });
           */
          // device.connect(autoConnect: true, timeout: Duration(seconds: 30));
          deviceConnection = await bluetoothManagerFlutter.newConnection(
            deviceId,
          );
          deviceConnection!.onConnectionState.listen((state) {
            writeln('connect state: $state');
          });
        }
      });

      item('disconnect_$name', () async {
        cancelScanSubscription();
        await deviceConnection!.disconnect();
      });

      item('close $name', () async {
        cancelScanSubscription();
        deviceConnection?.close();
        deviceConnection = null;
      });

      item('stop_scan_$name', cancelScanSubscription);
    }

    scanMenu('1');
    scanMenu('2');
  });
}
