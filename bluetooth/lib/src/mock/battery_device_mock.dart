import 'package:tekartik_bluetooth/ble.dart';
import 'package:tekartik_bluetooth/src/mock/peripheral_mock.dart';
import 'package:tekartik_bluetooth/src/rx_utils.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

import 'battery_device.dart';

class CharacteristicMock {
  // Stale value
  BleBluetoothCharacteristicValue bcv;

  // For notification
  final _subject = BehaviorSubjectWrapper<BleBluetoothCharacteristicValue>();

  SubjectInterface<BleBluetoothCharacteristicValue> get subject => _subject;

  void dispose() {
    unawaited(_subject.close());
  }
}

class BatteryRemoteDeviceMock extends BatteryRemoteDevice {
  BatteryRemoteDeviceMock() : super() {
    bluetoothPeripheral ??=
        BluetoothPeripheralMock(deviceName: 'Battery', services: gattServices);
  }

  //static var deviceId = const DeviceIdentifier('noveo_lumi_android');

  /*
  @override
  Future init(Prefs prefs) async {
    /// An id is generate and saved in prefs
    // var deviceIdText =
    initId(prefs);

    await initValues(prefs);
  }
  */

  final characteristicValueMap =
      <BleBluetoothCharacteristic, CharacteristicMock>{};

  @override
  Future setCharacteristicValue(BleBluetoothCharacteristicValue bcv) async {
    // no check on whether it exists or not
    var mock = characteristicValueMap[bcv.bc] ??= CharacteristicMock();
    mock.bcv = bcv;
  }

  @override
  Future<BleBluetoothCharacteristicValue> getCharacteristicValue(
      BleBluetoothCharacteristic bc) async {
    var mock = characteristicValueMap[bc];
    return mock?.bcv;
  }

  @override
  Future notifyCharacteristicValue(BleBluetoothCharacteristicValue bcv) async {
    // ? nothing here it will read directly bleNotification
    //var mock = characteristicValueMap[bcv.bc] ??= CharacteristicMock();
    // mock.subject.sink.add(bcv);
  }
}
