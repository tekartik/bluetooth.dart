// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
//import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_test_app/ble/app_ble.dart';
import 'package:tekartik_bluetooth_test_app/constant.dart';
import 'package:tekartik_bluetooth_test_app/import/common_import.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  _ScanPageState createState() => _ScanPageState();
}

class AppScanResult {
  final DateTime dateTime;
  final ScanResult scanResult;
  BluetoothDevice get device => scanResult.device;
  int get rssi => scanResult.rssi;

  AppScanResult(this.dateTime, this.scanResult);
}

class AppScanResults {
  List<AppScanResult>? list;
}

class _ScanPageState extends State<ScanPage> {
  StreamSubscription? scanSubscription;
  bool _inited = false;
  bool _initialScanStartDone = false;
  final results = BehaviorSubject<AppScanResults?>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ble scan'),
      ),
      body: Builder(builder: (context) {
        if (!_inited) {
          _inited = true;
          () async {
            // await bluetoothManager.devSetOptions(BluetoothOptions(logLevel: bluetoothLogLevelVerbose));
            try {
              await startScan(context);
            } finally {
              setState(() {
                _initialScanStartDone = true;
              });
            }
          }();
        }
        return StreamBuilder<AppScanResults?>(
            initialData: results.value,
            stream: results,
            builder: (context, snapshot) {
              if (scanSubscription == null) {
                return ListView(children: const <Widget>[
                  ListTile(
                    title: Text('Tap scan for devices'),
                  )
                ]);
              }
              var result = snapshot.data;
              var list = result?.list;
              if (list?.isEmpty ?? true) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                  itemCount: list!.length,
                  itemBuilder: (builder, index) {
                    var item = list[index];
                    var deviceId = item.device.id;
                    return ListTile(
                      leading: Text(
                          item.dateTime.toIso8601String().substring(11, 19)),
                      title: Text(item.device.name ?? deviceId.id),
                      subtitle: Text(deviceId.id),
                      trailing: Text(item.rssi.toString()),
                      onTap: () {
                        Navigator.of(context).pop(deviceId);
                      },
                    );
                  });
            });
      }),
      floatingActionButton: _initialScanStartDone
          ? FloatingActionButton(
              onPressed: () {
                () async {
                  if (scanSubscription == null) {
                    await startScan(context);
                  } else {
                    setState(() {
                      stopScan();
                    });
                  }
                }();
              },
              tooltip: 'Refresh',
              child:
                  Icon(scanSubscription == null ? Icons.refresh : Icons.stop),
            )
          : null, //
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    stopScan();
    results.close();
    super.dispose();
  }

  void stopScan() {
    results.add(null);
    scanSubscription?.cancel();
    scanSubscription = null;
  }

  Future startScan(BuildContext context) async {
    print('stopScanning');
    stopScan();
    var info = await initBluetoothManager.getInfo();
    // devPrint('info: $info');
    if (!info.hasBluetoothBle!) {
      const snackBar = SnackBar(content: Text('Bluetooth BLE not supported'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    } else if (!info.isBluetoothEnabled!) {
      if (initBluetoothManager.supportsEnable!) {
        await initBluetoothManager.enable(
            androidRequestCode: androidEnableBluetoothRequestCode);
        info = await initBluetoothManager.getInfo();
      }
    }
    if (!info.isBluetoothEnabled!) {
      const snackBar =
          SnackBar(content: Text('Please enable Bluetooth on your device'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    if (initBluetoothManager.isAndroid!) {
      if (!await initBluetoothManager.checkCoarseLocationPermission(
          androidRequestCode: androidCheckCoarseLocationPermission)) {
        const snackBar = SnackBar(
            content: Text(
                'Please enable location services to scan for nearby devices'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
    print('scanning...');
    scanSubscription = deviceBluetoothManager.scan().listen((data) {
      // devPrint('$data');
      var scanResults = results.value;
      var list = scanResults?.list;
      var appScanResult = AppScanResult(DateTime.now(), data);
      list =
          (list == null) ? <AppScanResult>[] : List<AppScanResult>.from(list);
      var index =
          list.indexWhere((result) => result.device.id == data.device.id);
      if (index < 0) {
        list.add(appScanResult);
      } else {
        list[index] = appScanResult;
      }
      scanResults = AppScanResults()..list = list;
      results.add(scanResults);
    });
  }
}
