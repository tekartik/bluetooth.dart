import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

export 'package:flutter_blue_plus/flutter_blue_plus.dart';

typedef FlutterBlue = FlutterBluePlus;

extension FlutterBluePlusPrvExt on FlutterBluePlus {
  /// Scans and gives each advertisement, until the native scan stops (its
  /// [timeout], [FlutterBluePlus.stopScan], an error). Throws when a scan
  /// is already running. Cancelling the subscription does not stop the
  /// native scan.
  static Stream<ScanResult> scanAndStreamResults({
    List<Guid> withServices = const [],
    Duration? timeout,
    bool androidUsesFineLocation = false,
  }) {
    if (FlutterBluePlus.isScanningNow) {
      throw Exception('Another scan is already in progress');
    }
    return flutterBluePlusScan(
      withServices: withServices,
      timeout: timeout,
      androidUsesFineLocation: androidUsesFineLocation,
    );
  }
}

/// Scans (when listened) and gives each advertisement, until the native scan
/// stops (its [timeout], [FlutterBluePlus.stopScan], an error, given to the
/// stream). A scan already running is replaced (flutter_blue_plus restarts
/// it). Cancelling the subscription does not stop the native scan.
Stream<ScanResult> flutterBluePlusScan({
  List<Guid> withServices = const [],
  Duration? timeout,
  bool androidUsesFineLocation = false,
}) {
  late StreamController<ScanResult> controller;
  StreamSubscription<List<ScanResult>>? resultsSubscription;
  StreamSubscription<bool>? scanningSubscription;
  var ended = false;

  void end() {
    if (!ended) {
      ended = true;
      unawaited(resultsSubscription?.cancel());
      unawaited(scanningSubscription?.cancel());
      unawaited(controller.close());
    }
  }

  controller = StreamController<ScanResult>(
    onListen: () {
      // onScanResults does not give the results of a previous scan; while a
      // scan runs it gives its last result first: not ours.
      var results = FlutterBluePlus.onScanResults;
      if (FlutterBluePlus.isScanningNow) {
        results = results.skip(1);
      }
      resultsSubscription = results.listen((list) {
        for (var result in list) {
          controller.add(result);
        }
      }, onError: (Object e, StackTrace st) => controller.addError(e, st));
      FlutterBluePlus.startScan(
        withServices: withServices,
        timeout: timeout,
        oneByOne: true,
        androidUsesFineLocation: androidUsesFineLocation,
      ).then(
        (_) {
          if (!ended) {
            // isScanning gives its current value first: only listened once
            // the scan started (it was false before).
            scanningSubscription = FlutterBluePlus.isScanning
                .where((scanning) => !scanning)
                .listen((_) => end());
          }
        },
        onError: (Object e, StackTrace st) {
          if (!ended) {
            controller.addError(e, st);
            end();
          }
        },
      );
    },
    onCancel: () {
      ended = true;
      unawaited(resultsSubscription?.cancel());
      unawaited(scanningSubscription?.cancel());
    },
  );
  return controller.stream;
}
