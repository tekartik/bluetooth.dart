import 'package:cv/cv.dart';
import 'package:tekartik_common_utils/bool_utils.dart';

abstract class BluetoothInfo {
  bool? get hasBluetooth;

  bool? get hasBluetoothBle;

  bool? get isBluetoothEnabled;

  /// To handle Hot restart
  bool? get isScanning;
}

abstract class BluetoothAdminInfo {
  bool? get hasBluetooth;

  bool? get hasBluetoothBle;

  bool? get isBluetoothEnabled;
}

class BluetoothInfoImpl implements BluetoothInfo {
  @override
  bool? hasBluetooth;

  @override
  bool? hasBluetoothBle;

  @override
  bool? isBluetoothEnabled;

  @override
  bool? isScanning;

  BluetoothInfoImpl(
      {this.hasBluetooth,
      this.hasBluetoothBle,
      this.isBluetoothEnabled,
      this.isScanning});

  void fromMap(Map result) {
    var model = asModel(result);
    hasBluetooth = parseBool(model['hasBluetooth']) ?? false;
    hasBluetoothBle = parseBool(model['hasBluetoothBle']) ?? false;
    isBluetoothEnabled = parseBool(model['isBluetoothEnabled']) ?? false;
    isScanning = parseBool(model['isScanning']) ?? false;
  }

  @override
  String toString() => toDebugMap().toString();

  Model toDebugMap() {
    var model = newModel()
      ..setValue('hasBluetooth', hasBluetooth)
      ..setValue('hasBluetoothBle', hasBluetoothBle)
      ..setValue('isBluetoothEnabled', isBluetoothEnabled)
      ..setValue('isScanning', isScanning);
    return model;
  }
}

class BluetoothAdminInfoImpl implements BluetoothAdminInfo {
  @override
  bool? hasBluetooth;

  @override
  bool? hasBluetoothBle;

  @override
  bool? isBluetoothEnabled;

  BluetoothAdminInfoImpl(
      {this.hasBluetooth, this.hasBluetoothBle, this.isBluetoothEnabled});

  void fromMap(Map result) {
    var model = asModel(result);
    hasBluetooth = parseBool(model['hasBluetooth']) ?? false;
    hasBluetoothBle = parseBool(model['hasBluetoothBle']) ?? false;
    isBluetoothEnabled = parseBool(model['isBluetoothEnabled']) ?? false;
  }

  @override
  String toString() => toDebugMap().toString();

  Model toDebugMap() {
    var model = newModel()
      ..setValue('hasBluetooth', hasBluetooth)
      ..setValue('hasBluetoothBle', hasBluetoothBle)
      ..setValue('isBluetoothEnabled', isBluetoothEnabled);
    return model;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(Object other) {
    if (other is BluetoothAdminInfoImpl) {
      if (other.hasBluetooth != hasBluetooth) {
        return false;
      }
      if (other.hasBluetoothBle != hasBluetoothBle) {
        return false;
      }
      if (other.isBluetoothEnabled != isBluetoothEnabled) {
        return false;
      }
      return true;
    }
    return false;
  }
}
