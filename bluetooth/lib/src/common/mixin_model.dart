import 'package:tekartik_common_utils/model/model_v2.dart';

const methodStartScan = 'startScan';
const methodStopScan = 'stopScan';
const methodStreamGetScanResult = 'streamGetScanResult';

/// `startScan` param
class StartScanParam extends CvModelBase {
  final androidScanMode = CvField<int>('androidScanMode');
  @override
  List<CvField> get fields => [androidScanMode];
}
