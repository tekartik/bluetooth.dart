package com.tekartik.bluetooth_flutter.client;

import static android.bluetooth.le.ScanSettings.SCAN_MODE_LOW_POWER;

import com.tekartik.bluetooth_flutter.Utils;

import java.util.List;
import java.util.Map;

public class ScanSettings {
    public int androidScanMode;
    public List<String> serviceUuids;

    ScanSettings(Map map) {
        androidScanMode = Utils.getInt(map, "androidScanMode", SCAN_MODE_LOW_POWER);
        serviceUuids = Utils.getStringList(map, "serviceUuids");

    }
}
