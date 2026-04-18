import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    let registrar = flutterViewController.registrar(forPlugin: "AuraLiteRTBridge")
    let bridge = AuraLiteRTBridge()
    bridge.register(with: registrar.messenger)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
