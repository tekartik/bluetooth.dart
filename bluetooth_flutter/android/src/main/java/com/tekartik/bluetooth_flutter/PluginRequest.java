package com.tekartik.bluetooth_flutter;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class PluginRequest {
    final public MethodCall call;
    final public MethodChannel.Result result;

    public PluginRequest(MethodCall call, MethodChannel.Result result) {
        this.call = call;
        this.result = result;
    }

    public void sendError(PluginError error) {
        result.error(error.type, error.message, error.data);
    }

    public void sendSuccess(Object value) {
        result.success(value);
    }

    public void sendSuccess() {
        sendSuccess(null);
    }

    Long getArgumentLong(String key) {
        Object argument = call.argument(key);
        if (argument instanceof Long) {
            return (Long) argument;
        } else if (argument instanceof Integer) {
            return ((Integer) argument).longValue();
        }
        return null;
    }

    public Integer getArgumentInt(String key) {
        Object argument = call.argument(key);
        if (argument instanceof Integer) {
            return (Integer) argument;
        } else if (argument instanceof Long) {
            return ((Long) argument).intValue();
        }
        return null;
    }

    public String getArgumentString(String key) {
        Object argument = call.argument(key);
        if (argument != null) {
            return argument.toString();
        }
        return null;
    }

    public Boolean getArgumentBool(String key) {
        Object argument = call.argument(key);
        if (argument instanceof Boolean) {
            return (Boolean) argument;
        }
        return null;
    }

    public boolean getArgumentBool(String key, boolean defaultValue) {
        Object argument = call.argument(key);
        if (argument instanceof Boolean) {
            return (Boolean) argument;
        }
        return defaultValue;
    }
}
