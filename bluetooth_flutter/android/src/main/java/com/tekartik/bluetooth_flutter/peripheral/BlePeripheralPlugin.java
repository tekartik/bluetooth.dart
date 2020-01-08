package com.tekartik.bluetooth_flutter.peripheral;

import android.os.Build;
import android.util.Log;

import com.tekartik.bluetooth_flutter.BfluPluginError;
import com.tekartik.bluetooth_flutter.BluetoothFlutterPlugin;
import com.tekartik.bluetooth_flutter.PluginRequest;

import java.util.Map;
import java.util.UUID;

import static com.tekartik.bluetooth_flutter.BfluPluginError.errorCodeNoPeripheral;
import static com.tekartik.bluetooth_flutter.BfluPluginError.errorOtherError;
import static com.tekartik.bluetooth_flutter.BfluPluginError.errorUnsupported;

public class BlePeripheralPlugin {
    public static final String TAG = "BfluPluginPral";
    final BluetoothFlutterPlugin bfluPlugin;

    public BlePeripheralPlugin(BluetoothFlutterPlugin bfluPlugin) {
        this.bfluPlugin = bfluPlugin;
    }


    public void onInitPeripheral(PluginRequest request) {
        if (hasVerboseLevel()) {
            Log.i(TAG, "initPeripheral");
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {

            PeripheralDefinition definition = Utils.peripheralDefinitionFromMap((Map) request.call.arguments);
            Peripheral newPeripheral = new Peripheral(bfluPlugin);
            Log.d(TAG, definition.services.toString());
            if (newPeripheral.init(definition.services, (String) request.call.argument("deviceName"))) {
                Log.i(TAG, "init success");
                setPeripheral(newPeripheral);
                request.sendSuccess();
            } else {
                Log.i(TAG, "init failure");
                bfluPlugin.sendError(request, errorUnsupported);
                return;
            }


        } else {
            bfluPlugin.sendError(request, errorUnsupported);
        }
    }


    public void onStartAdvertising(PluginRequest request) {
        if (hasVerboseLevel()) {
            Log.i(TAG, "startAdvertising");
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (getPeripheral() == null) {
                Peripheral newPeripheral = new Peripheral(bfluPlugin);
                if (newPeripheral.init(null, (String) request.call.argument("deviceName")
                )) {
                    Log.i(TAG, "init success");
                    setPeripheral(newPeripheral);
                } else {
                    Log.i(TAG, "init failure");
                    sendError(request, errorUnsupported);
                    return;
                }
            }
            if (!getPeripheral().start(request)) {
                sendError(request, BfluPluginError.errorCodeNotEnabled);
            }


        } else {
            sendError(request, errorUnsupported);
        }
    }

    private Peripheral getPeripheral() {
        return bfluPlugin.getPeripheral();
    }

    private void setPeripheral(Peripheral peripheral) {
        bfluPlugin.setPeripheral(peripheral);
    }

    public boolean hasVerboseLevel() {
        return bfluPlugin.hasVerboseLevel();
    }


    public void sendError(PluginRequest request, int errorCode) {
        bfluPlugin.sendError(request, errorCode);
    }



    public void onPeripheralSetCharacteristicValue(PluginRequest request) {
        if (hasVerboseLevel()) {
            Log.i(TAG, "peripheralSetCharacteristicValue");
        }
        if (getPeripheral() == null) {
            sendError(request, errorCodeNoPeripheral);
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {

            UUID serviceUuid = UUID.fromString((String) request.call.argument("service"));
            UUID characteristicUuid = UUID.fromString((String) request.call.argument("characteristic"));
            byte[] value = request.call.argument("value");

            if (getPeripheral().setValue(serviceUuid, characteristicUuid, value)) {
                request.sendSuccess();
            } else {
                sendError(request, errorOtherError);
            }
        } else {
            sendError(request, errorUnsupported);
        }
    }
}
