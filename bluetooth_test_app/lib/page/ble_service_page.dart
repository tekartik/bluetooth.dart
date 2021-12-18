import 'package:flutter/material.dart';
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_test_app/page/ble_characteristic_page.dart';
import 'package:tekartik_bluetooth_test_app/utils/app_utils.dart';

class AppBleService {
  final BluetoothDeviceConnection? connection;
  final BleBluetoothService bleService;

  AppBleService({required this.connection, required this.bleService});
}

class BleServicePage extends StatefulWidget {
  final AppBleService appBleService;

  const BleServicePage({Key? key, required this.appBleService})
      : super(key: key);

  @override
  _BleServicePageState createState() => _BleServicePageState();
}

class _BleServicePageState extends State<BleServicePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service'),
      ),
      body: Builder(builder: (context) {
        var service = widget.appBleService.bleService;
        var characteristics = service.characteristics;
        if (characteristics.isEmpty) {
          return ListView(children: const <Widget>[
            ListTile(title: Text('No characteristics found'))
          ]);
        }
        return ListView(
          children: [
            ListTile(
                title: const Text('Service'),
                subtitle: Text(uuidText(service.uuid))),
            ...characteristics.map((characteristic) {
              var propertiesText = propertiesAsText(characteristic.properties);
              return ListTile(
                title: const Text('Characteristic'),
                subtitle: Text(
                    '${uuidText(characteristic.uuid, parent: service.uuid)}${propertiesText.isNotEmpty ? '\n$propertiesText' : ''}'),
                onTap: () {
                  () async {
                    await Navigator.of(context).push<String>(MaterialPageRoute(
                        builder: (_) => BleCharacteristicPage(
                            appBleCharacteristic: AppBleCharacteristic(
                                connection: widget.appBleService.connection,
                                characteristic: characteristic))));
                  }();
                },
              );
            }).toList(growable: false)
          ],
        );
      }),
    );
  }
}
