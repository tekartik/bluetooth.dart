import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';

BluetoothStateService? _bluetoothStateService;
final _lock = Lock();

Future<BluetoothStateService?> getBluetoothStateService() async {
  if (_bluetoothStateService == null) {
    BluetoothStateService bluetoothStateService;
    var deviceInfo = await getDeviceInfo();
    if (deviceInfo.isPhysicalDevice) {
      bluetoothStateService = bluetoothManagerFlutter;
    } else {
      bluetoothStateService = BluetoothStateServiceMock();
    }
    if (_bluetoothStateService == null) {
      _bluetoothStateService = bluetoothStateService;
    }
  }
  return _bluetoothStateService;
}

class DeviceInfo {
  bool get isAndroid => android != null;

  bool get isIOS => android != null;
  AndroidDeviceInfo? android;
  IosDeviceInfo? ios;

  bool get isPhysicalDevice =>
      (android?.isPhysicalDevice ?? ios?.isPhysicalDevice) == true;
}

DeviceInfo? _deviceInfo;

Future<DeviceInfo> getDeviceInfo() async {
  if (_deviceInfo != null) {
    return _deviceInfo!;
  } else {
    return _lock.synchronized(() async {
      if (_deviceInfo == null) {
        DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
        DeviceInfo deviceInfo = DeviceInfo();
        if (Platform.isAndroid) {
          deviceInfo.android = await deviceInfoPlugin.androidInfo;
        } else if (Platform.isIOS) {
          deviceInfo.ios = await deviceInfoPlugin.iosInfo;
        }
        _deviceInfo = deviceInfo;
      }
      return _deviceInfo!;
    });
  }
}

enum RssiStrength { great, ok, bad, unusable }

// https://www.metageek.com/training/resources/understanding-rssi.html
// Signal Strength	TL;DR	 	Required for
// -30 dBm	Amazing	Max achievable signal strength. The client can only be a few feet from the AP to achieve this. Not typical or desirable in the real world.	N/A
// -67 dBm	Very Good	Minimum signal strength for applications that require very reliable, timely delivery of data packets.	VoIP/VoWiFi, streaming video
// -70 dBm	Okay	Minimum signal strength for reliable packet delivery.	Email, web
// -80 dBm	Not Good	Minimum signal strength for basic connectivity. Packet delivery may be unreliable.	N/A
// -90 dBm	Unusable	Approaching or drowning in the noise floor. Any functionality is highly unlikely.
RssiStrength getIconDataFromRssi(int rssi) {
  if (rssi >= -67) {
    return RssiStrength.great;
  } else if (rssi >= -70) {
    return RssiStrength.ok;
  } else if (rssi >= -80) {
    return RssiStrength.bad;
  } else
    return RssiStrength.unusable;
}

class BluetoothStateServiceMock implements BluetoothStateService {
  @override
  Future disable() async {}

  @override
  bool get supportsEnable => false;

  @override
  Future enable({int? requestCode, int? androidRequestCode}) async {}
}
