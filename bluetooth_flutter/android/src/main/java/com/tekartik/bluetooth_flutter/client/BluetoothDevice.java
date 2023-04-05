package com.tekartik.bluetooth_flutter.client;

import static com.tekartik.bluetooth_flutter.Constant.ADDRESS_KEY;
import static com.tekartik.bluetooth_flutter.Constant.NAME_KEY;

import java.util.HashMap;
import java.util.Map;

public class BluetoothDevice {
    public String address;
    public String name;

    static public BluetoothDevice fromAndroidBluetoothDevice(android.bluetooth.BluetoothDevice bluetoothDevice) {
        if (bluetoothDevice == null) {
            return null;
        }
        return new BluetoothDevice(bluetoothDevice);
    }

    public BluetoothDevice(android.bluetooth.BluetoothDevice bluetoothDevice) {
        address = bluetoothDevice.getAddress();
        name = bluetoothDevice.getName();
    }

    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<>();

        map.put(NAME_KEY, name);
        map.put(ADDRESS_KEY, address);
        return map;
    }
}
