package com.tekartik.bluetooth_flutter;

import static com.tekartik.bluetooth_flutter.BfluPluginError.errorCodeNoPeripheral;
import static com.tekartik.bluetooth_flutter.BfluPluginError.errorOtherError;
import static com.tekartik.bluetooth_flutter.BfluPluginError.errorUnsupported;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Handler;
import android.util.Log;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.tekartik.bluetooth_flutter.client.BleClientPlugin;
import com.tekartik.bluetooth_flutter.peripheral.BlePeripheralPlugin;
import com.tekartik.bluetooth_flutter.peripheral.Peripheral;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

/**
 * BluetoothFlutterPlugin
 */
public class BluetoothFlutterPlugin implements FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler, PluginRegistry.RequestPermissionsResultListener, PluginRegistry.ActivityResultListener {

    public static final String TAG = "BfluPlugin";
    public static BluetoothFlutterPlugin instance;
    BluetoothManager bluetoothManager;
    public BluetoothAdapter bluetoothAdapter;

    static public String NAMESPACE = "com.tekartik.bluetooth_flutter";
    // the call is synchronized from the dart side so we're fine
    int enableBluetoothRequestCode;
    Result enableBluetoothResult;

    int checkPermissionsRequestCode;
    Result checkPermissionsResult;

    BleClientPlugin clientPlugin;
    BlePeripheralPlugin peripheralPlugin;

    private Peripheral peripheral;
    public int logLevel = LogLevel.none;

    public MethodChannel channel;
    public EventChannel connectionChannel;
    public EventChannel callbackChannel;
    public EventChannel writeCharacteristicChannel;
    private Boolean mHasBluetooth;
    private Boolean mHasBluetoothBle;
    private Context mApplicationContext;
    private Handler handler;
    private ActivityPluginBinding activityBinding;
    FlutterPluginBinding pluginBinding;

    private BleClientPlugin getClientPlugin() {
        if (clientPlugin == null) {
            clientPlugin = new BleClientPlugin(this);
        }
        return clientPlugin;
    }

    private BlePeripheralPlugin getPeripheralPlugin() {
        if (peripheralPlugin == null) {
            peripheralPlugin = new BlePeripheralPlugin(this);
        }
        return peripheralPlugin;
    }


    //
    // Plugin registration.
    //
    @SuppressWarnings("deprecation")
    public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
        BluetoothFlutterPlugin sqflitePlugin = new BluetoothFlutterPlugin();
        sqflitePlugin.onAttachedToEngine(registrar.context(), registrar.messenger());

