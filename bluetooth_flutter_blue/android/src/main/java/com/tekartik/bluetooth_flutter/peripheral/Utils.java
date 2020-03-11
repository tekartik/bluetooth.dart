package com.tekartik.bluetooth_flutter.peripheral;

import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.os.Build;

import androidx.annotation.RequiresApi;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class Utils {

    static public PeripheralDefinition peripheralDefinitionFromMap(Map map) {
        List<Service> services = new ArrayList<>();
        @SuppressWarnings("unchecked")
        List<Map> serviceList = (List<Map>) map.get("services");
        if (serviceList != null) {
            for (Map serviceMap : serviceList) {
                services.add(serviceFromMap(serviceMap));
            }
        }

        PeripheralDefinition peripheralDefinition = new PeripheralDefinition();
        peripheralDefinition.services = services;
        return peripheralDefinition;
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    static public Service serviceFromMap(Map map) {
        UUID uuid = UUID.fromString((String) map.get("uuid"));

        BluetoothGattService bluetoothGattService = new BluetoothGattService(uuid, BluetoothGattService.SERVICE_TYPE_PRIMARY);

        List<Characteristic> characteristics = new ArrayList<>();
        @SuppressWarnings("unchecked")
        List<Map> characteristicList = (List<Map>) map.get("characteristics");
        for (Map characteristicMap : characteristicList) {
            Characteristic characteristic = characteristicFromMap(characteristicMap);
            characteristics.add(characteristic);
        }


        return new Service(bluetoothGattService, characteristics);

    }

    private final static char[] hexArray = "0123456789ABCDEF".toCharArray();
    public static String bytesToHex(byte[] bytes) {
        char[] hexChars = new char[bytes.length * 2];
        for ( int j = 0; j < bytes.length; j++ ) {
            int v = bytes[j] & 0xFF;
            hexChars[j * 2] = hexArray[v >>> 4];
            hexChars[j * 2 + 1] = hexArray[v & 0x0F];
        }
        return new String(hexChars);
    }

    static public int parseInt(Object value) {
        return (int) (Integer) value;
    }

    static public BluetoothGattCharacteristic bluetoothGattCharacteristicFromMap(Map map) {
        UUID uuid = UUID.fromString((String) map.get("uuid"));
        int properties = parseInt(map.get("properties"));
        int permissions = parseInt(map.get("permissions"));

        return new BluetoothGattCharacteristic(uuid, properties, permissions);


    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    static public Characteristic characteristicFromMap(Map map) {
        UUID uuid = UUID.fromString((String) map.get("uuid"));
        int properties = parseInt(map.get("properties"));
        int permissions = parseInt(map.get("permissions"));
        String description = (String)map.get("description");

        return new Characteristic(new BluetoothGattCharacteristic(uuid, properties, permissions), description);


    }
}
