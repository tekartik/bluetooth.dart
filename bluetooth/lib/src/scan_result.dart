import 'package:tekartik_common_utils/int_utils.dart';
import 'package:tekartik_common_utils/model/model.dart';

import 'bluetooth_device.dart';

abstract class ScanResult {
  BluetoothDevice? get device;
  int? get rssi;
}

class ScanResultImpl implements ScanResult {
  @override
  BluetoothDevice? get device => deviceImpl;

  BluetoothDeviceImpl? deviceImpl;

  @override
  int? rssi;
  void fromMap(Map map) {
    rssi = parseInt(map['rssi']);
    var deviceMap = map['device'];
    if (deviceMap is Map) {
      deviceImpl = BluetoothDeviceImpl()..fromMap(deviceMap);
    }
  }

  Model toDebugMap() {
    var model = Model();
    model.setValue('rssi', rssi);
    model.setValue('device', deviceImpl?.toDebugMap());
    return model;
  }

  @override
  String toString() => toDebugMap().toString();
}
