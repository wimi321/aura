import Foundation
import AuraLiteRTNative
import XCTest

class RunnerTests: XCTestCase {
  func testLiteRTNativeEngineStartsWithoutBundledModel() throws {
    let engine = AURLiteRTNativeEngine()
    engine.configure(
      withPrimaryDelegate: "cpu",
      fallbackDelegates: ["cpu"],
      maxContextTokensOverride: NSNumber(value: 1024),
    )

    let runtimeStatus = engine.runtimeStatus()
    XCTAssertEqual(runtimeStatus["runtime"] as? String, "litert-lm")
    XCTAssertNil(runtimeStatus["loadedModelId"])
    XCTAssertFalse(hasBundledModelAsset(), "The app bundle should not ship a LiteRT-LM model anymore.")
  }

  private func hasBundledModelAsset() -> Bool {
    let candidateURLs: [URL?] = [
      Bundle.main.privateFrameworksURL?
        .appendingPathComponent("App.framework")
        .appendingPathComponent("flutter_assets")
        .appendingPathComponent("assets")
        .appendingPathComponent("models")
        .appendingPathComponent("gemma-4-E2B-it.litertlm"),
      Bundle.main.bundleURL
        .appendingPathComponent("Frameworks")
        .appendingPathComponent("App.framework")
        .appendingPathComponent("flutter_assets")
        .appendingPathComponent("assets")
        .appendingPathComponent("models")
        .appendingPathComponent("gemma-4-E2B-it.litertlm"),
    ]

    for case let url? in candidateURLs where FileManager.default.fileExists(atPath: url.path) {
      return true
    }
    return false
  }
}
