//import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';
// ignore: implementation_imports
import 'package:tekartik_bluetooth_flutter_blue/src/flutter_blue_import.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_test_menu_flutter/test.dart';

void menuFlutterBlue() {
  menu('flutter_blue_connect', () {
    var deviceIds = <String>[];
    var devices = <String, BluetoothDevice>{};
    void menu(String name) {
      StreamSubscription? scanSubscription;
      StreamSubscription? connectSubscription;
      StreamSubscription? stateChangeSubscription;
      void cancelScanSubscription() {
        scanSubscription?.cancel();
        scanSubscription = null;
      }

      item('connect_$name', () async {
        await scanSubscription?.cancel();
        scanSubscription =
            FlutterBluePlusPrvExt.scanAndStreamResults(
              timeout: const Duration(seconds: 30),
            ).listen(
              (result) {
                var id = result.device.remoteId.str;
                if (!deviceIds.contains(id)) {
                  write(
                    '[${devices.length}] scan_$name: ${result.device.remoteId} ${result.device.platformName} ${result.rssi}',
                  );
                  deviceIds.add(id);
                  devices[id] = result.device;
                }
              },
              onDone: () {
                write('scan_$name: done');
              },
              onError: (Object e, StackTrace st) {
                write('scan_$name: error $e');
                writeln(st);
              },
            );

        for (var i = 0; i < deviceIds.length; i++) {
          var device = devices[deviceIds[i]]!;
          write('[$i]: ${device.remoteId} ${device.platformName}');
        }
        var index = parseInt(await prompt('Enter connect_$name index'));
        if (index != null) {
          var deviceId = deviceIds[index];
          var device = devices[deviceId]!;
          cancelScanSubscription();
          await stateChangeSubscription?.cancel();
          stateChangeSubscription = device.connectionState.listen(
            (state) {
              write('onStateChanged_$name $state');
            },
            onDone: () {
              write('onStateChanged_$name done');
            },
          );
          write('get_state_$name ${await device.connectionState.first}');

          write('connecting ${device.remoteId}');
          connectSubscription = device.connectionState.listen(
            (state) {
              write('state_$name: $state');
            },
            onDone: () {
              write('scan_$name: connect done');
            },
            onError: (Object e, StackTrace st) {
              write('scan_$name: connect error $e');
              writeln(st);
            },
          );
          await device.connect(
            license: License.nonprofit,
            autoConnect: true,
            timeout: const Duration(seconds: 30),
          );
        }
      });

      item('disconnect_$name', () {
        cancelScanSubscription();
        connectSubscription?.cancel();
        connectSubscription = null;
      });

      item('stop_scan_$name', cancelScanSubscription);
    }

    menu('1');
    menu('2');
  });
  menu('flutter_blue_scan', () {
    StreamSubscription? stateSubscription;
    item('get_bt_state', () async {
      write('get_state: ${await FlutterBluePlus.adapterState.first}');
    });
    item('register_bt_state', () {
      FlutterBluePlus.adapterState.listen(
        (state) {
          write('state: $state');
        },
        onDone: () {
          write('register_bt_state done');
        },
        onError: (Object e, StackTrace st) {
          write('register_bt_state error $e');
          writeln(st);
        },
      );
    });
    item('cancel_register_bt_state', () {
      stateSubscription?.cancel();
      stateSubscription = null;
    });

    void menu(String name) {
      StreamSubscription? scanSubscription;
      void cancelSubscription() {
        scanSubscription?.cancel();
        scanSubscription = null;
      }

      item('scan_$name', () {
        scanSubscription?.cancel();
        scanSubscription =
            FlutterBluePlusPrvExt.scanAndStreamResults(
              timeout: const Duration(seconds: 30),
            ).listen(
              (result) {
                write(
                  'scan_$name: ${result.device.remoteId} ${result.device.platformName} ${result.rssi}',
                );
              },
              onDone: () {
                write('scan_$name: done');
              },
              onError: (Object e, StackTrace st) {
                write('scan_$name: error $e');
                writeln(st);
              },
            );
      });

      item('stop_scan_$name', cancelSubscription);
    }

    menu('1');
    menu('2');
  });
}
