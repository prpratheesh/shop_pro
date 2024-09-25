package com.archer.example.shop_pro

import android.os.Bundle
import android.view.KeyEvent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val CHANNEL = "nativeScanner"
    private lateinit var channel: MethodChannel

    private var latestBarcode: String = ""
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.getDefault())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (!::channel.isInitialized) {
            channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        val inputChar = event.unicodeChar.toChar()

        // Log the key event for debugging
        Log.d("KEY_EVENT", "onKeyDown - KeyCode: $keyCode, Char: $inputChar")

        if (keyCode in KeyEvent.KEYCODE_0..KeyEvent.KEYCODE_9 || keyCode == KeyEvent.KEYCODE_DEL) {
            if (inputChar.isDigit()) {
                latestBarcode += inputChar
                return true
            } else if (keyCode == KeyEvent.KEYCODE_DEL && latestBarcode.isNotEmpty()) {
                latestBarcode = latestBarcode.dropLast(1)
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean {
        val currentTime = System.currentTimeMillis()
        val formattedTime = dateFormat.format(currentTime)

        // Log the key event for debugging
//        Log.d("KEY_EVENT", "onKeyUp - KeyCode: $keyCode, Time: $formattedTime")

        if (keyCode == KeyEvent.KEYCODE_ENTER) {
            Log.d("BARCODE", "ONKEYUP TRIGGERED AT $formattedTime. BARCODE: $latestBarcode")
            Log.d("BARCODE", "SENDING BARCODE TO FLUTTER.")
            channel.invokeMethod("onBarcodeScanned", latestBarcode)
            latestBarcode = ""
            return true
        }
        return super.onKeyUp(keyCode, event)
    }
}


