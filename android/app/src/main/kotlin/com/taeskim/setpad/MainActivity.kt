package com.taeskim.setpad

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// Health Connect 의 권한 요청은 registerForActivityResult 를 쓴다. 그것을
// 부르려면 Activity 가 ComponentActivity 여야 해서 FlutterActivity 로는 안 된다.
class MainActivity : FlutterFragmentActivity() {
    private var localAi: LocalAiBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        localAi = LocalAiBridge(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        localAi?.close()
        localAi = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
