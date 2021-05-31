// ignore_for_file: implementation_imports
import 'dart:async';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth_server/bluetooth_context.dart';
import 'package:tekartik_bluetooth_server/bluetooth_server.dart';
import 'package:tekartik_bluetooth_server/src/constant.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_web_socket/web_socket.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';

typedef BluetoothServerNotifyCallback = void Function(
    bool response, String method, dynamic params);

/// Web socket server
class BluetoothServer {
  BluetoothServer._(this._webSocketChannelServer, this._notifyCallback) {
    _webSocketChannelServer.stream.listen((WebSocketChannel<String> channel) {
      _channels.add(BluetoothServerChannel(this, channel));
    });
  }

  final BluetoothServerNotifyCallback? _notifyCallback;
  final List<BluetoothServerChannel> _channels = [];
  final WebSocketChannelServer<String> _webSocketChannelServer;

  static Future<BluetoothServer> serve(
      {WebSocketChannelServerFactory? webSocketChannelServerFactory,
      dynamic address,
      int? port,
      BluetoothServerNotifyCallback? notifyCallback}) async {
    webSocketChannelServerFactory ??= webSocketChannelServerFactoryIo;
    var webSocketChannelServer = await webSocketChannelServerFactory
        .serve<String>(address: address, port: port);

    return BluetoothServer._(webSocketChannelServer, notifyCallback);
  }

  Future close() => _webSocketChannelServer.close();

  String get url => _webSocketChannelServer.url;

  int get port => _webSocketChannelServer.port;
}

/// We have one channer per client
class BluetoothServerChannel {
  // Keep TODO close open devices
  // List<int> _openDatabaseIds = [];

  BluetoothServerChannel(this._server, WebSocketChannel<String> channel)
      : _rpcServer = json_rpc.Server(channel) {
    // Specific method for getting server info upon start
    _rpcServer.registerMethod(methodGetServerInfo,
        (json_rpc.Parameters parameters) {
      if (_notifyCallback != null) {
        _notifyCallback!(false, methodGetServerInfo, parameters.value);
      }
      var result = <String, dynamic>{
        keyName: serverInfoName,
        keyVersion: serverInfoVersion.toString(),
      };
      if (_notifyCallback != null) {
        _notifyCallback!(true, methodGetServerInfo, result);
      }
      return result;
    });

    // Generic method
    _rpcServer.registerMethod(methodBluetooth,
        (json_rpc.Parameters parameters) async {
      if (_notifyCallback != null) {
        _notifyCallback!(false, methodBluetooth, parameters.value);
      }

      var map = parameters.value as Map;

      var method = map[keyMethod] as String;
      var param = map[keyParam];

      dynamic result = await (serverBluetoothManager as BluetoothManagerImpl)
          .invokeMethod<dynamic>(method, param);
      if (_notifyCallback != null) {
        _notifyCallback!(true, methodBluetooth, result);
      }

      return result;
    });
    _rpcServer.listen();

    // Cleanup
    // close opened connection
    _rpcServer.done.then((_) async {
      /*
      for (int databaseId in _openDatabaseIds) {
        try {
          await invokeMethod<dynamic>(
              methodCloseDatabase, {paramId: databaseId});
        } catch (e) {
          print('error cleaning up database $databaseId');
        }
      }

       */
      //TODO disconnect all
    });
  }

  final BluetoothServer _server;
  final json_rpc.Server _rpcServer;

  BluetoothServerNotifyCallback? get _notifyCallback => _server._notifyCallback;
}

class BluetoothLocalContext implements BluetoothContext {
  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIOS => Platform.isIOS;
}

BluetoothContext? _bluetoothLocalContext;

BluetoothContext get bluetoothLocalContext =>
    _bluetoothLocalContext ??= BluetoothLocalContext();
