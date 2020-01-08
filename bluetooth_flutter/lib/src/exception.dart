/// Generic Bluetooth Exception
class BluetoothException implements Exception {
  BluetoothException(this.message, this.result);

  final String message;
  final dynamic result;

  @override
  String toString() =>
      'BluetoothException($message${result == null ? '' : ' $result'})';
}
