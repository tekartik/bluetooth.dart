import 'package:tekartik_bluetooth/bluetooth_state_service.dart';
import 'package:test/test.dart';

void main() {
  group('BluetoothStateService', () {
    BluetoothStateService bluetoothService;

    setUp(() {});

    test('null', () {
      expect(bluetoothService, isNull);
    });
  });
}
