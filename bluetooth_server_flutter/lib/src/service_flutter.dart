// ignore_for_file: implementation_imports
import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth/src/mixin.dart';
import 'package:tekartik_bluetooth_flutter/src/mixin.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_server/bluetooth.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_web_socket/web_socket.dart';

class BluetoothServerFlutterService
    with BluetoothFlutterManagerMixin, BluetoothManagerMixin
    implements BluetoothManager {
  BluetoothServerFlutterService(this.context);

  final BluetoothServerContext context;

  static Future<BluetoothServerFlutterService?> create(String url,
      {WebSocketChannelClientFactory? webSocketChannelClientFactory}) async {
    var context = await BluetoothServerContext.connect(url,
        webSocketChannelClientFactory: webSocketChannelClientFactory);
    if (context != null) {
      return BluetoothServerFlutterService(context);
    }
    return null;
  }

  @override
  Future close() async {
    await context.close();
  }

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) =>
      context.invoke<T>(method, arguments);

  @override
  bool? get isAndroid => context.isAndroid;

  @override
  bool? get isIOS => context.isIOS;
}
