package com.kiwi.fluttercrashlytics

object Utils {
    fun createException(exception: Map<String, Any>): FlutterException {
        val cause = exception["cause"] as? String
        val message = exception["message"] as? String
        val traces = exception["trace"] as? List<List<Any>>
        val stack: MutableList<StackTraceElement> = mutableListOf()

        traces?.forEach {
            stack.add(StackTraceElement(it[0] as? String ?: "", it[1] as? String
                    ?: "", it[2] as? String ?: "", it[3] as Int))
        }
        val throwable = FlutterException("$message\n$cause")
        throwable.stackTrace = stack.toTypedArray()
        return throwable
    }

    fun create(exception: Map<String, Any>): FlutterException {
        val message = exception["message"] as? String
        val traces = exception["trace"] as? List<Map<String, Any>>

        return FlutterException("$message")
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
                              map["line"] as Int)
}
