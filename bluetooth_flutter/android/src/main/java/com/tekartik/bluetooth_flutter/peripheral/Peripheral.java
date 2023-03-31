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
import static com.tekartik.bluetooth_flutter.BfluPluginError.errorCodeStartFailure;

import android.annotation.SuppressLint;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattServer;
import android.bluetooth.BluetoothGattServerCallback;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.content.Context;
import android.os.ParcelUuid;
import android.util.Log;

import androidx.annotation.RequiresApi;

import com.tekartik.bluetooth_flutter.BluetoothFlutterPlugin;
import com.tekartik.bluetooth_flutter.PluginRequest;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RequiresApi(LOLLIPOP)
public class Peripheral {

    private static final int REQUEST_ENABLE_BT = 1;
    private static final String TAG = "BfluPlugin";
    private static final String CURRENT_FRAGMENT_TAG = "CURRENT_FRAGMENT";


    /*
    private static final UUID CHARACTERISTIC_USER_DESCRIPTION_UUID = UUID
            .fromString("00002901-87ae-41fe-b826-6ad4069efaff");
    private static final UUID CLIENT_CHARACTERISTIC_CONFIGURATION_UUID = UUID
            .fromString("00002902-87ae-41fe-b826-6ad4069efaff");
            */

    private static final UUID CHARACTERISTIC_USER_DESCRIPTION_UUID = UUID
            .fromString("00002901-0000-1000-8000-00805f9b34fb");
    private static final UUID CLIENT_CHARACTERISTIC_CONFIGURATION_UUID = UUID
            .fromString("00002902-0000-1000-8000-00805f9b34fb");


    private Service mCurrentService;
    private BluetoothGattService mBluetoothGattService;
    private HashSet<BluetoothDevice> mBluetoothDevices;
    private BluetoothManager mBluetoothManager;
    private BluetoothAdapter mBluetoothAdapter;
    private AdvertiseData mAdvData;
    private AdvertiseData mAdvScanResponse;
    private AdvertiseSettings mAdvSettings;
    private BluetoothLeAdvertiser mAdvertiser;
    private AdvertiseCallback
            mAdvCallback;
    private List<Service> services;

    final private BluetoothFlutterPlugin bluetoothFlutterPlugin;

    public Peripheral(BluetoothFlutterPlugin bluetoothFlutterPlugin) {
        this.bluetoothFlutterPlugin = bluetoothFlutterPlugin;
    }

    Map<UUID, Service> uuidServiceMap = new HashMap<>();

    @SuppressLint("MissingPermission")
    public boolean init(List<Service> services, String deviceName) {

        // Log.i(TAG, "init");
        // Create object
        mCurrentService = new BatteryService();

        // super.onCreate(savedInstanceState);
        mBluetoothDevices = new HashSet<>();
        mBluetoothManager = (BluetoothManager) bluetoothFlutterPlugin.getContext().getSystemService(Context.BLUETOOTH_SERVICE);
        mBluetoothAdapter = mBluetoothManager.getAdapter();

        mBluetoothGattService = mCurrentService.getBluetoothGattService();


        this.services = new ArrayList<>();
        if (services != null) {
            for (Service service : services) {
                // Add to map for fast access
                uuidServiceMap.put(service.getBluetoothGattService().getUuid(), service);
            }
            this.services.addAll(services);
        }
        //TODO for now include battery
        // this.services.add(mCurrentService);

        //Log.i(TAG, "init3");
        mAdvSettings = new AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
                .setConnectable(true)
                .setTimeout(0)
                .build();

        if (deviceName != null) {
            mBluetoothAdapter.setName(deviceName);
        }
        mAdvScanResponse = new AdvertiseData.Builder()
                .setIncludeDeviceName(true)
                //.addServiceUuid(new ParcelUuid(UUID.randomUUID()))
                .build();


        //Log.i(TAG, "inited");
        return true;

    }

    class AddServiceData {
        // index of the current service added
        int index = -1;
        final private PluginRequest pluginRequest;
        final List<Service> services;

        AddServiceData(PluginRequest pluginRequest, List<Service> services) {
            this.pluginRequest = pluginRequest;
            this.services = services;
        }

        void next() {
            index++;
            if (index == services.size()) {
                startAdvertisingWhenServicesAdded(pluginRequest);
            } else {
                mGattServer.addService(services.get(index).bluetoothGattService);
            }

        }
    }

