// ignore_for_file: implementation_imports
import 'package:tekartik_bluetooth_server/bluetooth.dart';
import 'package:tekartik_bluetooth_server/src/service.dart';
import 'package:test/test.dart';

/// A context whose native side returns null.
class _NullResultContext implements BluetoothServerContext {
  final methods = <String>[];

  @override
  Future<T> invoke<T>(String method, dynamic param) async {
    methods.add(method);
    return null as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('service', () {
    test('null native result', () async {
      var context = _NullResultContext();
      var service = BluetoothServerService(context);
      await service.enable();
      await service.disable();
      await service.invokeStopScan();
      expect(context.methods, [
        'enableBluetooth',
        'disableBluetooth',
        'stopScan',
      ]);
    });
  });
}
