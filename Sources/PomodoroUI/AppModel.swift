import AppKit
import Observation
import PomodoroCore
import ServiceManagement

@MainActor
@Observable
public final class AppModel {
    private(set) var engine: PomodoroEngine {
        didSet { save(engine, forKey: Keys.engine) }
    }

    private(set) var tally: DailyTally {
        didSet { save(tally, forKey: Keys.tally) }
    }

    /// Whole seconds left in the current phase. Only written when it changes, so views redraw once a second.
    private(set) var secondsLeft: Int

    public var showingSettings = false

    /// Nil when the model shouldn't persist or notify (offscreen snapshots).
    @ObservationIgnored private let defaults: UserDefaults?
    @ObservationIgnored private let notifier: Notifier?
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private var wakeObserver: NSObjectProtocol?

    /// The app's model: restores saved state and posts notifications.
    public convenience init() {
        let defaults = UserDefaults.standard
        self.init(
            engine: Self.load(PomodoroEngine.self, forKey: Keys.engine, from: defaults) ?? PomodoroEngine(),
            tally: Self.load(DailyTally.self, forKey: Keys.tally, from: defaults) ?? DailyTally(),
            defaults: defaults,
            notifier: Notifier()
        )
    }

    /// A model that neither persists nor notifies, for rendering specific states offscreen.
    public convenience init(engine: PomodoroEngine, tally: DailyTally, showingSettings: Bool = false) {
        self.init(engine: engine, tally: tally, defaults: nil, notifier: nil)
        self.showingSettings = showingSettings
    }

    private init(engine: PomodoroEngine, tally: DailyTally, defaults: UserDefaults?, notifier: Notifier?) {
        self.engine = engine
        self.tally = tally
        self.defaults = defaults
        self.notifier = notifier
        secondsLeft = 0

        notifier?.requestAuthorization()
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        // A phase that ran out while the app was closed still counts, but doesn't notify.
        tick(announce: false)
    }

    // MARK: Derived state

    var isRunning: Bool { engine.isRunning }
    var phase: Phase { engine.phase }
    var durations: Durations { engine.durations }

    var isPaused: Bool {
        if case .paused = engine.state { return true }
        return false
    }

    public var clockText: String {
        String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60)
    }

    var sessionNumber: Int { tally.count(on: .now) + 1 }

    var stageText: String {
        switch engine.phase {
        case .focus: "SESSION \(sessionNumber)"
        case .rest: "BREAK"
        }
    }

    var launchesAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("Pomodoro: couldn't update login item: \(error)")
            }
        }
    }

    // MARK: Actions

    func toggle() {
        engine.toggle(at: .now)
        tick()
    }

    func reset() {
        engine.reset()
        tick()
    }

    func apply(_ durations: Durations) {
        engine.apply(durations)
        tick()
    }

    // MARK: Ticking

    private func tick(announce: Bool = true) {
        let now = Date.now
        if let finished = engine.completeIfFinished(at: now) {
            if finished == .focus {
                tally.record(on: now)
            }
            if announce {
                announceEnd(of: finished)
            }
        }
        let seconds = engine.remainingSeconds(at: now)
        if seconds != secondsLeft {
            secondsLeft = seconds
        }
        updateTicker()
    }

    /// Ticks a few times a second only while running, so the display flips close to the real second boundary.
    private func updateTicker() {
        if engine.isRunning, ticker == nil {
            let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.tick() }
            }
            timer.tolerance = 0.05
            RunLoop.main.add(timer, forMode: .common)
            ticker = timer
        } else if !engine.isRunning, let timer = ticker {
            timer.invalidate()
            ticker = nil
        }
    }

    private func announceEnd(of finished: Phase) {
        switch finished {
        case .focus:
            notifier?.post(
                title: "Focus session done",
                body: "Time for a \(engine.durations.restMinutes) minute break. Start it when you're ready."
            )
        case .rest:
            notifier?.post(title: "Break's over", body: "Ready for session \(sessionNumber)?")
        }
    }

    // MARK: Persistence

    private enum Keys {
        static let engine = "engine"
        static let tally = "tally"
    }

    private func save(_ value: some Encodable, forKey key: String) {
        defaults?.set(try? JSONEncoder().encode(value), forKey: key)
    }

    private static func load<T: Decodable>(_ type: T.Type, forKey key: String, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
