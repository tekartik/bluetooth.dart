import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter_peripheral.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_test_menu_flutter/test.dart';

void menuFlutterBlue() {
  menu('flutter_blue_connect', () {
    List<String> deviceIds = [];
    Map<String, BluetoothDevice> _devices = {};
    void _menu(String name) {
      StreamSubscription scanSubscription;
      StreamSubscription connectSubscription;
      StreamSubscription stateChangeSubscription;
      void _cancelScanSubscription() {
        scanSubscription?.cancel();
        scanSubscription = null;
      }

      item('connect_$name', () async {
        scanSubscription?.cancel();
        scanSubscription = FlutterBlue.instance
            .scan(timeout: Duration(seconds: 30))
            .listen((result) {
          var id = result.device?.id?.id;
          if (id != null && !deviceIds.contains(id)) {
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
          var device = _devices[deviceIds[i]];
          write('[$i]: ${device.id} ${device?.name}');
        }
        int index = parseInt(await prompt('Enter connect_$name index'));
        if (index != null) {
          var deviceId = deviceIds[index];
          var device = _devices[deviceId];
          _cancelScanSubscription();
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
          device.connect(autoConnect: true, timeout: Duration(seconds: 30));
        }
      });

      item('disconnect_$name', () {
        _cancelScanSubscription();
        connectSubscription?.cancel();
        connectSubscription = null;
      });

      item('stop_scan_$name', _cancelScanSubscription);
    }

    _menu("1");
    _menu("2");
  });
  menu('flutter_blue_scan', () {
    StreamSubscription stateSubscription;
    item('get_bt_state', () async {
      write('get_state: ${await FlutterBlue.instance.state.first}');
    });
    item('register_bt_state', () {
      FlutterBlue.instance.state.listen((state) {
        write('state: $state');
      }, onDone: () {
        write('register_bt_state done');
      }, onError: (e, st) {
        write('register_bt_state error $e');
        print(st);
      });
    });
    item('cancel_register_bt_state', () {
      stateSubscription?.cancel();
      stateSubscription = null;
    });

    void _menu(String name) {
      StreamSubscription scanSubscription;
      void _cancelSubscription() {
        scanSubscription?.cancel();
        scanSubscription = null;
      }

      item('scan_$name', () {
        scanSubscription?.cancel();
        scanSubscription = FlutterBlue.instance
            .scan(timeout: Duration(seconds: 30))
            .listen((result) {
          write(
              'scan_$name: ${result.device.id} ${result.device.name} ${result.rssi}');
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
}
