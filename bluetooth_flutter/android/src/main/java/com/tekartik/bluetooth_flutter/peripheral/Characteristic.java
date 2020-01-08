package com.tekartik.bluetooth_flutter.peripheral;

import android.bluetooth.BluetoothGattCharacteristic;
import android.os.Build;
import android.util.Log;

import com.tekartik.bluetooth_flutter.BluetoothFlutterPlugin;

import java.util.UUID;

import androidx.annotation.RequiresApi;

import static com.tekartik.bluetooth_flutter.BluetoothFlutterPlugin.TAG;


public class Characteristic {
    final BluetoothGattCharacteristic bluetoothGattCharacteristic;

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    public Characteristic(BluetoothGattCharacteristic bluetoothGattCharacteristic, String description) {
        this.bluetoothGattCharacteristic = bluetoothGattCharacteristic;


        bluetoothGattCharacteristic.addDescriptor(
                Peripheral.getClientCharacteristicConfigurationDescriptor());

        if (description != null) {
            bluetoothGattCharacteristic.addDescriptor(
                    Peripheral.getCharacteristicUserDescriptionDescriptor(description));
        }

    }

    public UUID getUuid() {
        return bluetoothGattCharacteristic.getUuid();
    }

    public boolean setValue(byte[] value) {
        if (BluetoothFlutterPlugin.instance.hasVerboseLevel()) {
            Log.i(TAG, "Setting value " + Utils.bytesToHex(value) + " on " + this);
        }
        return bluetoothGattCharacteristic.setValue(value);
    }

    public byte[] getValue() {
        byte[] value = bluetoothGattCharacteristic.getValue();
        if (BluetoothFlutterPlugin.instance.hasVerboseLevel()) {
            Log.i(TAG, "Getting value " + value + " on " + this);
        }
        return value;
    }

    @Override
    public String toString() {
        return getUuid().toString();
    }
}
