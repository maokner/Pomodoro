import AppKit
import PomodoroCore
import PomodoroUI
import SwiftUI

// Renders the popup in each interesting state to PNGs, so the UI can be checked without clicking through it.
// Usage: snapshot <output-dir>
// It captures via an offscreen NSHostingView (unlike ImageRenderer, that includes AppKit controls such as switches).
// That capture path can leave faint vertical hairlines at the ends of capsules; they are not in the real app.

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: snapshot <output-dir>\n".utf8))
    exit(64)
}
let output = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
_ = NSApplication.shared

var oneDone = DailyTally()
oneDone.record(on: .now)

// States are built right before each render, so timers that just started land in the intended animation step.
func running(_ engine: PomodoroEngine, startedAgo seconds: TimeInterval) -> () -> PomodoroEngine {
    {
        var engine = engine
        engine.start(at: .now - seconds)
        return engine
    }
}

func paused(_ engine: PomodoroEngine, after seconds: TimeInterval) -> () -> PomodoroEngine {
    {
        var engine = running(engine, startedAgo: seconds)()
        engine.pause(at: .now)
        return engine
    }
}

let long = Durations(focusMinutes: 120, restMinutes: 30)
var states: [(name: String, engine: () -> PomodoroEngine, tally: DailyTally, settings: Bool)] = [
    ("focus-idle", { PomodoroEngine() }, DailyTally(), false),
    ("focus-paused", paused(PomodoroEngine(), after: 754), DailyTally(), false),
    ("break-idle", { PomodoroEngine(phase: .rest) }, oneDone, false),
    ("break-running", running(PomodoroEngine(phase: .rest), startedAgo: 9.5), oneDone, false),
    ("focus-120-running", running(PomodoroEngine(durations: long), startedAgo: 3.6), oneDone, false),
    ("settings", running(PomodoroEngine(), startedAgo: 47), DailyTally(), true),
]
// One render per step of the z-dot cycle, a little after each step begins.
for step in 0..<5 {
    states.append(("focus-running-dots\(step + 1)", running(PomodoroEngine(), startedAgo: Double(step) * 0.5 + 0.1), DailyTally(), false))
}

for appearance in [NSAppearance.Name.aqua, .darkAqua] {
    for state in states {
        let model = AppModel(engine: state.engine(), tally: state.tally, showingSettings: state.settings)
        let host = NSHostingView(rootView: PanelView().environment(model))
        host.frame = NSRect(origin: .zero, size: PanelView.size)
        let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.appearance = NSAppearance(named: appearance)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: .now + 0.15)

        let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
        host.cacheDisplay(in: host.bounds, to: rep)
        let suffix = appearance == .darkAqua ? "-dark" : ""
        try rep.representation(using: .png, properties: [:])!
            .write(to: output.appendingPathComponent("\(state.name)\(suffix).png"))
    }
}
print("Wrote \(states.count * 2) snapshots to \(output.path)")
