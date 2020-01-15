import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_test_app/import/common_import.dart';
import 'package:tekartik_bluetooth_test_app/page/ble_service_page.dart';

class DevicePage extends StatefulWidget {
  final String deviceId;

  const DevicePage({Key key, @required this.deviceId}) : super(key: key);

  @override
  _DevicePageState createState() => _DevicePageState();
}

class _DeviceState {
  final BluetoothDeviceConnectionState deviceConnectionState;
  final bool discoveringServices;

  _DeviceState({this.deviceConnectionState, this.discoveringServices});

  _DeviceState clone(
      {bool discoveringServices,
      BluetoothDeviceConnectionState deviceConnectionState}) {
    return _DeviceState(
        deviceConnectionState:
            deviceConnectionState ?? this.deviceConnectionState,
        discoveringServices: discoveringServices ?? this.discoveringServices);
  }

  @override
  String toString() => {
        'state': deviceConnectionState,
        'discoveringServices': discoveringServices
      }.toString();
}

class _DevicePageState extends State<DevicePage> {
  final connectionState = BehaviorSubject<_DeviceState>.seeded(_DeviceState());
  final _deviceServices = BehaviorSubject<List<BleBluetoothService>>();

  // true when initial connection is started
  bool _inited = false;
  BluetoothDeviceConnection connection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device ${widget.deviceId}'),
        actions: <Widget>[
          // overflow menu
          PopupMenuButton<int>(
            onSelected: (choice) {
              switch (choice) {
                case 1:
                  _disconnect();
                  break;
                case 2:
                  _connect();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<int>(
                  value: 1,
                  child: Text('Disconnect'),
                ),
                PopupMenuItem<int>(
                  value: 2,
                  child: Text('Reconnect'),
                )
              ];
            },
          ),
        ],
      ),
      body: Builder(builder: (context) {
        if (!_inited) {
          _inited = true;
          _connect();
        }
        return ListView(
          children: <Widget>[
            StreamBuilder<_DeviceState>(
                stream: connectionState,
                initialData: connectionState.value,
                builder: (context, snapshot) {
                  // devPrint('builder ${snapshot.data}');
                  var stateText = 'Unknown';
                  switch (snapshot?.data?.deviceConnectionState?.state ?? -1) {
                    case bluetoothDeviceConnectionStateConnecting:
                      stateText = 'Connecting';
                      break;
                    case bluetoothDeviceConnectionStateConnected:
                      stateText = 'Connected';
                      break;
                    case bluetoothDeviceConnectionStateDisconnecting:
                      stateText = 'Disconnecting';
                      break;
                    case bluetoothDeviceConnectionStateDisconnected:
                      stateText = 'Disconnected';
                      break;
                  }
                  bool discoveringServices =
                      snapshot?.data?.discoveringServices ?? false;
                  var subtitle;
                  if (discoveringServices) {
                    subtitle = 'Discovering services...';
                  }
                  return ListTile(
                    title: Text(stateText),
                    subtitle: subtitle == null ? null : Text(subtitle),
                  );
                }),
            StreamBuilder<List<BleBluetoothService>>(
                stream: _deviceServices,
                initialData: _deviceServices.value,
                builder: (context, snapshot) {
                  var list = snapshot.data;
                  if (list?.isEmpty ?? true) {
                    return Container();
                  }
                  return Column(
                      children: list
                          .map((service) => ListTile(
                                title: Text('Service'),
                                subtitle:
                                    Text(service.uuid.toString() ?? 'no uuid'),
                                onTap: () {
                                  () async {
                                    await Navigator.of(context).push<String>(
                                        MaterialPageRoute(
                                            builder: (_) => BleServicePage(
                                                appBleService: AppBleService(
                                                    connection: connection,
                                                    bleService: service))));
                                  }();
                                },
                              ))
                          .toList(growable: false));
                })
          ],
        );
      }),
    );
  }

  Future _disconnect() async {
    await connection?.disconnect();
    connection?.close();
    connection = null;
  }

  StreamSubscription stateSubscription;
  Future _connect() async {
    _deviceServices.add(null);
    await _disconnect();
    // Created only once

    connection = await bluetoothManager.newConnection(widget.deviceId);

    stateSubscription?.cancel();
    stateSubscription = connection.onConnectionState.listen((state) {
      // devPrint('got state: $state');
      connectionState
          .add(connectionState.value?.clone(deviceConnectionState: state));
    });
    await connection.connect();
    try {
      connectionState
          .add(connectionState.value?.clone(discoveringServices: true));
      // devPrint('Discovering services');
      await connection.discoverServices();
      // devPrint('getting services');
      var services = await connection.getServices();
      _deviceServices.add(services);
    } catch (e) {
      print(e);
    }
    connectionState
        .add(connectionState.value?.clone(discoveringServices: false));
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    stateSubscription?.cancel();
    connection?.close();
    connectionState.close();
    _deviceServices.close();
    super.dispose();
  }
}
