import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth_device.dart';
import 'package:tekartik_bluetooth/uuid.dart';
import 'package:tekartik_bluetooth_flutter/bluetooth_manager.dart';

const _channelName = 'tekartik_bluetooth_flutter';
const _channel = MethodChannel(_channelName);
const _codec = StandardMethodCodec();

/// The calls sent to the native side.
final _calls = <MethodCall>[];

/// Answers of the fake native side, by method.
final _answers = <String, Object? Function(MethodCall call)>{};

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// A call from the native side to Dart (what `channel.invokeMethod` does in
/// the Android plugin).
Future<void> _nativeInvoke(String method, Object? arguments) async {
  await _messenger.handlePlatformMessage(
    _channelName,
    _codec.encodeMethodCall(MethodCall(method, arguments)),
    (_) {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _calls.clear();
    _answers.clear();
    _messenger.setMockMethodCallHandler(_channel, (call) async {
      _calls.add(call);
      return _answers[call.method]?.call(call);
    });
  });
  tearDown(() {
    _messenger.setMockMethodCallHandler(_channel, null);
  });

  test('scan receives the native scan results', () async {
    var manager = bluetoothManagerFlutter;
    var first = manager.scan().first;
    // Let the startScan call go.
    await pumpEventQueue();
    expect(_calls.map((call) => call.method), contains('startScan'));
    await _nativeInvoke('scanResult', {
      'rssi': -42,
      'device': {'address': '00:11:22:33:44:55', 'name': 'my device'},
    });
    var result = await first.timeout(const Duration(seconds: 2));
    expect(result.rssi, -42);
    expect(result.device.address, '00:11:22:33:44:55');
    expect(result.device.name, 'my device');
  });

  group('connection', () {
    var connectionId = 0;
    setUp(() {
      _answers['remoteNewConnection'] = (_) => ++connectionId;
    });

    test('connect completes on the native connected state', () async {
      var connection = await bluetoothManagerFlutter.newConnection(
        BluetoothDeviceId('00:11:22:33:44:55'),
      );
      var id = connectionId;
      var connected = connection.connect();
      await pumpEventQueue();
      expect(_calls.map((call) => call.method), contains('remoteConnect'));
      await _nativeInvoke('remoteConnectionState', {
        'connectionId': id,
        'state': bluetoothDeviceConnectionStateConnected,
      });
      await connected.timeout(const Duration(seconds: 2));
      connection.close();
    });

    test('discoverServices completes on the native result', () async {
      var connection = await bluetoothManagerFlutter.newConnection(
        BluetoothDeviceId('00:11:22:33:44:55'),
      );
      var id = connectionId;
      var discovered = connection.discoverServices();
      await pumpEventQueue();
      expect(
        _calls.map((call) => call.method),
        contains('remoteDiscoverServices'),
      );
      await _nativeInvoke('remoteDiscoverServicesResult', {'connectionId': id});
      await discovered.timeout(const Duration(seconds: 2));
      connection.close();
    });

    test('read a characteristic given with upper case uuids', () async {
      var connection = await bluetoothManagerFlutter.newConnection(
        BluetoothDeviceId('00:11:22:33:44:55'),
      );
      var id = connectionId;
      // Android returns lower case uuids (java.util.UUID.toString()).
      _answers['remoteReadCharacteristic'] = (call) {
        var arguments = call.arguments as Map;
        () async {
          await pumpEventQueue();
          await _nativeInvoke('remoteReadCharacteristicResult', {
            'connectionId': id,
            'service': (arguments['service'] as String).toLowerCase(),
            'characteristic': (arguments['characteristic'] as String)
                .toLowerCase(),
            'status': 0,
            'value': Uint8List.fromList([1, 2, 3]),
          });
        }();
        return null;
      };
      // Nordic UART, as written in its documentation.
      var service = BleBluetoothService(
        uuid: Uuid128('6E400001-B5A3-F393-E0A9-E50E24DCCA9E'),
      );
      var characteristic = BleBluetoothCharacteristic(
        service: service,
        uuid: Uuid128('6E400003-B5A3-F393-E0A9-E50E24DCCA9E'),
      );
      var value = await connection
          .readCharacteristic(characteristic)
          .timeout(const Duration(seconds: 2));
      expect(value.value, [1, 2, 3]);
      connection.close();
    });
  });
}
