package com.kiwi.fluttercrashlytics

import android.app.Activity
import android.os.Bundle
import com.crashlytics.android.Crashlytics
import io.fabric.sdk.android.Fabric

class CrashActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out)
        super.onCreate(savedInstanceState)
        Fabric.with(this, Crashlytics())

        throw intent.getSerializableExtra("exception") as Throwable
    }
}
