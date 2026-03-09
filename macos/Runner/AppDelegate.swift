import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private static let channelName = "wattalizer/file_intents"
  private var channel: FlutterMethodChannel?
  private var pendingFilePath: String?
  private var isInitialLaunchHandled = false

  override func applicationDidFinishLaunching(_ notification: Notification) {
    guard
      let flutterVC = NSApp.windows.first?.contentViewController
        as? FlutterViewController
    else { return }

    let ch = FlutterMethodChannel(
      name: AppDelegate.channelName,
      binaryMessenger: flutterVC.engine.binaryMessenger
    )
    channel = ch
    ch.setMethodCallHandler { [weak self] call, result in
      if call.method == "getPendingFile" {
        result(self?.pendingFilePath)
        self?.pendingFilePath = nil
        self?.isInitialLaunchHandled = true
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func application(
    _ sender: NSApplication, open urls: [URL]
  ) {
    guard let url = urls.first,
          let path = resolveFilePath(url) else { return }
    if isInitialLaunchHandled {
      channel?.invokeMethod("openFile", arguments: path)
    } else {
      pendingFilePath = path
    }
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

  override func applicationShouldTerminateAfterLastWindowClosed(
    _ sender: NSApplication
  ) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(
    _ app: NSApplication
  ) -> Bool {
    return true
  }
}
