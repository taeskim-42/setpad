package com.taeskim.setpad

import io.flutter.embedding.android.FlutterFragmentActivity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Health Connect 의 권한 요청은 registerForActivityResult 를 쓴다. 그것을
// 부르려면 Activity 가 ComponentActivity 여야 해서 FlutterActivity 로는 안 된다.
class MainActivity : FlutterFragmentActivity() {
    private var timing: TimingBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        timing = TimingBridge(this, flutterEngine.dartExecutor.binaryMessenger)

        // 공유 시트. 글 한 줄(공동 루틴 초대 링크)을 올리는 것이 전부라 플러그인 없이 둔다.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "setpad/share")
            .setMethodCallHandler { call, result ->
                val text = call.argument<String>("text")
                if (call.method != "share" || text == null) return@setMethodCallHandler result.success(false)
                val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
                startActivity(Intent.createChooser(send, null))
                result.success(true)
            }
    }

    override fun onPause() { timing?.interrupt(); super.onPause() }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        timing?.close(); timing = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
