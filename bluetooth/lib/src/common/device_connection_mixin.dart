import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/bluetooth.dart';

mixin BluetoothDeviceConnectionMixin implements BluetoothDeviceConnection {
  @override
  Stream<BleBluetoothCharacteristicValue> onCharacteristicValueChanged(
          BleBluetoothCharacteristic characteristic) =>
      throw UnimplementedError('onCharacteristicValueChanged');

  @override
  Future<void> registerCharacteristic(
      BleBluetoothCharacteristic characteristic, bool on) {
    throw UnimplementedError('registerCharacteristic');
  }
}
