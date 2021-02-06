import 'package:tekartik_bluetooth/src/mock/battery_device_mock.dart';
import 'package:test/test.dart';

void main() {
  group('Mock', () {
    //BluetoothStateService bluetoothService;

    setUp(() {});

    test('advertise', () async {
      var remoteMock = BatteryRemoteDeviceMock();
      await remoteMock.start();
      await remoteMock.stop();
    });
  });
}
