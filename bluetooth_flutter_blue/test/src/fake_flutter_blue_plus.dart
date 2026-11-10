import 'dart:async';

import 'package:flutter_blue_plus_platform_interface/flutter_blue_plus_platform_interface.dart';

/// The id of the device advertised by the scan number [scan] (1 based).
String fakeScanDeviceId(int scan) =>
    '00:11:22:33:44:${scan.toString().padLeft(2, '0')}';

/// A flutter_blue_plus platform answering each scan with one advertisement
/// ([fakeScanDeviceId]) 20 ms after it started.
final class FakeFlutterBluePlusPlatform extends FlutterBluePlusPlatform {
  final _scanResponses = StreamController<BmScanResponse>.broadcast();

  /// The number of scans started.
  var startScanCount = 0;

  /// Thrown by the next start of a scan.
  Object? startScanError;

  @override
  Stream<BmScanResponse> get onScanResponse => _scanResponses.stream;

  @override
  Future<bool> startScan(BmScanSettings request) async {
    var error = startScanError;
    if (error != null) {
      startScanError = null;
      throw error;
    }
    var scan = ++startScanCount;
    Timer(const Duration(milliseconds: 20), () {
      _scanResponses.add(
        BmScanResponse(
          advertisements: [
            BmScanAdvertisement(
              remoteId: DeviceIdentifier(fakeScanDeviceId(scan)),
              platformName: 'device $scan',
              advName: 'device $scan',
              connectable: true,
              txPowerLevel: null,
              appearance: null,
              manufacturerData: const {},
              serviceData: const {},
              serviceUuids: const [],
              rssi: -50,
            ),
          ],
          success: true,
          errorCode: 0,
          errorString: '',
        ),
      );
    });
    return true;
  }

  @override
  Future<bool> stopScan(BmStopScanRequest request) async => true;
}
