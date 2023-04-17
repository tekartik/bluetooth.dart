import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tekartik_app_platform/app_platform.dart';
import 'package:tekartik_bluetooth_test_app/page/peripheral_screen.dart';
import 'package:tekartik_bluetooth_test_app/page/start_screen.dart';
import 'package:tekartik_bluetooth_test_app/src/ble_setup.dart';

import 'import/common_import.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (platformContext.io?.isLinux ?? false) {
    initWithBluez();
  } else if (kIsWeb) {
    initWithBleWeb();
  } else {
    initWithFlutterBlue();
  }
  // ignore: dead_code
  if (false) {
    // Quick test
    startScreenAutoStartFunction = ((context) async {
      await goToPeripheralScreen(context);
    });
  }
  runApp(const BleTestApp());
}

class BleTestApp extends StatelessWidget {
  const BleTestApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      home: const StartScreen(title: 'Bluetooth test app'),
    );
  }
}