    private AddServiceData addServiceData;
    private BluetoothGattServer mGattServer;
    private final BluetoothGattServerCallback mGattServerCallback = new BluetoothGattServerCallback() {
        @Override
        public void onConnectionStateChange(BluetoothDevice device, final int status, int newState) {
            super.onConnectionStateChange(device, status, newState);
            Log.v(TAG, "onConnectionStateChange(" + device.getAddress() + ", status " + status + ", newState " + newState);
            if (status == BluetoothGatt.GATT_SUCCESS) {
                if (newState == BluetoothGatt.STATE_CONNECTED) {
                    mBluetoothDevices.add(device);
                    updateConnectedDevicesStatus();
                    // Log.v(TAG, "Connected to device: " + device.getAddress());
                    Map<String, Object> map = new HashMap<>();

                    if (bluetoothFlutterPlugin.connectionSink != null) {
                        map.put("connected", true);
                        map.put("address", device.getAddress());
                        bluetoothFlutterPlugin.connectionSink.success(map);
                    }
                } else if (newState == BluetoothGatt.STATE_DISCONNECTED) {
                    mBluetoothDevices.remove(device);
                    updateConnectedDevicesStatus();
                    Log.v(TAG, "Disconnected from device");

                    if (bluetoothFlutterPlugin.connectionSink != null) {
                        Map<String, Object> map = new HashMap<>();
                        map.put("connected", false);
                        map.put("address", device.getAddress());
                        bluetoothFlutterPlugin.connectionSink.success(map);
                    }
                }
            } else {
                mBluetoothDevices.remove(device);
                updateConnectedDevicesStatus();
                // There are too many gatt errors (some of them not even in the documentation) so we just
                // show the error to the user.
        /*
        final String errorMessage = getString(R.string.status_errorWhenConnecting) + ": " + status;
        /*runOnUiThread(new Runnable() {
          @Override
          public void run() {
            Toast.makeText(Peripheral.this, errorMessage, Toast.LENGTH_LONG).show();
          }
        });
        */
                //TODO notify
                Log.e(TAG, "Error when connecting: " + status);
            }
        }

        @Override
        public void onServiceAdded(int status, BluetoothGattService service) {
            super.onServiceAdded(status, service);

            Log.d(TAG, "onServiceAdded(" + service.getUuid());
            Log.d(TAG, "onServiceAdded(" + service + ") " + service.getCharacteristics().size());
            for (BluetoothGattCharacteristic characteristic : service.getCharacteristics()) {
                Log.d(TAG, "characteristic " + characteristic.getUuid().toString()
                        + " " + characteristic.getInstanceId());
                for (BluetoothGattDescriptor descriptor : characteristic.getDescriptors()) {
                    //Log.d(TAG, "descriptor " + descriptor.getUuid() + " " + descript)

                }
            }
            addServiceData.next();
        }

        @SuppressLint("MissingPermission")
        @Override
        public void onCharacteristicReadRequest(BluetoothDevice device, int requestId, int offset,
                                                BluetoothGattCharacteristic characteristic) {
            Log.d(TAG, "Device tried to read characteristic: " + characteristic.getUuid());
            Log.d(TAG, "Offset: " + offset + ", Value: " + Arrays.toString(characteristic.getValue()));

            super.onCharacteristicReadRequest(device, requestId, offset, characteristic);
            if (offset != 0) {
                mGattServer.sendResponse(device, requestId, BluetoothGatt.GATT_INVALID_OFFSET, offset,
                        /* value (optional) */ null);
                return;
            }
            mGattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS,
                    offset, characteristic.getValue());
        }

        @Override
        public void onNotificationSent(BluetoothDevice device, int status) {
            super.onNotificationSent(device, status);
            Log.v(TAG, "Notification sent. Status: " + status);
        }

