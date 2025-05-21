import 'dart:async';

import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart' as web;
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_web/src/bluetooth_device_connection_web.dart';
import 'package:tekartik_bluetooth_web/src/bluetooth_device_web.dart';
import 'package:tekartik_bluetooth_web/src/scan_result_web.dart';

import 'import_bluetooth.dart';

/// Web request options
class BluetoothRequestDeviceOptionsWeb {
  final bool acceptAllDevices;
  final List<BluetoothRequestDeviceFilterWeb> filters;
  final List<String> optionalServices;

  BluetoothRequestDeviceOptionsWeb({
    required this.acceptAllDevices,
    this.filters = const <BluetoothRequestDeviceFilterWeb>[],

    /// Valid for both acceptAllDevices and filters
    this.optionalServices = const <String>[],
  });
}

class BluetoothRequestDeviceFilterWeb {
  final String? name;
  final String? namePrefix;
  final List<String>? services;

  BluetoothRequestDeviceFilterWeb({this.name, this.namePrefix, this.services});
}

/// Web specific interface
abstract class BluetoothManagerWeb extends BluetoothManager
    implements BluetoothAdminManager {
  Future<BluetoothDevice> webRequestDevice([
    BluetoothRequestDeviceOptionsWeb? options,
  ]);
}

bool debugBluetoothManagerWeb = false;

class BluetoothManagerWebImpl
    with BluetoothManagerMixin, BluetoothAdminManagerMixin
    implements BluetoothManagerWeb {
  void _addNativeDevice(web.BluetoothDevice nativeDevice) {
    nativeDeviceMap[nativeDevice.id] = nativeDevice;
  }

  /// Key if the id
  final nativeDeviceMap = <String, web.BluetoothDevice>{};
  StreamSubscription? _scanWebSubscription;

  /// Web specific API
  @override
  Future<BluetoothDevice> webRequestDevice([
    BluetoothRequestDeviceOptionsWeb? options,
  ]) async {
    options ??= BluetoothRequestDeviceOptionsWeb(acceptAllDevices: true);
    var nativeDevice = await web.FlutterWebBluetooth.instance.requestDevice(
      options.acceptAllDevices
          ? web.RequestOptionsBuilder.acceptAllDevices(
            optionalServices: options.optionalServices,
          )
          : web.RequestOptionsBuilder(
            options.filters
                .map(
                  (e) => web.RequestFilterBuilder(
                    name: e.name,
                    namePrefix: e.namePrefix,
                    services: e.services,
                  ),
                )
                .toList(),
            optionalServices: options.optionalServices,
          ),
    );
    _addNativeDevice(nativeDevice);
    return BluetoothDeviceWeb(nativeDevice);
  }

  /// Set upon start

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) {
    throw UnimplementedError();
  }

  @override
  Future<BluetoothInfo> getInfo() async {
    var apiSupported = web.FlutterWebBluetooth.instance.isBluetoothApiSupported;
    return BluetoothInfoImpl(
      hasBluetooth: apiSupported,
      hasBluetoothBle: apiSupported,
      isBluetoothEnabled: apiSupported,
    );
  }

  @override
  Future<BluetoothAdminInfo> getAdminInfo() async {
    var apiSupported = web.FlutterWebBluetooth.instance.isBluetoothApiSupported;
    return BluetoothAdminInfoImpl(
      hasBluetooth: apiSupported,
      hasBluetoothBle: apiSupported,
      isBluetoothEnabled: apiSupported,
    );
  }

  @override
  // TODO: implement isAndroid
  bool? get isAndroid => false;

  @override
  // TODO: implement isIOS
  bool? get isIOS => false;

  @override
  Stream<ScanResult> scan({
    ScanMode scanMode = ScanMode.lowLatency,
    List<Uuid128>? withServices,
  }) {
    scanController?.close();

    scanController = StreamController<ScanResult>(
      onCancel: () {
        _scanWebSubscription?.cancel();

        scanController?.close();
      },
      onListen: () async {
        _scanWebSubscription = web.FlutterWebBluetooth.instance.devices.listen((
          data,
        ) {
          for (var nativeDevice in data) {
            _addNativeDevice(nativeDevice);
            scanController?.add(
              ScanResultWeb(BluetoothDeviceWeb(nativeDevice)),
            );
          }
        });
      },
    );

    return scanController!.stream;
  }

  // static int _connectionId = 0;
  @override
  Future<BluetoothDeviceConnection> newConnection(
    BluetoothDeviceId deviceId,
  ) async {
    var nativeDevice = nativeDeviceMap[deviceId.id];
    if (nativeDevice == null) {
      throw StateError('device id $deviceId not found');
    }
    return BluetoothDeviceConnectionWeb(nativeDevice);
  }
}

/// Internal implementation
final BluetoothManagerWebImpl bluetoothManagerWebImpl =
    BluetoothManagerWebImpl();

/// Linux only
BluetoothManagerWeb get bluetoothManagerWeb => bluetoothManagerWebImpl;
