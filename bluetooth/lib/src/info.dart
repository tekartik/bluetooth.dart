import 'package:tekartik_common_utils/bool_utils.dart';
import 'package:tekartik_common_utils/model/model.dart';

abstract class BluetoothInfo {
  bool get hasBluetooth;

  bool get hasBluetoothBle;

  bool get isBluetoothEnabled;

  /// To handle Hot restart
  bool get isScanning;
}

class BluetoothInfoImpl implements BluetoothInfo {
  @override
  bool hasBluetooth;

  @override
  bool hasBluetoothBle;

  @override
  bool isBluetoothEnabled;

  @override
  bool isScanning;

  BluetoothInfoImpl(
      {this.hasBluetooth, this.hasBluetoothBle, this.isBluetoothEnabled});

  void fromMap(Map result) {
    var model = Model(result);
    hasBluetooth = parseBool(model['hasBluetooth']) ?? false;
    hasBluetoothBle = parseBool(model['hasBluetoothBle']) ?? false;
    isBluetoothEnabled = parseBool(model['isBluetoothEnabled']) ?? false;
    isScanning = parseBool(model['isScanning']) ?? false;
  }

  @override
  String toString() => toDebugMap().toString();
  Model toDebugMap() {
    var model = Model()
      ..setValue('hasBluetooth', hasBluetooth)
      ..setValue('hasBluetoothBle', hasBluetoothBle)
      ..setValue('isBluetoothEnabled', isBluetoothEnabled)
      ..setValue('isScanning', isScanning);
    return model;
  }
}
