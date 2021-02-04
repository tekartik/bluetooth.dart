import 'dart:async';

import 'package:tekartik_bluetooth/bluetooth_manager.dart';
import 'package:tekartik_bluetooth_server/bluetooth_context.dart';
import 'package:tekartik_bluetooth_server/src/bluetooth_server_client.dart';
import 'package:tekartik_bluetooth_server/src/common_public.dart';
import 'package:tekartik_bluetooth_server/src/service.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_web_socket/web_socket.dart';

const bluetoothServerUrlEnvKey = 'TEKARTIK_BLUETOOTH_SERVER_URL';
const bluetoothServerPortEnvKey = 'TEKARTIK_BLUETOOTH_SERVER_PORT';

int parseBluetoothServerUrlPort(String url, {int defaultValue}) {
  var port = parseInt(url.split('\:').last);
  return port ?? defaultValue;
}

final bluetoothServerDefaultUrl = getBluetoothServerUrl();

Future<BluetoothManager> initBluetoothClientService() async {
  BluetoothManager service;
  var envUrl = const String.fromEnvironment(bluetoothServerUrlEnvKey);
  var envPort =
      parseInt(const String.fromEnvironment(bluetoothServerPortEnvKey));

  var url = envUrl;
  url ??= getBluetoothServerUrl(port: envPort);

  try {
    service = await BluetoothServerService.create(url);
  } catch (e) {
    print(e);
  }
  if (service == null) {
    print('''
bluetooth server not running on $url
Check that the blueooth_server_app is running on the proper port
Android: 
  check that you have forwarded tcp ip on Android
  \$ adb forward tcp:8501 tcp:8501

url/port can be overriden using env variables
$bluetoothServerUrlEnvKey: ${envUrl ?? ''}
$bluetoothServerPortEnvKey: ${envPort ?? ''}

''');
  }
  return service;
}

class BluetoothServerContext implements BluetoothContext {
  BluetoothServerClient _client;

  BluetoothServerClient get client => _client;

  Future<T> sendRequest<T>(String method, dynamic param) async {
    return await _client.sendRequest<T>(method, param);
  }

  Future<T> invoke<T>(String method, dynamic param) async {
    //var map = <String, dynamic>{keyMethod: method, keyParam: param};
    var result = await _client.invoke<T>(method, param);
    return result;
  }

  Future<BluetoothServerClient> connectClient(String url,
      {WebSocketChannelClientFactory webSocketChannelClientFactory}) async {
    BluetoothServerClient client;
    try {
      client = await BluetoothServerClient.connect(url,
          webSocketChannelClientFactory: webSocketChannelClientFactory);
      if (client != null) {
        _client = client;
      }
      return client;
    } catch (e) {
      print(e);
    }
    return null;
  }

  //BluetoothServerFlutterService get service => _service;

  static Future<BluetoothServerContext> connect(String url,
      {WebSocketChannelClientFactory webSocketChannelClientFactory}) async {
    var context = BluetoothServerContext();
    var client = await (context.connectClient(url,
        webSocketChannelClientFactory: webSocketChannelClientFactory));
    if (client == null) {
      var port = parseBluetoothServerUrlPort(url);
      print('''
bluetooth server not running on $url
Check that the bluetooth_server_app is running on the proper port
Android: 
  check that you have forwarded tcp ip on Android
  \$ adb forward tcp:$port tcp:$port

''');
    } else {
      return context;
    }
    return null;
  }

  Future close() async {
    await _client?.close();
    _client = null;
  }

  @override
  bool get isAndroid => client.serverInfo.isAndroid;

  @override
  bool get isIOS => client.serverInfo.isIOS;
}

BluetoothServerContext _bluetoothServerContext;

BluetoothServerContext get bluetoothServerContext =>
    _bluetoothServerContext ??= BluetoothServerContext();
