package app.aura.story

import app.aura.story.bridge.AuraLiteRtBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AuraLiteRtBridge(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }
}
