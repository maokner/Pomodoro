import AppKit
import PomodoroUI
import SwiftUI

@main
struct PomodoroApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    // Everything lives in the status item; SwiftUI just needs a scene to exist.
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = StatusItemController(model: AppModel())
    }
}
