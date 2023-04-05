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

import static android.os.Build.VERSION_CODES.LOLLIPOP;

import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.os.ParcelUuid;

import androidx.annotation.RequiresApi;

import java.util.UUID;


@RequiresApi(LOLLIPOP)
public class BatteryService extends Service {

    private static final UUID BATTERY_SERVICE_UUID = UUID
            .fromString("0000180F-0000-1000-8000-00805f9b34fb");

    private static final UUID BATTERY_LEVEL_UUID = UUID
            .fromString("00002A19-0000-1000-8000-00805f9b34fb");
    private static final int INITIAL_BATTERY_LEVEL = 50;
    private static final int BATTERY_LEVEL_MAX = 100;
    private static final String BATTERY_LEVEL_DESCRIPTION = "The current charge level of a " +
            "battery. 100% represents fully charged while 0% represents fully discharged.";

    // GATT
    private BluetoothGattService mBatteryService;
    private BluetoothGattCharacteristic mBatteryLevelCharacteristic;

    public BatteryService() {
        super();
        mBatteryLevelCharacteristic =
                new BluetoothGattCharacteristic(BATTERY_LEVEL_UUID,
                        BluetoothGattCharacteristic.PROPERTY_READ | BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                        BluetoothGattCharacteristic.PERMISSION_READ);

        mBatteryLevelCharacteristic.addDescriptor(
                Peripheral.getClientCharacteristicConfigurationDescriptor());

        mBatteryLevelCharacteristic.addDescriptor(
                Peripheral.getCharacteristicUserDescriptionDescriptor(BATTERY_LEVEL_DESCRIPTION));

        mBatteryService = new BluetoothGattService(BATTERY_SERVICE_UUID,
                BluetoothGattService.SERVICE_TYPE_PRIMARY);
        mBatteryService.addCharacteristic(mBatteryLevelCharacteristic);

        setValue(INITIAL_BATTERY_LEVEL);
    }

    void init() {

        // return view;
    }


    public BluetoothGattService getBluetoothGattService() {
        return mBatteryService;
    }

    @Override
    public ParcelUuid getServiceUUID() {
        return new ParcelUuid(BATTERY_SERVICE_UUID);
    }


    /// set the value of the characteristics
    public void setValue(int newBatteryLevel) {
        mBatteryLevelCharacteristic.setValue(newBatteryLevel,
                BluetoothGattCharacteristic.FORMAT_UINT8, /* offset */ 0);
    /*
    if (source != mBatteryLevelSeekBar) {
      mBatteryLevelSeekBar.setProgress(newBatteryLevel);
    }
    if (source != mBatteryLevelEditText) {
      mBatteryLevelEditText.setText(Integer.toString(newBatteryLevel));
    }*/
        //TODO send response
    }

    @Override
    public void notificationsEnabled(BluetoothGattCharacteristic characteristic, boolean indicate) {
        if (characteristic.getUuid() != BATTERY_LEVEL_UUID) {
            return;
        }
        if (indicate) {
            return;
        }
    /*
    getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
        Toast.makeText(getActivity(), R.string.notificationsEnabled, Toast.LENGTH_SHORT)
            .show();
      }
    });
    */
        //TODO notify
    }

    @Override
    public void notificationsDisabled(BluetoothGattCharacteristic characteristic) {
        if (characteristic.getUuid() != BATTERY_LEVEL_UUID) {
            return;
        }
    /*
    getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
        Toast.makeText(getActivity(), R.string.notificationsNotEnabled, Toast.LENGTH_SHORT)
            .show();
      }
    });
    */
        //TODO notify
    }
}
