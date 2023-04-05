package com.tekartik.bluetooth_flutter.common;

import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ModelUtils {

    static public String UUID_KEY = "uuid"; // string
    static public String PROPERTIES_KEY = "properties"; // int
    static public String CHARACTERISTICS_KEY = "characteristics"; // list
    static public String DESCRIPTORS_KEY = "descriptors"; // list
    static public String VALUE_KEY = "value"; // byte[]

    static public List<Map<String, Object>> servicesDefToMap(List<BluetoothGattService> services) {
        if (services == null) {
            return null;
        }
        List<Map<String, Object>> list = new ArrayList<>();
        for (BluetoothGattService service : services) {
            Map<String, Object> serviceDefMap = serviceDefToMap(service);
            if (serviceDefMap != null) {
                list.add(serviceDefMap);
            }
        }
        return list;
    }

    static public Map<String, Object> serviceDefToMap(BluetoothGattService service) {
        if (service == null) {
            return null;
        }
        final Map<String, Object> map = new HashMap<>();
        map.put(UUID_KEY, service.getUuid().toString());
        List<BluetoothGattCharacteristic> characteristics = service.getCharacteristics();
        if (characteristics != null) {
            List<Map<String, Object>> list = new ArrayList<>();
            for (BluetoothGattCharacteristic characteristic : characteristics) {
                list.add(characteristicDefToMap(characteristic));
            }
            map.put(CHARACTERISTICS_KEY, list);
        }
        return map;
    }

    static public Map<String, Object> characteristicDefToMap(BluetoothGattCharacteristic characteristic) {
        final Map<String, Object> map = new HashMap<>();
        map.put(UUID_KEY, characteristic.getUuid().toString());
        map.put(PROPERTIES_KEY,
                characteristic.getProperties());
        List<BluetoothGattDescriptor> descriptors = characteristic.getDescriptors();
        if (descriptors != null) {
            List<Map<String, Object>> list = new ArrayList<>();
            for (BluetoothGattDescriptor descriptor : descriptors) {
                list.add(descriptorDefToMap(descriptor));
            }
            map.put(DESCRIPTORS_KEY, list);
        }
        return map;
    }

    static public Map<String, Object> descriptorDefToMap(BluetoothGattDescriptor descriptor) {
        final Map<String, Object> map = new HashMap<>();
        map.put(UUID_KEY, descriptor.getUuid().toString());
        return map;
    }
}
