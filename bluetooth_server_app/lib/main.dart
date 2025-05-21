import 'package:flutter/material.dart';
import 'package:tekartik_bluetooth_server_app/page/main_page.dart';

void main() => runApp(const BluetoothServerApp());

void run() {
  runApp(const BluetoothServerApp());
}

class BluetoothServerApp extends StatelessWidget {
  const BluetoothServerApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.blue,
      ),
      home: const BluetoothServerHomePage(title: 'Bluetooth server'),
    );
  }
}

MaterialPageRoute<dynamic> get homePageRoute => MaterialPageRoute<dynamic>(
  builder: (BuildContext context) {
    return const BluetoothServerHomePage(title: 'Bluetooth server');
  },
);
