// ignore_for_file: implementation_imports
import 'dart:typed_data';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:tekartik_bluetooth/src/exception.dart';
import 'package:tekartik_bluetooth_server/src/constant.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';

import 'import.dart';

class ServerInfo {
  bool? isIOS;
  bool? isAndroid;
}

/// Instance of a server
class BluetoothServerClient {
  BluetoothServerClient._(this._client, this.serverInfo);

  final json_rpc.Client _client;
  final ServerInfo serverInfo;

  static Future<BluetoothServerClient> connect(
    String url, {
    WebSocketChannelClientFactory? webSocketChannelClientFactory,
  }) async {
    webSocketChannelClientFactory ??= webSocketChannelClientFactoryIo;
    var webSocketChannel = webSocketChannelClientFactory.connect<String>(url);
    var rpcClient = json_rpc.Client(webSocketChannel);
    ServerInfo serverInfo;
    unawaited(rpcClient.listen());
    try {
      var serverInfoMap =
          await rpcClient.sendRequest(methodGetServerInfo) as Map;
      if (serverInfoMap[keyName] != serverInfoName) {
        throw 'invalid name in $serverInfoMap';
      }
      var version = Version.parse(serverInfoMap[keyVersion] as String);
      if (version < serverInfoMinVersion) {
        throw 'Bluetooth server version $version not supported, >=$serverInfoMinVersion expected';
      }
      serverInfo = ServerInfo()
        ..isIOS = parseBool(serverInfoMap[keyIsIOS])
        ..isAndroid = parseBool(serverInfoMap[keyIsAndroid]);
    } catch (e) {
      await rpcClient.close();
      rethrow;
    }
    return BluetoothServerClient._(rpcClient, serverInfo);
  }

  Future<T> sendRequest<T>(String method, dynamic param) async {
    T t;
    try {
      t = await _client.sendRequest(method, param) as T;
    } on json_rpc.RpcException catch (e) {
      // devPrint('ERROR ${e.runtimeType} $e ${e.message} ${e.data}');
      throw BluetoothException(e.message, e.data);
    }
    return t;
  }

  static void fixResult<T>(T result) {
    bool shouldFix(dynamic value) {
      return value is List && (value is! Uint8List);
    }

    Uint8List fix(dynamic value) {
      var list = <int?>[];
      for (var item in value) {
        list.add(parseInt(item));
      }
      // devPrint('fix: $value ${value.runtimeType}');
      return Uint8List.fromList(list as List<int>);
    }

    // devPrint('result1: $result');
    // Convert List to Uint8List
    if (result is List) {
      for (var item in result) {
        if (item is Map) {
          var changed = <String, dynamic>{};
          var map = item.cast<String, dynamic>();
          map.forEach((String key, dynamic value) {
            if (shouldFix(value)) {
              changed[key] = fix(value);
            }
          });
          map.addAll(changed);
        }
      }
    } else if (result is Map) {
      // print(result);
      dynamic rawRows = result['rows'];
      if (rawRows is List) {
        var rows = rawRows.cast<List>();
        for (var row in rows) {
          for (var i = 0; i < row.length; i++) {
            dynamic value = row[i];
            if (shouldFix(value)) {
              row[i] = fix(value);
            }
          }
        }
      }
      //col
      //for (var column )
    }
    // devPrint('result2: $result');
  }

  Future<T> invoke<T>(String method, dynamic param) async {
    var map = <String, dynamic>{keyMethod: method, keyParam: param};
    var result = await sendRequest<T>(methodBluetooth, map);

    fixResult(result);

    return result;
  }

  Future close() => _client.close();
}
