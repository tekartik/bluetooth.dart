import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';

import 'menu_main.dart' as menu_main;

// void main() => runApp(MyApp());
void main() => menu_main.main();

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BluetoothInfo? _bluetoothInfo;
  DateTime? _statusDate;
  final _bluetoothManager = bluetoothManagerFlutter;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    /*
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await BluetoothFlutter.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    var bluetoothStatus = await BluetoothFlutter.bluetoothStatus;

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _statusDate = now;
      _platformVersion = platformVersion;
      _bluetoothStatus = bluetoothStatus;
    });
    */
    await getStatus();
  }

  Future getStatus() async {
    var now = DateTime.now();
    var bluetoothState = await _bluetoothManager.getInfo();
    print('$now $bluetoothState');

    _setVars() {
      _statusDate = now;
      _bluetoothInfo = bluetoothState;
    }

    if (!mounted) {
      _setVars();
      return;
    }

    setState(() {
      _setVars();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            children: <Widget>[
              Text('on: $_statusDate\nBluetooth status $_bluetoothInfo'),
              ElevatedButton(
                child: Text('enable'),
                onPressed: () async {
                  BluetoothFlutter.enableBluetooth(requestCode: 1);
                  await getStatus();
                },
              ),
              ElevatedButton(
                child: Text('enable admin'),
                onPressed: () async {
                  BluetoothFlutter.enableBluetooth();
                  await getStatus();
                },
              ),
              ElevatedButton(
                child: Text('disable'),
                onPressed: () async {
                  BluetoothFlutter.disableBluetooth();
                  await getStatus();
                },
              ),
              ElevatedButton(
                child: Text('getStatus'),
                onPressed: () async {
                  await getStatus();
                },
              ),
              ElevatedButton(
                child: Text('startAdvertising'),
                onPressed: () async {
                  await BluetoothFlutter.startAdvertising();
                },
              ),
              ElevatedButton(
                child: Text('stopAdvertising'),
                onPressed: () async {
                  await BluetoothFlutter.stopAdvertising();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
