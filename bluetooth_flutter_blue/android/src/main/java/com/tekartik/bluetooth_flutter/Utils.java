package com.tekartik.bluetooth_flutter;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class Utils {
    static public Integer getInteger(Map map, String key) {
        Object object = map.get(key);
        if (object instanceof Integer) {
            return (Integer) object;
        } else if (object instanceof Long) {
            return (int)(long)object;
        }
        return null;
    }

    static public List getList(Map map, String key) {
        Object object = map.get(key);
        if (object instanceof List) {
            return (List) object;
        }
        return null;
    }

    static public List<String> getStringList(Map map, String key) {
        List list = getList(map, key);
        if (list != null) {
            List<String> stringList = new ArrayList<>();
            for (Object object : list) {
                stringList.add(object.toString());
            }
            return stringList;
        }

        return null;
    }

    static public int getInt(Map map, String key, int defaultValue) {
        Integer value = getInteger(map, key);
        if (value == null) {
            return defaultValue;
        }
        return value;
    }
}
