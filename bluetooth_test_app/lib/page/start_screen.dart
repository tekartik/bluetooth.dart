import 'package:flutter/material.dart';
import 'package:tekartik_bluetooth_test_app/ble/app_ble.dart';
import 'package:tekartik_bluetooth_test_app/import/common_import.dart';
import 'package:tekartik_bluetooth_test_app/import/import_bluetooth.dart';
import 'package:tekartik_bluetooth_test_app/page/device_page.dart';
import 'package:tekartik_bluetooth_test_app/page/peripheral_screen.dart';
import 'package:tekartik_bluetooth_test_app/page/scan_page.dart';

import '../test_main.dart' as test_main;

typedef StartScreenAutoStartFunction = Future<void> Function(
    BuildContext context);

StartScreenAutoStartFunction? startScreenAutoStartFunction;

class StartScreen extends StatefulWidget {
  const StartScreen({Key? key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String? title;

  @override
  // ignore: library_private_types_in_public_api
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    sleep(0).then((_) async {
      if (startScreenAutoStartFunction != null && mounted) {
        var fn = startScreenAutoStartFunction!;
        startScreenAutoStartFunction = null;
        await fn(context);
      }
    });
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
            title: const Text('Simple peripheral (Android only)'),
            onTap: () async {
              await goToPeripheralScreen(context);
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
    if (initBluetoothManager.supportsEnable ?? false) {}
    if (initBluetoothManager.isAndroid ?? false) {
      // devPrint('Check permission');
      if (!await initBluetoothManager.checkBluetoothPermissions(
          androidRequestCode: 1234)) {
        // devPrint('Permissions denied');
        return;
      }
    }
    // ignore: use_build_context_synchronously
    var deviceId = await Navigator.of(context).push<BluetoothDeviceId>(
        MaterialPageRoute(builder: (_) => const ScanPage()));
    if (deviceId != null) {
      // ignore: use_build_context_synchronously
      await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => DevicePage(deviceId: deviceId)));
    }
  }
}
