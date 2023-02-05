import 'package:flutter/services.dart' as flutter;
import 'package:tekartik_bluetooth/bluetooth_peripheral.dart';
import 'package:tekartik_bluetooth/bluetooth_service.dart';
// const MethodChannel methodChannel = MethodChannel('tekartik_bluetooth_flutter');

class MethodCallFlutter implements MethodCall {
  final flutter.MethodCall _native;

  MethodCallFlutter(String method, [dynamic arguments])
      : _native = flutter.MethodCall(method, arguments);

  @override
  dynamic get arguments => _native.arguments;

  @override
  String get method => _native.method;
}

class MethodChannelFlutter implements MethodChannel {
  final flutter.MethodChannel _native;

  MethodChannelFlutter(String name) : _native = flutter.MethodChannel(name);

  @override
  Future invokeMethod(String method, [dynamic arguments]) {
    return _native.invokeMethod(method, arguments);
  }

  @override
  String get name => _native.name;

  @override
  void setMethodCallHandler(Future Function(MethodCall call)? handler) {
    // TODO: implement setMethodCallHandler
  }
}

class EventChannelFlutter implements EventChannel {
  final flutter.EventChannel _native;

  EventChannelFlutter(String name) : _native = flutter.EventChannel(name);

  @override
  String get name => _native.name;

  @override
  Stream<Object?> receiveBroadcastStream() => _native.receiveBroadcastStream();
}

class BluetoothPeripheralFlutterPlugin implements BluetoothPeripheralPlugin {
  @override
  final EventChannel connectionChannel =
      EventChannelFlutter('$bluetoothPluginNamespace/connection');
  @override
  final MethodChannel methodChannel =
      MethodChannelFlutter('tekartik_bluetooth_flutter');
  @override
  final MethodChannel callbackChannel =
      MethodChannelFlutter('$bluetoothPluginNamespace/callback');
  @override
  final EventChannel writeCharacteristicChannel =
      EventChannelFlutter('$bluetoothPluginNamespace/writeCharacteristic');

  BluetoothPeripheralFlutterPlugin._();
}

final BluetoothPeripheralFlutterPlugin bluetoothFlutterPlugin =
    BluetoothPeripheralFlutterPlugin._();
