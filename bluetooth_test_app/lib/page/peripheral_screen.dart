import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tekartik_bluetooth_test_app/ble/simple_peripheral.dart';
import 'package:tekartik_bluetooth_test_app/import/common_import.dart';

class PeripheralScreen extends StatefulWidget {
  const PeripheralScreen({super.key});

  @override
  State<PeripheralScreen> createState() => _PeripheralScreenState();
}

String nameFromDateTime(DateTime dateTime) {
  var name = dateTime
      .toIso8601String()
      .replaceAll(':', '')
      .replaceAll('-', '')
      .replaceAll('T', '')
      .substring(8, 14);
  return 'TK$name';
}

class _PeripheralScreenState extends State<PeripheralScreen> {
  var peripheral =
      SimplePeripheral(deviceName: nameFromDateTime(DateTime.now()));
  Timer? _timer;

  @override
  void initState() {
    peripheral.init();

    super.initState();
  }

  void _sendTimeEverySeconds() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (peripheral.connectedDevices.isNotEmpty) {
        peripheral.notifyConnectedDevices();
      }
    });
  }

  @override
  void dispose() {
    peripheral.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Peripheral ${peripheral.deviceName}'),
        ),
        body: ListView(
          children: [
            const SizedBox(height: 32),
            Center(
              child: Text('Peripheral ${peripheral.deviceName}'),
            ),
            StreamBuilder(
              stream: peripheral.onConnectedDeviceList,
              builder: (context, snapshot) {
                var list = snapshot.data ?? <String>[];
                if (list.isEmpty) {
                  return const ListTile(title: Text('No device connected'));
                }
                return Column(children: [
                  const ListTile(title: Text('Connected devices')),
                  ...list.map((e) => ListTile(
                        title: Text(e),
                        dense: true,
                      ))
                ]);
              },
            ),
            StreamBuilder(
              stream: peripheral.onValueWritten,
              builder: (context, snapshot) {
                var value = snapshot.data ?? Uint8List(0);
                return ListTile(
                    title: const Text('Value written'),
                    subtitle: Text(toHexString(value)!));
              },
            ),
            SwitchListTile(
                title: const Text('Notify every seconds'),
                value: _timer != null,
                onChanged: (value) {
                  if (value) {
                    _sendTimeEverySeconds();
                  } else {
                    _timer?.cancel();
                    _timer = null;
                  }
                  setState(() {});
                }),
          ],
        ));
  }
}

Future<void> goToPeripheralScreen(BuildContext context) async {
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) {
    return const PeripheralScreen();
  }));
}
