package com.tekartik.bluetooth_flutter.client;

import static com.tekartik.bluetooth_flutter.Constant.DEVICE_KEY;
import static com.tekartik.bluetooth_flutter.Constant.RSSI_KEY;

import android.os.Build;

import androidx.annotation.RequiresApi;

import java.util.HashMap;
import java.util.Map;

public class ScanResult {
    public BluetoothDevice device;
    public int rssi;

    public ScanResult(android.bluetooth.BluetoothDevice bluetoothDevice, int rssi) {
        this.rssi = rssi;
        if (bluetoothDevice != null) {
            device = new BluetoothDevice(bluetoothDevice);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    public ScanResult(android.bluetooth.le.ScanResult leScanResult) {

        rssi = leScanResult.getRssi();
        android.bluetooth.BluetoothDevice bluetoothDevice = leScanResult.getDevice();
        if (bluetoothDevice != null) {
            device = new BluetoothDevice(bluetoothDevice);
        }


    }

    Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<>();

        map.put(RSSI_KEY, rssi);
        if (device != null) {

            map.put(DEVICE_KEY, device.toMap());
        }
        return map;
    }
}
