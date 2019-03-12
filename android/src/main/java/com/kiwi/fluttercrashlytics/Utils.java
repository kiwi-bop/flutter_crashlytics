package com.kiwi.fluttercrashlytics;

import java.util.List;
import java.util.Map;

public class Utils {

    public static FlutterException create(Map<String, Object> exception) {
        final String message = (String) exception.get("message");
        final List<Map<String, Object>> traces = (List<Map<String, Object>>) exception.get("trace");

        final FlutterException flutterException = new FlutterException(message);


        return flutterException;
    }

    StackTraceElement stackTraceElement(Map<String, Object> map) {
        return new StackTraceElement(parseStringOrEmpty(map.get("class")),
                parseStringOrEmpty(map.get("method")),
                (String) map.get("library"),
                (int) map.get("line")
        );
    }

    private String parseStringOrEmpty(Object string) {
        if (string instanceof String) {
            return (String) string;
        }
        return "";
    }


}
