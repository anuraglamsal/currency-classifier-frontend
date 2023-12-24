package com.example.proj

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import android.view.KeyEvent

class MainActivity: FlutterActivity() {
private lateinit var channel : MethodChannel;

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mychannel")
    }

    // using platform-specific events
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_DOWN -> channel.invokeMethod("volumeBtnPressed", "volume_down")
            KeyEvent.KEYCODE_VOLUME_UP -> channel.invokeMethod("volumeBtnPressed", "volume_up")
        }
        // return true means "prevent default behavior", so volume doesn't change and volume bar doesn't appear
        return true
    }
}
