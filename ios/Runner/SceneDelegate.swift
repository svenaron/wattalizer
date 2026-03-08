import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private static let channelName = "wattalizer/file_intents"
  private var channel: FlutterMethodChannel?
  private var pendingFilePath: String?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard
      let windowScene = scene as? UIWindowScene,
      let flutterVC = windowScene.windows.first?.rootViewController
        as? FlutterViewController
    else { return }

    let ch = FlutterMethodChannel(
      name: SceneDelegate.channelName,
      binaryMessenger: flutterVC.binaryMessenger
    )
    self.channel = ch

    ch.setMethodCallHandler { [weak self] call, result in
      if call.method == "getPendingFile" {
        result(self?.pendingFilePath)
        self?.pendingFilePath = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    if let url = connectionOptions.urlContexts.first?.url {
      pendingFilePath = resolveFilePath(url)
    }
  }

  override func scene(
    _ scene: UIScene,
    openURLContexts urlContexts: Set<UIOpenURLContext>
  ) {
    guard
      let url = urlContexts.first?.url,
      let path = resolveFilePath(url)
    else { return }
    channel?.invokeMethod("openFile", arguments: path)
  }

  private func resolveFilePath(_ url: URL) -> String? {
    let accessing = url.startAccessingSecurityScopedResource()
    defer {
      if accessing { url.stopAccessingSecurityScopedResource() }
    }
    let dest = FileManager.default.temporaryDirectory
      .appendingPathComponent(url.lastPathComponent)
    do {
      if FileManager.default.fileExists(atPath: dest.path) {
        try FileManager.default.removeItem(at: dest)
      }
      try FileManager.default.copyItem(at: url, to: dest)
      return dest.path
    } catch {
      return nil
    }
  }
}
