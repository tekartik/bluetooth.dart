package com.tekartik.bluetooth_flutter.client;

import static com.tekartik.bluetooth_flutter.BfluPluginError.errorCodeConnectionNotFound;
import static com.tekartik.bluetooth_flutter.BfluPluginError.errorOtherError;
import static com.tekartik.bluetooth_flutter.BfluPluginError.errorUnsupported;
import static com.tekartik.bluetooth_flutter.BluetoothFlutterPlugin.TAG;
import static com.tekartik.bluetooth_flutter.Constant.CONNECTION_ID_KEY;
import static com.tekartik.bluetooth_flutter.LogLevel.hasVerboseLevel;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanFilter;
import android.os.Build;
import android.os.ParcelUuid;
import android.util.Log;

import com.tekartik.bluetooth_flutter.BluetoothFlutterPlugin;
import com.tekartik.bluetooth_flutter.PluginRequest;
import com.tekartik.bluetooth_flutter.common.ModelUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class BleClientPlugin {

    boolean mIsScanning = false;
    Map<Integer, DeviceConnection> connections = new HashMap<>();


    final BluetoothFlutterPlugin bfluPlugin;
    private final Map<String, BluetoothGatt> mGattServers = new HashMap<>();

    public BleClientPlugin(BluetoothFlutterPlugin bfluPlugin) {
        this.bfluPlugin = bfluPlugin;
    }


    public void onNewConnection(PluginRequest request) {
        if (hasVerboseLevel(bfluPlugin.logLevel)) {
            Log.i(TAG, "onNewConnection");
        }

        String address = request.getArgumentString("deviceId");
        final android.bluetooth.BluetoothDevice device = getBluetoothAdapter().getRemoteDevice(address);
        if (device == null) {
            Log.w(TAG, "Device not found.  Unable to connect.");
            bfluPlugin.sendError(request, errorUnsupported);
            return;
        }
        /*
         // If device was connected to previously but is now disconnected, attempt a reconnect
                if(mGattServers.containsKey(connectionId) && !isConnected) {
                    if(mGattServers.get(connectionId).connect()){
                        result.success(null);
                    } else {
                        result.error("reconnect_error", "error when reconnecting to device", null);
                    }
                    return;
                }

         */
        if (hasVerboseLevel(bfluPlugin.logLevel)) {
            Log.i(TAG, "Found device " + device.getName() + " address " + device.getAddress());
        }
        // We want to directly connect to the device, so we are setting the autoConnect
        // parameter to false.
        // sendError(request, errorUnsupported);
        // New request, connect and add gattServer to Map
        BluetoothGatt gattServer;
        int connectionId = newConnectionId();
        DeviceConnection connection = new DeviceConnection(this, connectionId, device);
        connections.put(connectionId, connection);
        bfluPlugin.sendSuccess(request, connectionId);

    }

    public void onConnect(PluginRequest request) {
        if (hasVerboseLevel(bfluPlugin.logLevel)) {
            Log.i(TAG, "connect");
        }

        DeviceConnection deviceConnection = getConnectionOrError(request);
        if (deviceConnection != null) {
            boolean autoConnect = request.getArgumentBool("autoConnect", false);


            if (deviceConnection.connectGatt(autoConnect)) {
                getBfluPlugin().sendSuccess(request, null);
            } else {
                getBfluPlugin().sendError(request, errorOtherError);
            }
        }


    }

    int mLastConnectionId = 0;

    int newConnectionId() {
        return ++mLastConnectionId;
    }

    public void onDisconnect(PluginRequest request) {
        if (hasVerboseLevel(bfluPlugin.logLevel)) {
            Log.i(TAG, "disconnect");
        }

        DeviceConnection deviceConnection = getConnectionOrError(request);
        if (deviceConnection != null) {
            connections.remove(deviceConnection.connectionId);
            try {
                deviceConnection.gattServer.disconnect();
            } catch (Exception e) {
                Log.e(TAG, "disconnect failed for " + deviceConnection);
            }
            try {
                deviceConnection.gattServer.close();
            } catch (Exception e) {
                Log.e(TAG, "close failed for " + deviceConnection);
            }

            bfluPlugin.sendSuccess(request, null);
        }

    }

    public void onDiscoverServices(PluginRequest request) {
        DeviceConnection deviceConnection = getConnectionOrError(request);
        if (deviceConnection != null) {
            try {
                if (deviceConnection.discoverServices(request)) {
                    bfluPlugin.sendSuccess(request, null);
                    return;
                }
            } catch (Exception e) {
                Log.e(TAG, "discoverServices failed for " + deviceConnection + " error " + e);
            }
            bfluPlugin.sendError(request, errorOtherError);


        }
    }

    public void onReadCharacteristic(PluginRequest request) {
        DeviceConnection deviceConnection = getConnectionOrError(request);
        if (deviceConnection != null) {
            try {
                if (deviceConnection.readCharacteristic(request)) {
                    bfluPlugin.sendSuccess(request, null);
                    return;
                }
            } catch (Exception e) {
                Log.e(TAG, "readCharacteristic failed for " + deviceConnection + " error " + e);
            }
            bfluPlugin.sendError(request, errorOtherError);


        }
    }

    private DeviceConnection getConnectionOrError(PluginRequest request) {
        Integer connectionId = request.getArgumentInt(CONNECTION_ID_KEY);
        DeviceConnection deviceConnection = connections.get(connectionId);
        if (hasVerboseLevel(bfluPlugin.logLevel)) {
            Log.i(TAG, "Getting connection for " + connectionId + " " + deviceConnection);
        }
        if (deviceConnection != null) {
            return deviceConnection;
        } else {
            bfluPlugin.sendError(request, errorCodeConnectionNotFound);
            return null;
        }
    }

    public void onGetServices(PluginRequest request) {
        DeviceConnection deviceConnection = getConnectionOrError(request);
        if (deviceConnection != null) {
            try {
                bfluPlugin.sendSuccess(request, ModelUtils.servicesDefToMap(deviceConnection.getServices()));
            } catch (Exception e) {
                Log.e(TAG, "getServices failed for " + deviceConnection);
                bfluPlugin.sendError(request, errorOtherError);
            }
        }

    }

    public void onStartScan(PluginRequest request) {
        Map map = request.call.arguments();
        ScanSettings settings = new ScanSettings(map);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            startScan21(settings);
        } else {
            startScan18(settings);
        }
        mIsScanning = true;
        request.result.success(null);

    }

    public void onStopScan(PluginRequest request) {
        mIsScanning = false;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            stopScan21();
        } else {
            stopScan18();
        }
        request.result.success(null);
    }

    private ScanCallback scanCallback21;

    @TargetApi(21)
    private ScanCallback getScanCallback21() {
        if (scanCallback21 == null) {
            scanCallback21 = new ScanCallback() {

                @Override
                public void onScanResult(int callbackType, android.bluetooth.le.ScanResult leScanResult) {
                    super.onScanResult(callbackType, leScanResult);
                    final ScanResult scanResult;
                    if (leScanResult != null) {
                        scanResult = new ScanResult(leScanResult);


                        bfluPlugin.bgInvokeMethod("scanResult", scanResult.toMap());

                    }

                }

                @Override
                public void onBatchScanResults(List<android.bluetooth.le.ScanResult> results) {
                    super.onBatchScanResults(results);

                }

                @Override
                public void onScanFailed(int errorCode) {
                    super.onScanFailed(errorCode);
                }
            };
        }
        return scanCallback21;
    }


    @TargetApi(21)
    private void startScan21(ScanSettings scanSettings) throws IllegalStateException {
        BluetoothLeScanner scanner = getBluetoothAdapter().getBluetoothLeScanner();
        if (scanner == null)
            throw new IllegalStateException("getBluetoothLeScanner() is null. Is the Adapter on?");
        int scanMode = scanSettings.androidScanMode;
        List<ScanFilter> filters = null;
        if (scanSettings.serviceUuids != null) {

            filters = new ArrayList<>();
            for (String uuid : scanSettings.serviceUuids) {

                ScanFilter f = new ScanFilter.Builder().setServiceUuid(ParcelUuid.fromString(uuid)).build();
                filters.add(f);
            }
        }
        android.bluetooth.le.ScanSettings settings = new android.bluetooth.le.ScanSettings.Builder().setScanMode(scanMode).build();
        scanner.startScan(filters, settings, getScanCallback21());
    }

    @TargetApi(21)
    private void stopScan21() {
        BluetoothLeScanner scanner = getBluetoothAdapter().getBluetoothLeScanner();
        if (scanner != null) scanner.stopScan(getScanCallback21());
    }

    private BluetoothAdapter.LeScanCallback scanCallback18;

    private BluetoothAdapter.LeScanCallback getScanCallback18() {
        if (scanCallback18 == null) {
            scanCallback18 = new BluetoothAdapter.LeScanCallback() {
                @Override
                public void onLeScan(final android.bluetooth.BluetoothDevice bluetoothDevice, int rssi,
                                     byte[] scanRecord) {
                    final ScanResult scanResult = new ScanResult(bluetoothDevice, rssi);

                    bfluPlugin.bgInvokeMethod("scanResult", scanResult.toMap());


                }
            };
        }
        return scanCallback18;
    }

    private void startScan18(ScanSettings scanSettings) throws IllegalStateException {
        List<String> serviceUuids = scanSettings.serviceUuids;
        UUID[] uuids = new UUID[serviceUuids.size()];
        for (int i = 0; i < serviceUuids.size(); i++) {
            uuids[i] = UUID.fromString(serviceUuids.get(i));
        }
        @SuppressWarnings("deprecation")
        boolean success = getBluetoothAdapter().startLeScan(uuids, getScanCallback18());
        if (!success)
            throw new IllegalStateException("getBluetoothLeScanner() is null. Is the Adapter on?");
    }

    @SuppressWarnings("deprecation")
    private void stopScan18() {
        getBluetoothAdapter().stopLeScan(getScanCallback18());
    }


    private BluetoothAdapter getBluetoothAdapter() {
        return bfluPlugin.getBluetoothAdapter();
    }

    public boolean isScanning() {
        return mIsScanning;
    }

    private BluetoothFlutterPlugin getBfluPlugin() {
        return bfluPlugin;
    }
}
