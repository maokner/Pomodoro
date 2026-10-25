import AppKit
import Observation
import PomodoroUI
import SwiftUI

/// Owns the menu bar item (just the time) and the borderless popup that shows the device under it.
@MainActor
final class StatusItemController: NSObject {
    private let model: AppModel
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let panel: PopupPanel
    private var clickMonitor: Any?
    private var keyMonitor: Any?

    init(model: AppModel) {
        self.model = model
        panel = PopupPanel(content: PanelView().environment(model), size: PanelView.size)
        super.init()

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updateTitle()
    }

    /// Re-renders the menu bar title whenever the clock text changes.
    private func updateTitle() {
        let text = withObservationTracking {
            model.clockText
        } onChange: { [weak self] in
            Task { @MainActor in self?.updateTitle() }
        }
        // Tabular digits keep the item from changing width every second.
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.menuBarFont(ofSize: 0).pointSize, weight: .regular)
        statusItem.button?.attributedTitle = NSAttributedString(string: text, attributes: [.font: font])
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else if panel.isVisible {
            closePanel()
        } else {
            openPanel()
        }
    }

    private func showMenu() {
        closePanel()
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Pomodoro", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openSettings() {
        model.showingSettings = true
        openPanel()
    }

    private func openPanel() {
        guard let button = statusItem.button, let buttonWindow = button.window else { return }
        let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let screen = buttonWindow.screen ?? NSScreen.main
        var origin = NSPoint(x: anchor.midX - PanelView.size.width / 2, y: anchor.minY - 6 - PanelView.size.height)
        if let visible = screen?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX + 8), visible.maxX - PanelView.size.width - 8)
        }
        panel.setFrameOrigin(origin)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 1
        }
        button.highlight(true)

        // Clicks in other apps close the popup, like a menu.
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated { self?.closePanel() }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            MainActor.assumeIsolated { self?.escapePressed() }
            return nil
        }
    }

    private func closePanel() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        statusItem.button?.highlight(false)
        model.showingSettings = false
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
        }
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        clickMonitor = nil
        keyMonitor = nil
    }

    /// Esc backs out of settings first, then closes the popup.
    private func escapePressed() {
        if model.showingSettings {
            model.showingSettings = false
        } else {
            closePanel()
        }
    }
}

/// A transparent, borderless panel. The SwiftUI content draws the device's rounded outline and the window
/// server derives the drop shadow from it, so the popup is just the device floating under the menu bar.
private final class PopupPanel: NSPanel {
    init(content: some View, size: CGSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isReleasedWhenClosed = false
        hidesOnDeactivate = false

        let hosting = NSHostingView(rootView: content)
        hosting.frame = NSRect(origin: .zero, size: size)
        contentView = hosting
    }

    // Borderless panels refuse key status by default; the device needs it for Space and Esc.
    override var canBecomeKey: Bool { true }
}
