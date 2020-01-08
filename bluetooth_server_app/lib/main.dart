import 'package:flutter/material.dart';
import 'package:tekartik_bluetooth_server_app/page/main_page.dart';

void main() => runApp(BluetoothServerApp());

void run() {
  runApp(BluetoothServerApp());
}

class BluetoothServerApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.blue,
      ),
      home: BluetoothServerHomePage(title: 'Bluetooth server'),
    );
  }
}

MaterialPageRoute<dynamic> get homePageRoute =>
    MaterialPageRoute<dynamic>(builder: (BuildContext context) {
      return BluetoothServerHomePage(title: 'Bluetooth server');
    });
