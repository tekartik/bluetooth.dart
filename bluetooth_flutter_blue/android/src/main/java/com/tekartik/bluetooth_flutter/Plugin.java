package com.tekartik.bluetooth_flutter;

import android.app.Activity;
import android.content.Context;

import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry;

/**
 * BluetoothFlutterPlugin
 */
public abstract class Plugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {

    private Context context;

    public Context getContext() {
        return context;
    }

    public Activity getActivity() {
        return activity;
    }

    final private Activity activity;


    public Plugin(PluginRegistry.Registrar registrar) {
        this.context = registrar.context().getApplicationContext();
        this.activity = registrar.activity();

    }


}
