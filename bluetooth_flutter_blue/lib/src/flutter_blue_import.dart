import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

export 'package:flutter_blue_plus/flutter_blue_plus.dart';

typedef FlutterBlue = FlutterBluePlus;

extension FlutterBluePlusPrvExt on FlutterBluePlus {
  static Stream<ScanResult> scanAndStreamResults({
    List<Guid> withServices = const [],
    Duration? timeout,
    bool androidUsesFineLocation = false,
  }) {
    if (FlutterBluePlus.isScanningNow) {
      throw Exception('Another scan is already in progress');
    }

    final controller = StreamController<ScanResult>();

    var subscription = FlutterBluePlus.scanResults.listen(
      (r) {
        for (var scanResult in r) {
          controller.add(scanResult);
        }
      },
      onError: (Object e, StackTrace? stackTrace) =>
          controller.addError(e, stackTrace),
    );

    FlutterBluePlus.startScan(
      withServices: withServices,
      timeout: timeout,
      removeIfGone: null,
      oneByOne: true,
      androidUsesFineLocation: androidUsesFineLocation,
    );

    Future scanComplete = FlutterBluePlus.isScanning.where((e) => !e).first;

    scanComplete.whenComplete(() {
      subscription.cancel();
      controller.close();
    });

    return controller.stream;
  }
}
