package com.tekartik.bluetooth_flutter.client;

import static android.bluetooth.BluetoothGatt.GATT_SUCCESS;
import static com.tekartik.bluetooth_flutter.BluetoothFlutterPlugin.TAG;
import static com.tekartik.bluetooth_flutter.Constant.CHARACTERISTIC_UUID_KEY;
import static com.tekartik.bluetooth_flutter.Constant.CONNECTION_ID_KEY;
import static com.tekartik.bluetooth_flutter.Constant.SERVICE_UUID_KEY;
import static com.tekartik.bluetooth_flutter.Constant.STATE_KEY;
import static com.tekartik.bluetooth_flutter.Constant.STATUS_KEY;
import static com.tekartik.bluetooth_flutter.common.ModelUtils.VALUE_KEY;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import com.tekartik.bluetooth_flutter.BluetoothFlutterPlugin;
import com.tekartik.bluetooth_flutter.PluginRequest;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class DeviceConnection {
    final int connectionId;
    final android.bluetooth.BluetoothDevice device;
    final BleClientPlugin bleClientPlugin;
    BluetoothGatt gattServer;

    // Implements callback methods for GATT events that the app cares about.  For example,
    // connection change and services discovered.
    private BluetoothGattCallback getGattCallback() {
        return new BluetoothGattCallback() {
            @Override
            public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
                if (gatt == gattServer) {
                    if (getBfluPlugin().hasVerboseLevel()) {
                        Log.i(TAG, "onConnectionStateChange " + status + " state " + newState);
                    }
                    Map<String, Object> map = new HashMap<String, Object>();
                    map.put(CONNECTION_ID_KEY, connectionId);
                    map.put(STATE_KEY, newState);
                    getBfluPlugin().bgInvokeMethod("remoteConnectionState", map);
                }
            }

            @Override
            public void onServicesDiscovered(BluetoothGatt gatt, int status) {
                if (gatt == gattServer) {
                    if (getBfluPlugin().hasVerboseLevel()) {
                        Log.i(TAG, "onServicesDiscovered");
                    }

                    List<BluetoothGattService> services = gatt.getServices();
                    if (services != null) {
                        List<Object> list = new ArrayList<>();
                        for (BluetoothGattService service : services) {
                            //TODO
                        }
                    }
                    //if (discoverRequest != null) {
                    getBfluPlugin().getHandler().post(new Runnable() {
                        @Override
                        public void run() {
                            Map<String, Object> map = new HashMap<String, Object>();
                            map.put(CONNECTION_ID_KEY, connectionId);
                            getBfluPlugin().bgInvokeMethod("remoteDiscoverServicesResult", map);
                        }
                    });
                }


            /*
            if (status == BluetoothGatt.GATT_SUCCESS) {
                broadcastUpdate(ACTION_GATT_SERVICES_DISCOVERED);
            } else {
                Log.w(TAG, "onServicesDiscovered received: " + status);
            }
            */
            }

            @Override
            public void onCharacteristicRead(BluetoothGatt gatt,
                                             BluetoothGattCharacteristic characteristic,
                                             int status) {
                Map<String, Object> map = new HashMap<String, Object>();
                map.put(CONNECTION_ID_KEY, connectionId);
                map.put(CHARACTERISTIC_UUID_KEY, characteristic.getUuid().toString());
                map.put(SERVICE_UUID_KEY, characteristic.getService().getUuid().toString());
                map.put(STATUS_KEY, status);
                if (status == GATT_SUCCESS) {
                    map.put(VALUE_KEY, characteristic.getValue());
                }
                getBfluPlugin().bgInvokeMethod("remoteReadCharacteristicResult", map);

            }

            @Override
            public void onCharacteristicChanged(BluetoothGatt gatt,
                                                BluetoothGattCharacteristic characteristic) {
            /*
            broadcastUpdate(ACTION_DATA_AVAILABLE, characteristic);
            */
            }
        };
    }

    private BluetoothFlutterPlugin getBfluPlugin() {
        return bleClientPlugin.bfluPlugin;
    }

    public DeviceConnection(BleClientPlugin bleClientPlugin, int connectionId, BluetoothDevice device) {
        this.connectionId = connectionId;

        this.bleClientPlugin = bleClientPlugin;
        this.device = device;
    }

    public boolean discoverServices(PluginRequest request) {
        if (gattServer.discoverServices()) {
            return true;
        }
        return false;

    }

    public List<BluetoothGattService> getServices() {
        List<BluetoothGattService> services = gattServer.getServices();
        return services;
    }

    public boolean connectGatt(boolean autoConnect) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                gattServer = device.connectGatt(getBfluPlugin().getActivity(), autoConnect, getGattCallback(), android.bluetooth.BluetoothDevice.TRANSPORT_LE);
            } else {
                gattServer = device.connectGatt(getBfluPlugin().getActivity(), autoConnect, getGattCallback());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        if (gattServer == null) {
            return false;
        } else {
            return true;
        }

    }

    private BluetoothGattCharacteristic findCharacteristic(String serviceId, String secondaryServiceId, String characteristicId) throws Exception {
        BluetoothGattService primaryService = gattServer.getService(UUID.fromString(serviceId));
        if (primaryService == null) {
            throw new Exception("service (" + serviceId + ") could not be located on the device");
        }
        BluetoothGattService secondaryService = null;
        if (secondaryServiceId != null &&
                secondaryServiceId.length() > 0) {
            for (BluetoothGattService s : primaryService.getIncludedServices()) {
                if (s.getUuid().equals(UUID.fromString(secondaryServiceId))) {
                    secondaryService = s;
                }
            }
            if (secondaryService == null) {
                throw new Exception("secondary service (" + secondaryServiceId + ") could not be located on the device");
            }
        }
        BluetoothGattService service = (secondaryService != null) ? secondaryService : primaryService;
        BluetoothGattCharacteristic characteristic = service.getCharacteristic(UUID.fromString(characteristicId));
        if (characteristic == null) {
            throw new Exception("characteristic (" + characteristicId + ") could not be located in the service (" + service.getUuid().toString() + ")");
        }
        return characteristic;
    }

    @NonNull
    @Override
    public String toString() {
        return "Connection " + connectionId;
    }

    public boolean readCharacteristic(PluginRequest request) throws Exception {
        BluetoothGattCharacteristic characteristic = findCharacteristic(request.getArgumentString(SERVICE_UUID_KEY), null, request.getArgumentString(CHARACTERISTIC_UUID_KEY));
        return gattServer.readCharacteristic(characteristic);
    }
}
