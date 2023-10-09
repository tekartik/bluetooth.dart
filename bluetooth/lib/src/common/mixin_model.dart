import 'package:cv/cv.dart';

const methodStartScan = 'startScan';
const methodStopScan = 'stopScan';
const methodStreamGetScanResult = 'streamGetScanResult';

/// `startScan` param
class StartScanParam extends CvModelBase {
  final androidScanMode = CvField<int>('androidScanMode');
  @override
  List<CvField> get fields => [androidScanMode];
}
