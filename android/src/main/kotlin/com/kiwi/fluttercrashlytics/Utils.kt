package com.kiwi.fluttercrashlytics

object Utils {

    fun create(exception: Map<String, Any>): FlutterException {
        val message = exception["message"] as? String
        val traces = exception["trace"] as? List<Map<String, Any>>

        return FlutterException(message)
                .apply {
                    stackTrace = traces?.map(::stackTraceElement)
                            .orEmpty()
                            .toTypedArray()
                }
    }

    private fun stackTraceElement(map: Map<String, Any>) =
            StackTraceElement(map["class"] as? String ?: "",
                              map["method"] as? String ?: "",
                              map["library"] as? String,
                              map["line"] as? Int?: -1)
}
