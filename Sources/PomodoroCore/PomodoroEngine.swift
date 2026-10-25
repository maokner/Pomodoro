import Foundation

public enum Phase: String, Codable, Sendable {
    case focus
    case rest

    public var next: Phase { self == .focus ? .rest : .focus }
}

/// How long focus and break last. The options match the settings card.
public struct Durations: Codable, Equatable, Sendable {
    public static let focusOptions = [10, 25, 60, 90, 120]
    public static let restOptions = [5, 10, 15, 30, 60]
    public static let standard = Durations(focusMinutes: 25, restMinutes: 5)

    public var focusMinutes: Int
    public var restMinutes: Int

    public init(focusMinutes: Int, restMinutes: Int) {
        self.focusMinutes = focusMinutes
        self.restMinutes = restMinutes
    }

    public func minutes(of phase: Phase) -> Int {
        phase == .focus ? focusMinutes : restMinutes
    }

    public func duration(of phase: Phase) -> TimeInterval {
        TimeInterval(minutes(of: phase) * 60)
    }
}

public enum RunState: Codable, Equatable, Sendable {
    case idle
    case running(endsAt: Date)
    case paused(remaining: TimeInterval)
}

/// The pomodoro state machine. It stores an absolute end date while running,
/// so the countdown stays correct across sleep, app restarts and missed ticks.
public struct PomodoroEngine: Codable, Equatable, Sendable {
    public private(set) var durations: Durations
    public private(set) var phase: Phase
    public private(set) var state: RunState

    public init(durations: Durations = .standard, phase: Phase = .focus, state: RunState = .idle) {
        self.durations = durations
        self.phase = phase
        self.state = state
    }

    public var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    /// When the running phase would have started had it never been paused. Nil unless running.
    public var runningSince: Date? {
        guard case .running(let endsAt) = state else { return nil }
        return endsAt - durations.duration(of: phase)
    }

    public func remaining(at now: Date) -> TimeInterval {
        switch state {
        case .idle: durations.duration(of: phase)
        case .running(let endsAt): max(0, endsAt.timeIntervalSince(now))
        case .paused(let remaining): remaining
        }
    }

    /// Whole seconds left, rounded up so a fresh timer reads 25:00 and the last second reads 00:01.
    public func remainingSeconds(at now: Date) -> Int {
        Int(remaining(at: now).rounded(.up))
    }

    public mutating func start(at now: Date) {
        switch state {
        case .idle: state = .running(endsAt: now + durations.duration(of: phase))
        case .paused(let remaining): state = .running(endsAt: now + remaining)
        case .running: break
        }
    }

    public mutating func pause(at now: Date) {
        guard isRunning else { return }
        state = .paused(remaining: remaining(at: now))
    }

    public mutating func toggle(at now: Date) {
        if isRunning {
            pause(at: now)
        } else {
            start(at: now)
        }
    }

    /// Rewinds the current phase. Resetting a break that hasn't started skips it and goes back to focus.
    public mutating func reset() {
        if state == .idle && phase == .rest {
            phase = .focus
        }
        state = .idle
    }

    /// Moves to the next phase once the running one has ended. The next phase waits for `start`.
    /// Returns the phase that just finished.
    @discardableResult
    public mutating func completeIfFinished(at now: Date) -> Phase? {
        guard case .running(let endsAt) = state, now >= endsAt else { return nil }
        let finished = phase
        phase = phase.next
        state = .idle
        return finished
    }

    /// New lengths apply right away. If the length of the current phase changed, that phase rewinds
    /// so it picks up the new duration; changing only the other phase leaves the timer alone.
    public mutating func apply(_ durations: Durations) {
        guard durations != self.durations else { return }
        let currentChanged = durations.minutes(of: phase) != self.durations.minutes(of: phase)
        self.durations = durations
        if currentChanged {
            state = .idle
        }
    }

    /// Whether applying `durations` would rewind a session that is running or paused.
    public func wouldRestart(with durations: Durations) -> Bool {
        state != .idle && durations.minutes(of: phase) != self.durations.minutes(of: phase)
    }
}

/// Counts completed focus sessions for the current calendar day.
public struct DailyTally: Codable, Equatable, Sendable {
    public private(set) var day: Date
    public private(set) var completed: Int

    public init(day: Date = .distantPast, completed: Int = 0) {
        self.day = day
        self.completed = completed
    }

    public func count(on date: Date, calendar: Calendar = .current) -> Int {
        calendar.isDate(day, inSameDayAs: date) ? completed : 0
    }

    public mutating func record(on date: Date, calendar: Calendar = .current) {
        completed = count(on: date, calendar: calendar) + 1
        day = calendar.startOfDay(for: date)
    }
}
