import 'dart:async';
import 'dart:io';

import 'package:flutter_blue/flutter_blue.dart' as native;
import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';

// ignore: implementation_imports
import 'package:tekartik_bluetooth/src/options.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

import 'bluetooth_device_flutter_blue.dart';

class ScanResultFlutter implements ScanResult {
  final native.ScanResult nativeImpl;
  BluetoothDeviceFlutterBlue _device;

  ScanResultFlutter(this.nativeImpl);

  @override
  BluetoothDevice get device =>
      _device ??= BluetoothDeviceFlutterBlue(nativeImpl.device);

  @override
  int get rssi => nativeImpl.rssi;

  @override
  String toString() => nativeImpl.toString();
}

class BluetoothManagerFlutterBlue implements BluetoothManager {
  @override
  Future<bool> checkCoarseLocationPermission({int androidRequestCode}) {
    throw UnimplementedError();
  }

  @override
  Future<void> close() {
    throw UnimplementedError();
  }

  @override
  // ignore: deprecated_member_use
  Future<void> devSetOptions(BluetoothOptions options) {
    throw UnimplementedError();
  }

  @override
  Future disable() {
    throw UnimplementedError();
  }

  @override
  Future enable({int requestCode, int androidRequestCode}) {
    throw UnimplementedError();
  }

  @override
  Future<List<BluetoothDevice>> getConnectedDevices() async {
    var devices = await native.FlutterBlue.instance.connectedDevices;
    return devices.map((native) => BluetoothDeviceFlutterBlue(native)).toList();
  }

  @override
  Future<BluetoothInfo> getInfo() {
    throw UnimplementedError();
  }

  @override
  Future init() {
    throw UnimplementedError();
  }

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIOS => Platform.isIOS;

  @override
  Future<BluetoothDeviceConnection> newConnection(String deviceId) {
    // TODO: implement newConnection
    throw UnimplementedError();
  }

  StreamSubscription scannerSubscription;

  @override
  Stream<ScanResult> scan({ScanMode scanMode = ScanMode.lowLatency}) {
    scannerSubscription?.cancel();
    scannerSubscription = null;
    StreamController<ScanResult> ctlr;
    ctlr = StreamController<ScanResult>(onListen: () {
      scannerSubscription ??=
          native.FlutterBlue.instance.scan().listen((event) {
        ctlr.add(ScanResultFlutter(event));
      });
    }, onCancel: () {
      native.FlutterBlue.instance.stopScan();
      scannerSubscription?.cancel();
      ctlr?.close();
    });
    return ctlr.stream;
  }

  @override
  Future stop() async {
    await native.FlutterBlue.instance.stopScan();
    /*
    unawaited(scannerSubscription?.cancel());
    scannerSubscription = null;

     */
  }

  @override
  // TODO: implement supportsEnable
  bool get supportsEnable => throw UnimplementedError();
}

final bluetoothManagerFlutterBlue = BluetoothManagerFlutterBlue();
