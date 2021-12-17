import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth_test_app/ble/app_ble.dart';
import 'package:tekartik_bluetooth_test_app/page/device_page.dart';
import 'package:tekartik_bluetooth_test_app/page/scan_page.dart';
import 'package:tekartik_bluetooth_test_app/src/ble_setup.dart';
import 'package:tekartik_platform_io/context_io.dart';

import 'import/common_import.dart';
import 'test_main.dart' as test_main;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (platformContextIo.io?.isLinux ?? false) {
    initWithBluez();
  } else {
    initWithFlutterBlue();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth test app',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Bluetooth test app'),
    );
  }
}

var _scanOnStart = true;

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    if (_scanOnStart) {
      _scanOnStart = false;
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
        if (mounted) {
          await _scan(context);
        }
      });
    }
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title!),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Scan & Select'),
            onTap: () async {
              await _scan(context);
            },
          ),
          ListTile(
            title: const Text('Test menu'),
            onTap: () {
              test_main.main();
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          () async {
            await _scan(context);
          }();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> _scan(BuildContext context) async {
    if (Platform.isAndroid) {
      // devPrint('Check permission');
      if (!await initBluetoothManager.checkCoarseLocationPermission(
          androidRequestCode: 1234)) {
        // devPrint('Permissions denied');
        return;
      }
    }
    var deviceId = await Navigator.of(context).push<BluetoothDeviceId>(
        MaterialPageRoute(builder: (_) => const ScanPage()));
    if (deviceId != null) {
      await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => DevicePage(deviceId: deviceId)));
    }
  }
}
