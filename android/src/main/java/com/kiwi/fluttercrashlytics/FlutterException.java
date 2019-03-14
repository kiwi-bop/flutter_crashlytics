package com.kiwi.fluttercrashlytics;

import java.io.Serializable;

class FlutterException extends RuntimeException implements Serializable {

    private String message;

    FlutterException(String message) {
        this.message = message;
    }

    public String getMessage() {
        return message;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        FlutterException that = (FlutterException) o;
        return message.equals(that.message);
    }

    @Override
    public int hashCode() {
        return message.hashCode();
    }
}
