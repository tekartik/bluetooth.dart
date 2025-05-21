import 'import.dart';

bool _devPrintEnabled = true;

/// Deprecated to prevent keeping the code used.
@Deprecated('Dev only')
void devPrint(Object object) {
  if (_devPrintEnabled) {
    // ignore: avoid_print
    print(object);
  }
}

/// Deprecated to prevent keeping the code used.
///
/// Can be use as a todo for weird code. int value = devWarning(myFunction());
/// The function is always called
@Deprecated('Dev only')
T devWarning<T>(T value) => value;

void _devError([Object? object]) {
  // one day remove the print however sometimes the error thrown is hidden
  try {
    throw UnsupportedError('$object');
  } catch (e, st) {
    if (_devPrintEnabled) {
      // ignore: avoid_print
      print('# ERROR $object');
      // ignore: avoid_print
      print(st);
    }
    rethrow;
  }
}

/// Deprecated to prevent keeping the code used.
///
/// Will call the action on debug only
@Deprecated('Dev only')
T? devDebugOnly<T>(T Function() action, {String? message}) {
  if (isDebug) {
    // ignore: avoid_print
    print(
      '[DEBUG_ONLY]${message != null ? ' $message' : ' debug only behavior'}',
    );
    return action();
  } else {
    return null;
  }
}

@Deprecated('Dev only')
void devError([Object? object]) => _devError(object);