        @SuppressLint("MissingPermission")
        @Override
        public void onCharacteristicWriteRequest(BluetoothDevice device, int requestId,
                                                 BluetoothGattCharacteristic characteristic, boolean preparedWrite, boolean responseNeeded,
                                                 int offset, byte[] value) {
            Log.v(TAG, "Characteristic Write request: " + Arrays.toString(value));
            // Don't call super here...
            // super.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite,
            //        responseNeeded, offset, value);
            //

            // Always response true
            // int status = mCurrentService.writeCharacteristic(characteristic, offset, value);
            int status = BluetoothGatt.GATT_SUCCESS;
            if (responseNeeded) {
                mGattServer.sendResponse(device, requestId, status,
                        // No need to respond with an offset
                        0,
                        // No need to respond with a value
                        null);
            }
            if (bluetoothFlutterPlugin.writeCharacteristicSink != null) {
                final Map<String, Object> map = new HashMap<>();
                map.put("service", characteristic.getService().getUuid().toString());
                map.put("characteristic", characteristic.getUuid().toString());
                map.put("value", value);

                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        bluetoothFlutterPlugin.writeCharacteristicSink.success(map);
                    }
                });

            }
        }

        @SuppressLint("MissingPermission")
        @Override
        public void onDescriptorReadRequest(BluetoothDevice device, int requestId,
                                            int offset, BluetoothGattDescriptor descriptor) {
            Log.d(TAG, "Device tried to read descriptor: " + descriptor.getUuid());
            Log.d(TAG, "Value: " + Arrays.toString(descriptor.getValue()));

            super.onDescriptorReadRequest(device, requestId, offset, descriptor);
            if (offset != 0) {
                mGattServer.sendResponse(device, requestId, BluetoothGatt.GATT_INVALID_OFFSET, offset,
                        /* value (optional) */ null);
                return;
            }
            mGattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset,
                    descriptor.getValue());
        }

        @SuppressLint("MissingPermission")
        @Override
        public void onDescriptorWriteRequest(BluetoothDevice device, int requestId,
                                             BluetoothGattDescriptor descriptor, boolean preparedWrite, boolean responseNeeded,
                                             int offset,
                                             byte[] value) {
            Log.v(TAG, "Descriptor Write Request " + descriptor.getUuid() + " " + Arrays.toString(value));
            super.onDescriptorWriteRequest(device, requestId, descriptor, preparedWrite, responseNeeded,
                    offset, value);

            int status = BluetoothGatt.GATT_SUCCESS;
            if (descriptor.getUuid() == CLIENT_CHARACTERISTIC_CONFIGURATION_UUID) {
                BluetoothGattCharacteristic characteristic = descriptor.getCharacteristic();
                boolean supportsNotifications = (characteristic.getProperties() &
                        BluetoothGattCharacteristic.PROPERTY_NOTIFY) != 0;
                boolean supportsIndications = (characteristic.getProperties() &
                        BluetoothGattCharacteristic.PROPERTY_INDICATE) != 0;

                if (!(supportsNotifications || supportsIndications)) {
                    status = BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED;
                } else if (value.length != 2) {
                    status = BluetoothGatt.GATT_INVALID_ATTRIBUTE_LENGTH;
                } else if (Arrays.equals(value, BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE)) {
                    status = BluetoothGatt.GATT_SUCCESS;
                    mCurrentService.notificationsDisabled(characteristic);

                    descriptor.setValue(value);
                } else if (supportsNotifications &&
                        Arrays.equals(value, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)) {
                    status = BluetoothGatt.GATT_SUCCESS;
                    mCurrentService.notificationsEnabled(characteristic, false /* indicate */);
                    descriptor.setValue(value);
                } else if (supportsIndications &&
                        Arrays.equals(value, BluetoothGattDescriptor.ENABLE_INDICATION_VALUE)) {
                    status = BluetoothGatt.GATT_SUCCESS;
                    mCurrentService.notificationsEnabled(characteristic, true /* indicate */);
                    descriptor.setValue(value);
                } else {
                    status = BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED;
                }
            } else {
                status = BluetoothGatt.GATT_SUCCESS;
                descriptor.setValue(value);
            }
            if (responseNeeded) {
                mGattServer.sendResponse(device, requestId, status,
                        /* No need to respond with offset */ 0,
                        /* No need to respond with a value */ null);
            }
        }
    };

    public boolean start(final PluginRequest request) {
        Log.i(TAG, "start");

        mAdvCallback = new AdvertiseCallback() {
            @Override
            public void onStartFailure(int errorCode) {
                super.onStartFailure(errorCode);
                Log.e(TAG, "Not broadcasting: " + errorCode);
                int statusText;
                switch (errorCode) {
                    case ADVERTISE_FAILED_ALREADY_STARTED:
                        // statusText = R.string.status_advertising;
                        Log.w(TAG, "ADVERTISE_FAILED_ALREADY_STARTED App was already advertising");
                        break;
                    case ADVERTISE_FAILED_DATA_TOO_LARGE:
                        // statusText = R.string.status_advDataTooLarge;
                        Log.w(TAG, "ADVERTISE_FAILED_DATA_TOO_LARGE");
                        break;
                    case ADVERTISE_FAILED_FEATURE_UNSUPPORTED:
                        // statusText = R.string.status_advFeatureUnsupported;
                        Log.w(TAG, "ADVERTISE_FAILED_DATA_TOO_LARGE");
                        break;
                    case ADVERTISE_FAILED_INTERNAL_ERROR:
                        // statusText = R.string.status_advInternalError;
                        Log.w(TAG, "ADVERTISE_FAILED_DATA_TOO_LARGE");
                        break;
                    case ADVERTISE_FAILED_TOO_MANY_ADVERTISERS:
                        // statusText = R.string.status_advTooManyAdvertisers;
                        Log.w(TAG, "ADVERTISE_FAILED_DATA_TOO_LARGE");
                        break;
                    default:
                        // statusText = R.string.status_notAdvertising;
                        Log.wtf(TAG, "Unhandled error: " + errorCode);
                }
//TODO notify
                sendError(request, errorCodeStartFailure);
            }

            @Override
            public void onStartSuccess(AdvertiseSettings settingsInEffect) {
                super.onStartSuccess(settingsInEffect);
                Log.v(TAG, "Broadcasting");

                // TODO notify
                // notifyAdvertiseStart(true);
                request.sendSuccess();
            }


        };

        // Add service one at a time
        addServiceData = new AddServiceData(request, services);

        mGattServer = mBluetoothManager.openGattServer(getContext(), mGattServerCallback);
        if (mGattServer == null) {
            Log.i(TAG, "ble not enable");
            ensureBleFeaturesAvailable();
            return false;
        }
        // Log.i(TAG, "#2");
        addServiceData.next();
        /*
        // Add a service for a total of three services (Generic Attribute and Generic Access
        // are present by default).
        for (Service service : services) {
            mGattServer.addService(service.bluetoothGattService);
        }
        return startAdvertisingWhenServicesAdded(request);
        */
        return true;
    }

    @SuppressLint("MissingPermission")
    private boolean startAdvertisingWhenServicesAdded(PluginRequest request) {

        AdvertiseData.Builder builder =
                new AdvertiseData.Builder()
                        .setIncludeTxPowerLevel(true)
                        .setIncludeDeviceName(true);
        // .addServiceUuid(mCurrentService.getServiceUUID())


        List<Map> list = request.call.argument("services");
        if (list != null) {
            for (Map item : list) {
                String uuidText = (String) item.get("uuid");
                UUID uuid = UUID.fromString(uuidText);
                ParcelUuid parcelUuid = new ParcelUuid(uuid);
                // builder.addServiceUuid(parcelUuid)
//                        .addServiceData(parcelUuid, new byte[]{1, 2, 3, 4})
                ;
            }
        }
        // Use ericson
        //builder.addManufacturerData(0, new byte[]{1, 2, 3, 4});

        mAdvData = builder.build();


        // Log.i(TAG, "#3");
        if (mBluetoothAdapter.isMultipleAdvertisementSupported()) {
            Log.i(TAG, "start advertising");
            mAdvertiser = mBluetoothAdapter.getBluetoothLeAdvertiser();
            mAdvertiser.startAdvertising(mAdvSettings, mAdvData, mAdvScanResponse, mAdvCallback);
            return true;
        } else {
            //mAdvStatus.setText(R.string.status_noLeAdv);
            Log.e(TAG, "isMultipleAdvertisementSupported false");
            return false;
        }

    }

    private Context getContext() {
        return bluetoothFlutterPlugin.getContext();
    }


    static void sendError(PluginRequest request, int errorCode) {
        Peripheral.sendError(request, errorCode);
    }

    @SuppressLint("MissingPermission")
    public void stop() {

        try {
            if (mGattServer != null) {
                mGattServer.close();
            }
            if (mBluetoothAdapter.isEnabled() && mAdvertiser != null) {
                // If stopAdvertising() gets called before close() a null
                // pointer exception is raised.

                mAdvertiser.stopAdvertising(mAdvCallback);

            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        // resetStatusViews();

    }


    @SuppressLint("MissingPermission")
    public void sendNotificationToDevices(BluetoothGattCharacteristic characteristic) {
        boolean indicate = (characteristic.getProperties()
                & BluetoothGattCharacteristic.PROPERTY_INDICATE)
                == BluetoothGattCharacteristic.PROPERTY_INDICATE;
        for (BluetoothDevice device : mBluetoothDevices) {
            // true for indication (acknowledge) and false for notification (unacknowledge).
            mGattServer.notifyCharacteristicChanged(device, characteristic, indicate);
        }
    }


    private void updateConnectedDevicesStatus() {
    /*
    final String message = getString(R.string.status_devicesConnected) + " "
        + mBluetoothManager.getConnectedDevices(BluetoothGattServer.GATT).size();
    runOnUiThread(new Runnable() {
      @Override
      public void run() {
        mConnectionStatus.setText(message);
      }
    });
    */
        //TODO
        Log.d(TAG, "TODO notify updateConnectedDevicesStatus()");
    }


    ///////////////////////
    ////// Bluetooth //////
    ///////////////////////
    public static BluetoothGattDescriptor getClientCharacteristicConfigurationDescriptor() {
        BluetoothGattDescriptor descriptor = new BluetoothGattDescriptor(
                CLIENT_CHARACTERISTIC_CONFIGURATION_UUID,
                (BluetoothGattDescriptor.PERMISSION_READ | BluetoothGattDescriptor.PERMISSION_WRITE));
        descriptor.setValue(new byte[]{0, 0});
        return descriptor;
    }

    public static BluetoothGattDescriptor getCharacteristicUserDescriptionDescriptor(String defaultValue) {
        BluetoothGattDescriptor descriptor = new BluetoothGattDescriptor(
                CHARACTERISTIC_USER_DESCRIPTION_UUID,
                (BluetoothGattDescriptor.PERMISSION_READ | BluetoothGattDescriptor.PERMISSION_WRITE));
        try {
            descriptor.setValue(defaultValue.getBytes("UTF-8"));
        } finally {
            return descriptor;
        }
    }

    private void ensureBleFeaturesAvailable() {
        if (mBluetoothAdapter == null) {
            // Toast.makeText(this, R.string.bluetoothNotSupported, Toast.LENGTH_LONG).show();
            Log.e(TAG, "Bluetooth not supported");
            // finish();
            //TODO notify
        } else if (!mBluetoothAdapter.isEnabled()) {
            // Make sure bluetooth is enabled.
            // Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            // startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
            //TODO notify
            Log.e(TAG, "Bluetooth not enabled");
        }
    }

    @SuppressLint("MissingPermission")
    private void disconnectFromDevices() {
        Log.d(TAG, "Disconnecting devices...");
        for (BluetoothDevice device : mBluetoothManager.getConnectedDevices(
                BluetoothGattServer.GATT)) {
            Log.d(TAG, "Devices: " + device.getAddress() + " " + device.getName());
            mGattServer.cancelConnection(device);
        }
    }


    private Characteristic getCharacteristic(UUID serviceUuid, UUID characteristicUuid) {
        Service service = getService(serviceUuid);
        if (service != null) {
            return service.getCharacteristic(characteristicUuid);
        }
        Log.i(TAG, "Service " + serviceUuid + " not found");
        return null;
    }

    private Service getService(UUID serviceUuid) {
        return uuidServiceMap.get(serviceUuid);

    }

    public boolean setValue(UUID serviceUuid, UUID characteristicUuid, byte[] value) {


        Characteristic characteristic = getCharacteristic(serviceUuid, characteristicUuid);
        if (characteristic == null) {
            Log.e(TAG, "Service " + serviceUuid + " Characteristic " + characteristicUuid + " not found");
            return false;
        }
        return characteristic.setValue(value);
    }

    public byte[] getValue(UUID serviceUuid, UUID characteristicUuid) {
        Characteristic characteristic = getCharacteristic(serviceUuid, characteristicUuid);
        if (characteristic == null) {
            Log.e(TAG, "Service " + serviceUuid + " Characteristic " + characteristicUuid + " not found");
            return null;
        }
        return characteristic.getValue();
    }

    public boolean sendNotificationToDevices(UUID serviceUuid, UUID characteristicUuid) {
        Characteristic characteristic = getCharacteristic(serviceUuid, characteristicUuid);
        if (characteristic == null) {
            Log.e(TAG, "Service " + serviceUuid + " Characteristic " + characteristicUuid + " not found");
            return false;

        }
        boolean indicate = (characteristic.bluetoothGattCharacteristic.getProperties()
                & BluetoothGattCharacteristic.PROPERTY_INDICATE)
                == BluetoothGattCharacteristic.PROPERTY_INDICATE;
        for (BluetoothDevice device : mBluetoothDevices) {
            // true for indication (acknowledge) and false for notification (unacknowledge).
            //TODO handle failure (??? what should i do if one fails)
            mGattServer.notifyCharacteristicChanged(device, characteristic.bluetoothGattCharacteristic, indicate);
        }
        return true;
    }

    void runOnUiThread(Runnable runnable) {
        bluetoothFlutterPlugin.getHandler().post(runnable);
    }
}
