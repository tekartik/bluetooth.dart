/// Platform of the device hosting the radio.
library;

abstract class BluetoothContext {
  bool? get isAndroid;

  bool? get isIOS;
}
