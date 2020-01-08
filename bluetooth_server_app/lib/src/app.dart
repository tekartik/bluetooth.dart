import 'package:tekartik_bluetooth_server/bluetooth_server.dart';
import 'package:tekartik_bluetooth_server_app/src/prefs.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

Version _appVersion = Version(0, 1, 0);

class App {
  bool started = false;
  Prefs prefs;
  BluetoothServer _bluetoothServer;
  BluetoothServer get bluetoothServer => _bluetoothServer;

  bool get bluetoothServerStarted => _bluetoothServer != null;

  Version get version => _appVersion;

  Future<BluetoothServer> startServer(int port,
      {BluetoothServerNotifyCallback notifyCallback}) async {
    await _closeServer();
    _bluetoothServer =
        await BluetoothServer.serve(port: port, notifyCallback: notifyCallback);
    return _bluetoothServer;
  }

  Future stopServer() => _closeServer();

  Future _closeServer() async {
    if (_bluetoothServer != null) {
      var done = _bluetoothServer.close();
      _bluetoothServer = null;
      await done;
    }
  }
}

App _app;
App get app => _app ??= App();

Future clearApp() async {
  //_app = null;
  await app.stopServer();
  var prefs = Prefs();
  await prefs.load();
  app.prefs = prefs;
  app.started = false;
}
