package com.tekartik.bluetooth_flutter;

public class BfluPluginError extends PluginError {
    static public int errorUnsupported = 1;
    static public int errorOtherError = 2;
    static public int errorCodeNotEnabled = 3;
    static public int errorCodeStartFailure = 4;
    /// No peripheral inited
    static public int errorCodeNoPeripheral = 5;
    /// No connection found
    static public int errorCodeConnectionNotFound = 6;




    public BfluPluginError(int errorCode) {
        this.type = "tekartik_flutter";
        this.message = Integer.toString(errorCode);
    }
}
