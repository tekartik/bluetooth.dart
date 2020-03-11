/*
 * Copyright 2015 Google Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.tekartik.bluetooth_flutter.peripheral;

import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.os.Build;
import android.os.ParcelUuid;
import android.util.Log;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import androidx.annotation.RequiresApi;

import static com.tekartik.bluetooth_flutter.BluetoothFlutterPlugin.TAG;

@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class Service {
    final BluetoothGattService bluetoothGattService;
    final Map<UUID, Characteristic> uuidCharacteristicMap = new HashMap<>();
    final List<Characteristic> characteristics;

    // for existing battery service...
    public Service() {

        characteristics = null;
        bluetoothGattService = null;
    }

    public Service(BluetoothGattService bluetoothGattService, List<Characteristic> characteristics) {
        this.bluetoothGattService = bluetoothGattService;
        this.characteristics = characteristics;
        if (characteristics != null) {
            for (Characteristic characteristic : characteristics) {

                /*
                characteristic.bluetoothGattCharacteristic.addDescriptor(
                        Peripheral.getClientCharacteristicConfigurationDescriptor());

                characteristic.bluetoothGattCharacteristic.addDescriptor(
                        Peripheral.getCharacteristicUserDescriptionDescriptor("Test name"));
                        */


                bluetoothGattService.addCharacteristic(characteristic.bluetoothGattCharacteristic);
                // Add to map for fast access
                uuidCharacteristicMap.put(characteristic.getUuid(), characteristic);
            }
        }
    }

    public UUID getUuid() {
        return getBluetoothGattService().getUuid();

    }

    public BluetoothGattService getBluetoothGattService() {
        return bluetoothGattService;

    }

    ParcelUuid parcelUuid;

    public ParcelUuid getServiceUUID() {
        return parcelUuid;
    }

    /**
     * Function to communicate to the Service that a device wants to write to a
     * characteristic.
     * <p>
     * The Service should check that the value being written is valid and
     * return a code appropriately. The Service should update the UI to reflect the change.
     *
     * @param characteristic Characteristic to write to
     * @param value          Value to write to the characteristic
     * @return {@link android.bluetooth.BluetoothGatt#GATT_SUCCESS} if the write operation
     * was completed successfully. See {@link android.bluetooth.BluetoothGatt} for GATT return codes.
     */
    public int writeCharacteristic(BluetoothGattCharacteristic characteristic, int offset, byte[] value) {
        throw new UnsupportedOperationException("Method writeCharacteristic not overridden");
    }

    ;

    /**
     * Function to notify to the Service that a device has disabled notifications on a
     * CCC descriptor.
     * <p>
     * The Service should update the UI to reflect the change.
     *
     * @param characteristic Characteristic written to
     */
    public void notificationsDisabled(BluetoothGattCharacteristic characteristic) {
        throw new UnsupportedOperationException("Method notificationsDisabled not overridden");
    }

    ;

    /**
     * Function to notify to the Service that a device has enabled notifications on a
     * CCC descriptor.
     * <p>
     * The Service should update the UI to reflect the change.
     *
     * @param characteristic Characteristic written to
     * @param indicate       Boolean that says if it's indicate or notify.
     */
    public void notificationsEnabled(BluetoothGattCharacteristic characteristic, boolean indicate) {
        throw new UnsupportedOperationException("Method notificationsEnabled not overridden");
    }

    public Characteristic getCharacteristic(UUID characteristicUuid) {
        Characteristic characteristic = uuidCharacteristicMap.get(characteristicUuid);
        if (characteristic == null) {
            Log.i(TAG, "Characteristic " + characteristicUuid + " not found in " + this);
        }
        return characteristic;
    }

    ;

    /**
     * This interface must be implemented by activities that contain a Service to allow an
     * interaction in the fragment to be communicated to the activity.
     */
    public interface ServiceFragmentDelegate {
        void sendNotificationToDevices(BluetoothGattCharacteristic characteristic);
    }

    @Override
    public String toString() {
        return getUuid().toString() + " " + characteristics;
    }
}