        registrar.addRequestPermissionsResultListener(sqflitePlugin);
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        Log.d(TAG, "onAttachedToEngine");
        pluginBinding = binding;
        onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
    }

    @SuppressWarnings("deprecation")
    private void createHandler() {
        handler = new Handler();
    }

    private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger) {
        this.mApplicationContext = applicationContext;

        instance = this;
        createHandler();


        channel = new MethodChannel(messenger, "tekartik_bluetooth_flutter");
        channel.setMethodCallHandler(this);


        callbackChannel = new EventChannel(messenger, NAMESPACE + "/callback");
        callbackChannel.setStreamHandler(callbackHandler);
        // TODO needed? can we reuse callbackChannel?
        connectionChannel = new EventChannel(messenger, NAMESPACE + "/connection");
        connectionChannel.setStreamHandler(stateHandler);
        writeCharacteristicChannel = new EventChannel(messenger, NAMESPACE + "/writeCharacteristic");
        writeCharacteristicChannel.setStreamHandler(writeCharacteristicHandler);


    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        Log.d(TAG, "onAttachedToActivity");
        activityBinding = binding;
        //onAttachedToEngine(binding.getActivity(), pluginBinding.getBinaryMessenger());
        activityBinding.addActivityResultListener(this);
    }

    @Override
    public void onDetachedFromActivity() {
        Log.d(TAG, "onDetachedFromActivity");
        if (activityBinding != null) {
            try {
                activityBinding.removeActivityResultListener(this);
                activityBinding.removeRequestPermissionsResultListener(this);
            } catch (Exception ignore) {

            }
            activityBinding = null;
        }
        //tearDown();
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        Log.d(TAG, "onDetachedFromEngine");
        pluginBinding = binding;
        mApplicationContext = null;
        channel.setMethodCallHandler(null);
        channel = null;
        callbackChannel.setStreamHandler(null);
        callbackChannel = null;
        bluetoothAdapter = null;
        bluetoothManager = null;
    }


    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    private boolean hasBluetooth() {
        if (mHasBluetooth == null) {
            // Use this check to determine whether BLE is supported on the device. Then
            // you can selectively disable BLE-related features.
            this.bluetoothManager = (BluetoothManager) mApplicationContext.getSystemService(Context.BLUETOOTH_SERVICE);
            if (bluetoothManager != null) {
                bluetoothAdapter = bluetoothManager.getAdapter();
                if (bluetoothAdapter != null) {
                    mHasBluetooth = true;
                    return true;
                }
            }
            mHasBluetooth = false;
        }

        return mHasBluetooth;
    }

    private boolean hasBluetoothBle() {
        if (mHasBluetoothBle == null) {
            // Use this check to determine whether BLE is supported on the device. Then
            // you can selectively disable BLE-related features.
            mHasBluetoothBle = mApplicationContext.getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE);
        }
        return mHasBluetoothBle;
    }

    // Need public constructor
    public BluetoothFlutterPlugin() {
        Log.d(TAG, "BluetoothFlutterPlugin()");
    }


    public EventChannel.EventSink connectionSink;
    private final EventChannel.StreamHandler stateHandler = new EventChannel.StreamHandler() {
        @Override
        public void onListen(Object o, EventChannel.EventSink eventSink) {
            connectionSink = eventSink;
        }

        @Override
        public void onCancel(Object o) {
            connectionSink = null;
        }
    };

    public EventChannel.EventSink writeCharacteristicSink;
    private final EventChannel.StreamHandler writeCharacteristicHandler = new EventChannel.StreamHandler() {
        @Override
        public void onListen(Object o, EventChannel.EventSink eventSink) {
            writeCharacteristicSink = eventSink;
        }

        @Override
        public void onCancel(Object o) {
            writeCharacteristicSink = null;
        }
    };

    public EventChannel.EventSink callbackSink;
    private final EventChannel.StreamHandler callbackHandler = new EventChannel.StreamHandler() {
        @Override
        public void onListen(Object o, EventChannel.EventSink eventSink) {
            callbackSink = eventSink;
        }

        @Override
        public void onCancel(Object o) {
            callbackSink = null;
        }
    };

    //@SuppressLint("MissingPermission")
    @Override
    public void onMethodCall(MethodCall call, Result result) {
        try {
            onRequest(new PluginRequest(call, result));
        } catch (Exception e) {
            result.error(call.method, "exception " + e, call.arguments);
        }
    }

    public void onRequest(PluginRequest request) {
        if (hasVerboseLevel()) {
            Log.d(TAG, "onRequest(" + request.call.method + ", " + request.call.arguments + ")");
        }
        MethodCall call = request.call;
        Result result = request.result;
        String method = call.method;
        this.bluetoothManager = (BluetoothManager) mApplicationContext.getSystemService(Context.BLUETOOTH_SERVICE);
        if (bluetoothManager != null) {
            bluetoothAdapter = bluetoothManager.getAdapter();
        }

        if (method.equals("getPlatformVersion")) {
            result.success("Android " + Build.VERSION.RELEASE);
        } else if (call.method.equals("enableBluetooth")) {
            onEnableBluetooth(request);
        } else if (method.equals("disableBluetooth")) {
            if (bluetoothAdapter.isEnabled()) {
                // Requires admin permission
                bluetoothAdapter.disable();
            }
        } else if (method.equals("peripheralStartAdvertising")) {
            getPeripheralPlugin().onStartAdvertising(request);

        } else if (method.equals("peripheralInit")) {
            getPeripheralPlugin().onInitPeripheral(request);

        } else if (method.equals("peripheralSetCharacteristicValue")) {
            getPeripheralPlugin().onPeripheralSetCharacteristicValue(request);

        } else if (method.equals("peripheralGetCharacteristicValue")) {
            onPeripheralGetCharacteristicValue(request);
        } else if (method.equals("peripheralNotifyCharacteristicValue")) {
            onPeripheralNotifyCharacteristicValue(request);

        } else if (method.equals("stopAdvertising")) {
            Log.i(TAG, "stopAdvertising");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                if (getPeripheral() != null) {
                    getPeripheral().stop();
                }
                request.sendSuccess();
            } else {
                sendError(request, errorUnsupported);
            }

        } else if (call.method.equals("remoteNewConnection")) {
            getClientPlugin().onNewConnection(request);
        } else if (call.method.equals("remoteConnect")) {
            getClientPlugin().onConnect(request);
        } else if (call.method.equals("remoteDiscoverServices")) {
            getClientPlugin().onDiscoverServices(request);
        } else if (call.method.equals("remoteGetServices")) {
            getClientPlugin().onGetServices(request);
        } else if (call.method.equals("remoteReadCharacteristic")) {
            getClientPlugin().onReadCharacteristic(request);
        } else if (call.method.equals("remoteDisconnect")) {
            getClientPlugin().onDisconnect(request);
        } else if (method.equals("startScan")) {
            getClientPlugin().onStartScan(request);
        } else if (method.equals("stopScan")) {
            getClientPlugin().onStopScan(request);
        } else if (method.equals("getInfo")) {
            // deprecated
            onGetInfo(request);
        } else if (method.equals("getAdminInfo")) {
            onGetAdminInfo(request);
        } else if (method.equals("getConnectedDevices")) {
            onGetConnectedDevices(request);
        } else if (method.equals("setOptions")) {
            onSetOptions(request);
        } else if (method.equals("checkCoarseLocationPermission")) {
            // onCheckCoarseLocationPermission(request);
            // Compat
            onCheckBluetoothPermissions(request);
        } else if (method.equals("checkBluetoothPermissions")) {
            onCheckBluetoothPermissions(request);
        } else {
            Log.i(TAG, "Unhandled " + call.method);
        }
    }

    private void onGetConnectedDevices(PluginRequest request) {
        List<BluetoothDevice> devices = bluetoothManager.getConnectedDevices(BluetoothProfile.GATT);
        List<Map<String, Object>> list = new ArrayList<>();
        if (devices != null) {
            for (BluetoothDevice androidBluetoothDevice : devices) {
                list.add(new com.tekartik.bluetooth_flutter.client.BluetoothDevice(androidBluetoothDevice).toMap());
            }
        }
        request.result.success(list);
    }


    private void onGetInfo(PluginRequest request) {
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("hasBluetooth", hasBluetooth());
        if (hasBluetooth()) {
            map.put("hasBluetoothBle", hasBluetoothBle());
            boolean enabled = bluetoothAdapter.isEnabled();
            map.put("isBluetoothEnabled", enabled);
            if (enabled) {
                map.put("isScanning", getClientPlugin().isScanning());
            }
        }
        request.result.success(map);
    }

    private void onGetAdminInfo(PluginRequest request) {
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("hasBluetooth", hasBluetooth());
        if (hasBluetooth()) {
            map.put("hasBluetoothBle", hasBluetoothBle());
            boolean enabled = bluetoothAdapter.isEnabled();
            map.put("isBluetoothEnabled", enabled);

        }
        request.result.success(map);
    }


    private void onSetOptions(PluginRequest request) {
        Integer logLevel = LogLevel.getLogLevel(request.call);
        if (logLevel != null) {
            this.logLevel = logLevel;
        }
        request.result.success(null);
    }

    @SuppressLint("MissingPermission")
    private void onEnableBluetooth(PluginRequest request) {
        if (!bluetoothAdapter.isEnabled()) {
            Integer requestCode = request.call.argument("androidRequestCode");
            if (requestCode != null) {
                if (hasVerboseLevel()) {
                    Log.i(TAG, "onEnableBluetooth(" + requestCode + ")");
                }
                enableBluetoothRequestCode = requestCode;
                enableBluetoothResult = request.result;
                Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
                activityBinding.getActivity().startActivityForResult(enableBtIntent, enableBluetoothRequestCode);
            } else {
                // Requires admin permission
                if (hasVerboseLevel()) {
                    Log.i(TAG, "onEnableBluetooth()");
                }
                try {
                    bluetoothAdapter.enable();
                    if (hasVerboseLevel()) {
                        Log.i(TAG, "enable done");
                    }
                    request.result.success(null);
                } catch (Exception e) {
                    if (hasVerboseLevel()) {
                        Log.i(TAG, "enable failed " + e);
                    }
                    request.result.error("enable_bluetooth", "failed " + e, null);
                }
            }
        } else {
            request.result.success(null);
        }
    }


    private void onPeripheralGetCharacteristicValue(PluginRequest request) {
        if (hasVerboseLevel()) {
            Log.i(TAG, "peripheralGetCharacteristicValue");
        }
        if (getPeripheral() == null) {
            sendError(request, errorCodeNoPeripheral);
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {

            UUID serviceUuid = UUID.fromString((String) request.call.argument("service"));
            UUID characteristicUuid = UUID.fromString((String) request.call.argument("characteristic"));

            byte[] value = getPeripheral().getValue(serviceUuid, characteristicUuid);
            request.sendSuccess(value);

        } else {
            sendError(request, errorUnsupported);
        }
    }

    private void onPeripheralNotifyCharacteristicValue(PluginRequest request) {
        if (hasVerboseLevel()) {
            Log.i(TAG, "peripheralNotifyCharacteristicValue");
        }
        if (getPeripheral() == null) {
            sendError(request, errorCodeNoPeripheral);
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {

            UUID serviceUuid = UUID.fromString((String) request.call.argument("service"));
            UUID characteristicUuid = UUID.fromString((String) request.call.argument("characteristic"));

            if (getPeripheral().sendNotificationToDevices(serviceUuid, characteristicUuid)) {
                request.sendSuccess();
            } else {
                sendError(request, errorOtherError);
            }

        } else {
            sendError(request, errorUnsupported);
        }
    }

    public void sendError(PluginRequest request, int errorCode) {
        if (hasVerboseLevel()) {
            Log.i(TAG, "sendError(" + errorCode + ")");
        }
        request.sendError(new BfluPluginError(errorCode));
    }

    public void sendSuccess(PluginRequest request, Object value) {
        if (hasVerboseLevel()) {
            Log.i(TAG, "sendSuccess(" + value + ")");
        }
        request.sendSuccess(value);
    }


    public void onCheckCoarseLocationPermission(PluginRequest request) {
        Integer requestCode = request.call.argument("androidRequestCode");
        if (requestCode != null) {
            if (hasVerboseLevel()) {
                Log.i(TAG, "onEnableBluetooth(" + requestCode + ")");
            }
            if (ContextCompat.checkSelfPermission(activityBinding.getActivity(), Manifest.permission.ACCESS_COARSE_LOCATION)
                    != PackageManager.PERMISSION_GRANTED) {
                checkPermissionsRequestCode = requestCode;
                checkPermissionsResult = request.result;
                ActivityCompat.requestPermissions(
                        activityBinding.getActivity(),
                        new String[]{
                                Manifest.permission.ACCESS_COARSE_LOCATION
                        },
                        checkPermissionsRequestCode);
            } else {
                request.result.success(true);
            }
        } else {
            request.result.error("checkCoarseLocationPermission", "missing androidRequestCode", null);

        }

    }

    public void onCheckBluetoothPermissions(PluginRequest request) {

        List<String> permissions = new ArrayList<String>();
        Boolean advertise = request.call.argument("advertise");
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.add(Manifest.permission.BLUETOOTH_SCAN);
            permissions.add(Manifest.permission.BLUETOOTH_CONNECT);
            if (Boolean.TRUE.equals(advertise)) {
                permissions.add(Manifest.permission.BLUETOOTH_ADVERTISE);
            }

        } else {
            permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION);
            permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
        }
        Integer requestCode = request.call.argument("androidRequestCode");

        List<String> askForPermissions = new ArrayList<String>();
        for (String permission : permissions) {
            int grantResult = ContextCompat.checkSelfPermission(activityBinding.getActivity(), permission);
            if (hasVerboseLevel()) {
                Log.i(TAG, "permission " + permission + ": " + (
                        (grantResult == PackageManager.PERMISSION_GRANTED) ? "ok" : ("error (" + grantResult + ")")));
            }
            if (grantResult
                    != PackageManager.PERMISSION_GRANTED) {
                askForPermissions.add(permission);
            }
        }
        if (requestCode != null) {
            if (!askForPermissions.isEmpty()) {
                if (hasVerboseLevel()) {
                    Log.i(TAG, "onCheckBluetoothPermissions(" + askForPermissions + ", " + requestCode + ")");
                }


                checkPermissionsResult = request.result;
                ActivityCompat.requestPermissions(
                        activityBinding.getActivity(),
                        askForPermissions.toArray(new String[0]),
                        checkPermissionsRequestCode);
            } else {
                request.result.success(true);
            }
        } else {
            request.result.error("onCheckBluetoothPermissions", "missing androidRequestCode", null);

        }

    }

    @Override
    public boolean onRequestPermissionsResult(
            int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == checkPermissionsRequestCode) {
            for (int grantResult : grantResults) {
                if (grantResult != PackageManager.PERMISSION_GRANTED) {

                    checkPermissionsResult.error(
                            "checkCoarseLocationPermission", "missing location permissions for scanning", null);
                    return true;

                }
            }
            checkPermissionsResult.success(true);
            return true;
        }
        return false;
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
        if (requestCode == enableBluetoothRequestCode) {
            if (requestCode == Activity.RESULT_OK) {
                enableBluetoothResult.success(null);
            } else {
                // Check enabled again
                // bluetoothAdapter.isEnabled()
                enableBluetoothResult.error("enable_bluetooth", "failed " + resultCode, null);
            }
            return true;
        }
        return false;
    }

    public BluetoothAdapter getBluetoothAdapter() {
        return bluetoothAdapter;
    }

    public boolean hasVerboseLevel() {
        return LogLevel.hasVerboseLevel(logLevel);
    }

    public Handler getHandler() {
        return handler;
    }

    public void bgInvokeMethod(final String method, final Object arguments) {
        getHandler().post(new Runnable() {
            @Override
            public void run() {
                invokeMethod(method, arguments);
            }
        });

    }


    public void invokeMethod(String method, Object arguments) {
        if (hasVerboseLevel()) {
            Log.i(TAG, "callback: " + method + " args " + arguments);
        }
        channel.invokeMethod(method, arguments);
    }

    public Peripheral getPeripheral() {
        return peripheral;
    }

    public void setPeripheral(Peripheral peripheral) {
        this.peripheral = peripheral;
    }

    public Activity getActivity() {
        return activityBinding.getActivity();
    }

    public Context getContext() {
        return mApplicationContext;
    }
}
