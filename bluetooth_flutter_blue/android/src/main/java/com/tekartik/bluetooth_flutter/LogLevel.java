package com.tekartik.bluetooth_flutter;

import io.flutter.plugin.common.MethodCall;

public class LogLevel {

    static final int none = 0;
    static final int verbose = 2;

    static Integer getLogLevel(MethodCall methodCall) {
        return methodCall.argument("logLevel");
    }

    public static boolean hasVerboseLevel(int level) {
        return level >= verbose;
    }
}
