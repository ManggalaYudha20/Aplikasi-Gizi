package com.example.aplikasi_diagnosa_gizi

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode // 1. Tambahkan import ini

class MainActivity: FlutterActivity() {
    // 2. Tambahkan override function ini
    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }
}