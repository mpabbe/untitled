package com.example.untitled

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("7ffdb2f7-797e-4648-9572-914fad616516")
    }
}
