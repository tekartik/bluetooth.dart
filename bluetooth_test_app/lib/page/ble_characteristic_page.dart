import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_flutter/src/constant.dart'; // ignore: implementation_imports
import 'package:tekartik_bluetooth_test_app/utils/app_uuid_utils.dart';
import 'package:tekartik_common_utils/hex_utils.dart';

class AppBleCharacteristic {
  final BluetoothDeviceConnection? connection;
  final BleBluetoothCharacteristic characteristic;

  AppBleCharacteristic(
      {required this.connection, required this.characteristic});
}

class _ValueState {
  dynamic exception;
  Uint8List? value;
}

class BleCharacteristicPage extends StatefulWidget {
  final AppBleCharacteristic? appBleCharacteristic;

  const BleCharacteristicPage({Key? key, this.appBleCharacteristic})
      : super(key: key);

  @override
  _BleCharacteristicPageState createState() => _BleCharacteristicPageState();
}

class _BleCharacteristicPageState extends State<BleCharacteristicPage> {
  final valueSubject = BehaviorSubject<_ValueState>();

  @override
  Widget build(BuildContext context) {
    var connection = widget.appBleCharacteristic!.connection;
    var descriptors = widget.appBleCharacteristic?.characteristic.descriptors;
    var characteristic = widget.appBleCharacteristic?.characteristic;

    var canRead = ((characteristic?.properties ?? 0) & blePropertyRead) != 0;

    var propertySb = StringBuffer();
    void _addPropertyText(String text, bool test) {
      if (test) {
        if (propertySb.isNotEmpty) {
          propertySb.write(', ');
        }
        propertySb.write(text);
      }
    }

    _addPropertyText('read', canRead);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Characteristic'),
        ),
        body: ListView(children: <Widget>[
          ListTile(
              title: const Text('Characteristic'),
              subtitle: Text(uuidText(characteristic?.uuid))),
          ListTile(
              title: const Text('Properties'),
              subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(widget.appBleCharacteristic?.characteristic.properties
                            .toRadixString(2) ??
                        'no properties'),
                    if (propertySb.isNotEmpty) Text(propertySb.toString())
                  ])),
          if (descriptors?.isNotEmpty ?? false)
            ...descriptors!.map((descriptor) {
              return ListTile(
                  title: const Text('Descriptor'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(uuidText(descriptor.uuid,
                          parent: characteristic?.uuid))
                    ],
                  ));
            }),
          if (canRead)
            StreamBuilder<_ValueState>(
                initialData: valueSubject.value,
                stream: valueSubject,
                builder: (context, snapshot) {
                  var state = snapshot.data;
                  return ListTile(
                      leading: ElevatedButton(
                        onPressed: () {
                          () async {
                            try {
                              var bcv = await connection!.readCharacteristic(
                                  widget.appBleCharacteristic!.characteristic);
                              valueSubject
                                  .add(_ValueState()..value = bcv.value);
                            } catch (e) {
                              valueSubject.add(_ValueState()..exception = e);
                            }
                          }();
                        },
                        child: const Text('READ'),
                      ),
                      subtitle: state == null
                          ? null
                          : ((state.exception != null)
                              ? Text(state.exception.toString())
                              : Text(hexPretty(state.value) ?? '[null]')));
                })
        ]));
  }

  @override
  void dispose() {
    valueSubject.close();
    super.dispose();
  }
}
