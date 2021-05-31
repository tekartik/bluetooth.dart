// ignore_for_file: implementation_imports
import 'package:tekartik_bluetooth/bluetooth_manager.dart';
import 'package:tekartik_bluetooth/src/mixin.dart';

//import 'package:tekartik_bluetooth_flutter/src/mixin.dart';
import 'package:tekartik_bluetooth_server/bluetooth.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_web_socket/web_socket.dart';

class BluetoothServerService
    with BluetoothManagerMixin
    implements BluetoothManager {
  BluetoothServerService(this.context);

  final BluetoothServerContext context;

  static Future<BluetoothServerService?> create(String url,
      {WebSocketChannelClientFactory? webSocketChannelClientFactory}) async {
    var context = await BluetoothServerContext.connect(url,
        webSocketChannelClientFactory: webSocketChannelClientFactory);
    if (context != null) {
      return BluetoothServerService(context);
    }
    return null;
  }

  @override
  Future close() async {
    await context.close();
  }

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) async =>
      (await context.invoke<T>(method, arguments))!;

  /*
  @override
  // TODO: implement state
  Future<BluetoothState> get state => null;
  */
  @override
  bool? get isAndroid => context.isAndroid;

  @override
  bool? get isIOS => context.isIOS;
}
