// ignore_for_file: implementation_imports, depend_on_referenced_packages
import 'package:tekartik_bluetooth/bluetooth.dart';
import 'package:tekartik_bluetooth/src/mixin.dart';
import 'package:tekartik_bluetooth_flutter/src/mixin.dart';
import 'package:tekartik_bluetooth_flutter_blue/bluetooth_flutter.dart';
import 'package:tekartik_bluetooth_server/bluetooth.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_web_socket/web_socket.dart';

/// A [BluetoothManager] whose calls run on another device: a phone running
/// the bluetooth server (`BluetoothServer.serve` of tekartik_bluetooth_server,
/// hosted by the bluetooth_server_app), reached over a web socket.
///
/// Each call is one JSON-RPC request answered by the phone's
/// `serverBluetoothManager`; a remote error comes back as a
/// `BluetoothException`. Only request/response calls work: the server never
/// sends anything on its own, so [scan] results and connection events do not
/// arrive.
///
/// Known limitation: [newConnection] throws `UnimplementedError`.
/// [BluetoothManagerMixin] comes last, so its throwing `newConnection` hides
/// the one of [BluetoothFlutterManagerMixin]. Putting the flutter mixin last
/// would only move the failure to `connect()`, a 30 s timeout waiting for a
/// connection state the server cannot send; both need a server to client
/// message in the server protocol first.
class BluetoothServerFlutterService
    with BluetoothFlutterManagerMixin, BluetoothManagerMixin
    implements BluetoothManager {
  /// A service on an already connected [context]; see [create].
  BluetoothServerFlutterService(this.context);

  /// The connection to the server.
  final BluetoothServerContext context;

  /// Connects to the server at [url] (`ws://localhost:8502` with
  /// `adb forward tcp:8502 tcp:8502` for a phone on USB).
  ///
  /// Returns null, after printing the cause and an `adb forward` hint, when
  /// no server answers. [webSocketChannelClientFactory] defaults to the
  /// `dart:io` web socket client (`webSocketChannelFactoryMemory.client` in
  /// tests).
  static Future<BluetoothServerFlutterService?> create(
    String url, {
    WebSocketChannelClientFactory? webSocketChannelClientFactory,
  }) async {
    var context = await BluetoothServerContext.connect(
      url,
      webSocketChannelClientFactory: webSocketChannelClientFactory,
    );
    if (context != null) {
      return BluetoothServerFlutterService(context);
    }
    return null;
  }

  /// Closes the web socket: the only cleanup, a program or a test that skips
  /// it stays alive.
  @override
  Future close() async {
    await context.close();
  }

  /// Runs [method] on the phone (`serverBluetoothManager.invokeMethod`).
  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) =>
      context.invoke<T>(method, arguments);

  /// The platform of the server (sent in its server info): true for an
  /// Android phone, null with a server that does not send it (built before
  /// 2026-11).
  @override
  bool? get isAndroid => context.isAndroid;

  /// See [isAndroid].
  @override
  bool? get isIOS => context.isIOS;
}
