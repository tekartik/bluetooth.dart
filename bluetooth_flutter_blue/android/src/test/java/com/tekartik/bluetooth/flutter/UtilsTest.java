package com.tekartik.bluetooth.flutter;

import android.bluetooth.BluetoothGattService;

import junit.framework.Assert;

import org.junit.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Constants between dart & Java world
 */

public class UtilsTest {


    // {services: [{uuid: 36c9159b-6cc6-43b3-b198-ac03cc44949e,
    //      characteristics: [{properties: 18,
    //                         permissions: 1,
    //                         uuid: b5b15bf1-0215-464e-815b-0d88e261e56a}]}]}

    @Test
    public void peripheral() {
        Map map = new HashMap();
        List<Map> serviceList = new ArrayList<>();

        Map characteristicMap = new HashMap();
        characteristicMap.put("uuid", "b5b15bf1-0215-464e-815b-0d88e261e56a");
        characteristicMap.put("properties", 18);
        characteristicMap.put("permissions", 1);

        Map serviceMap = new HashMap();
        serviceMap.put("uuid", "36c9159b-6cc6-43b3-b198-ac03cc44949e");
        serviceMap.put("characteristics", Arrays.asList(characteristicMap));
        serviceList.add(serviceMap);

        map.put("services", serviceList);

        /*
        PeripheralDefinition peripheralDefinition = Utils.peripheralDefinitionFromMap(map);
        BluetoothGattService service = peripheralDefinition.services.get(0);
        Assert.assertEquals(service.getUuid(), UUID.fromString("36c9159b-6cc6-43b3-b198-ac03cc44949e"));
        */

    }

}
