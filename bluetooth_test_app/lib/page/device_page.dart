// ignore_for_file: avoid_print, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tekartik_bluetooth_test_app/ble/app_ble.dart';
import 'package:tekartik_bluetooth_test_app/import/common_import.dart';
import 'package:tekartik_bluetooth_test_app/import/import_bluetooth.dart';
import 'package:tekartik_bluetooth_test_app/page/ble_service_page.dart';

class DevicePage extends StatefulWidget {
  final BluetoothDeviceId deviceId;

  const DevicePage({super.key, required this.deviceId});

  @override
  // ignore: library_private_types_in_public_api
  _DevicePageState createState() => _DevicePageState();
}

class _DeviceState {
  final BluetoothDeviceConnectionState? deviceConnectionState;
  final bool? discoveringServices;

  _DeviceState({this.deviceConnectionState, this.discoveringServices});

  _DeviceState clone({
    bool? discoveringServices,
    BluetoothDeviceConnectionState? deviceConnectionState,
  }) {
    return _DeviceState(
      deviceConnectionState:
          deviceConnectionState ?? this.deviceConnectionState,
      discoveringServices: discoveringServices ?? this.discoveringServices,
    );
  }

  @override
  String toString() =>
      {
        'state': deviceConnectionState,
        'discoveringServices': discoveringServices,
      }.toString();
}

class _DevicePageState extends State<DevicePage> {
  final connectionState = BehaviorSubject<_DeviceState?>.seeded(_DeviceState());
  final _deviceServices = BehaviorSubject<List<BleBluetoothService>?>();

  // true when initial connection is started
  bool _inited = false;
  BluetoothDeviceConnection? connection;

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
                const PopupMenuItem<int>(value: 1, child: Text('Disconnect')),
                const PopupMenuItem<int>(value: 2, child: Text('Reconnect')),
              ];
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (!_inited) {
            _inited = true;
            _connect();
          }
          return ListView(
            children: <Widget>[
              StreamBuilder<_DeviceState?>(
                stream: connectionState,
                initialData: connectionState.value,
                builder: (context, snapshot) {
                  // devPrint('builder ${snapshot.data}');
                  var stateText = 'Unknown';
                  switch (snapshot.data?.deviceConnectionState?.state ?? -1) {
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
                  var discoveringServices =
                      snapshot.data?.discoveringServices ?? false;
                  String? subtitle;
                  if (discoveringServices) {
                    subtitle = 'Discovering services...';
                  }
                  return ListTile(
                    title: Text(stateText),
                    subtitle: subtitle == null ? null : Text(subtitle),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        _refreshServices();
                      },
                    ),
                  );
                },
              ),
              StreamBuilder<List<BleBluetoothService>?>(
                stream: _deviceServices,
                initialData: _deviceServices.value,
                builder: (context, snapshot) {
                  var list = snapshot.data;
                  if (list?.isEmpty ?? true) {
                    return Container();
                  }
                  return Column(
                    children: list!
                        .map(
                          (service) => ListTile(
                            title: const Text('Service'),
                            subtitle: Text(service.uuid.toString()),
                            onTap: () {
                              () async {
                                await Navigator.of(context).push<String>(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => BleServicePage(
                                          appBleService: AppBleService(
                                            connection: connection,
                                            bleService: service,
                                          ),
                                        ),
                                  ),
                                );
                              }();
                            },
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  var disconnectForExit = false;
  Future _disconnect() async {
    if (connection != null) {
      // ignore: avoid_print
      print('Disconnecting');
      await connection?.disconnect();
      connection?.close();
      connection = null;
      print('Disconnected');
    }
  }

  StreamSubscription? stateSubscription;

  Future _refreshServices() async {
    _deviceServices.add(null);
    try {
      connectionState.add(
        connectionState.value?.clone(discoveringServices: true),
      );
      print('Discovering services');
      await connection!.discoverServices();
      // devPrint('getting services');
      var services = await connection!.getServices();
      // Dump services
      for (var service in services) {
        print('Service uuid ${service.uuid}');
        for (var characteristic in service.characteristics) {
          print('  Characteristic ${characteristic.uuid}');
          print('            prop ${characteristic.properties}');
          print('            flags ${characteristic.propertyFlags}');
          for (var descriptor in characteristic.descriptors) {
            print('    Descriptor ${descriptor.uuid}');
          }
        }
      }
      // devPrint('services: $services');
      _deviceServices.add(services);
    } catch (e) {
      print(e);
    }
    connectionState.add(
      connectionState.value?.clone(discoveringServices: false),
    );
  }

  Future _connect() async {
    _deviceServices.add(null);

    await _disconnect();
    // Created only once
    print('Connecting');
    connection = await deviceBluetoothManager.newConnection(widget.deviceId);

    stateSubscription?.cancel().unawait();
    stateSubscription = connection!.onConnectionState.listen((state) {
      print('onConnectionState: $state');
      connectionState.add(
        connectionState.value?.clone(deviceConnectionState: state),
      );
    });
    try {
      await connection!.connect();
      await _refreshServices();
    } catch (e) {
      if (disconnectForExit) {
        // nothing
      } else {}
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    disconnectForExit = true;
    _disconnect();
    stateSubscription?.cancel();
    connection?.close();
    connectionState.close();
    _deviceServices.close();
    super.dispose();
  }
}
