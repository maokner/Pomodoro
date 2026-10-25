import Foundation
import Testing
@testable import PomodoroCore

@Suite struct PomodoroEngineTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

    @Test func idleShowsFullFocusDuration() {
        let engine = PomodoroEngine()
        #expect(engine.remainingSeconds(at: t0) == 25 * 60)
        #expect(engine.phase == .focus)
        #expect(!engine.isRunning)
    }

    @Test func countsDownFromAbsoluteEndDate() {
        var engine = PomodoroEngine()
        engine.start(at: t0)
        #expect(engine.isRunning)
        #expect(engine.remainingSeconds(at: t0) == 1500)
        #expect(engine.remainingSeconds(at: t0 + 0.2) == 1500)
        #expect(engine.remainingSeconds(at: t0 + 1) == 1499)
        #expect(engine.remainingSeconds(at: t0 + 1499.5) == 1)
        // A long gap (sleep) doesn't drift: the time left is based on the wall clock.
        #expect(engine.remainingSeconds(at: t0 + 600) == 900)
    }

    @Test func pauseFreezesAndResumeContinues() {
        var engine = PomodoroEngine()
        engine.start(at: t0)
        engine.pause(at: t0 + 100)
        #expect(engine.state == .paused(remaining: 1400))
        #expect(engine.remainingSeconds(at: t0 + 5000) == 1400)
        engine.start(at: t0 + 5000)
        #expect(engine.remainingSeconds(at: t0 + 5010) == 1390)
    }

    @Test func runningSinceAccountsForPauses() {
        var engine = PomodoroEngine()
        #expect(engine.runningSince == nil)
        engine.start(at: t0)
        #expect(engine.runningSince == t0)
        engine.pause(at: t0 + 100)
        #expect(engine.runningSince == nil)
        engine.start(at: t0 + 1000)
        #expect(engine.runningSince == t0 + 900)
    }

    @Test func toggleAlternatesBetweenRunningAndPaused() {
        var engine = PomodoroEngine()
        engine.toggle(at: t0)
        #expect(engine.isRunning)
        engine.toggle(at: t0 + 10)
        #expect(engine.state == .paused(remaining: 1490))
    }

    @Test func finishingFocusQueuesBreakWithoutStartingIt() {
        var engine = PomodoroEngine()
        engine.start(at: t0)
        #expect(engine.completeIfFinished(at: t0 + 1499) == nil)
        #expect(engine.completeIfFinished(at: t0 + 1500) == .focus)
        #expect(engine.phase == .rest)
        #expect(engine.state == .idle)
        #expect(engine.remainingSeconds(at: t0 + 1500) == 5 * 60)
        #expect(engine.completeIfFinished(at: t0 + 9999) == nil)
    }

    @Test func finishingBreakQueuesFocus() {
        var engine = PomodoroEngine(phase: .rest)
        engine.start(at: t0)
        #expect(engine.completeIfFinished(at: t0 + 300) == .rest)
        #expect(engine.phase == .focus)
        #expect(engine.state == .idle)
    }

    @Test func pausedTimerNeverCompletes() {
        var engine = PomodoroEngine()
        engine.start(at: t0)
        engine.pause(at: t0 + 10)
        #expect(engine.completeIfFinished(at: t0 + 10_000) == nil)
    }

    @Test func resetRewindsCurrentPhase() {
        var engine = PomodoroEngine()
        engine.start(at: t0)
        engine.reset()
        #expect(engine.state == .idle)
        #expect(engine.phase == .focus)

        var resting = PomodoroEngine(phase: .rest)
        resting.start(at: t0)
        resting.reset()
        #expect(resting.phase == .rest)
        #expect(resting.state == .idle)
    }

    @Test func resetOnUnstartedBreakSkipsToFocus() {
        var engine = PomodoroEngine(phase: .rest)
        engine.reset()
        #expect(engine.phase == .focus)
    }

    @Test func changingCurrentPhaseLengthRewindsWithNewDuration() {
        var engine = PomodoroEngine()
        engine.start(at: t0)
        let longer = Durations(focusMinutes: 60, restMinutes: 5)
        #expect(engine.wouldRestart(with: longer))
        engine.apply(longer)
        #expect(engine.state == .idle)
        #expect(engine.remainingSeconds(at: t0) == 60 * 60)
    }

    @Test func changingOtherPhaseLengthKeepsTimerRunning() {
        var engine = PomodoroEngine()
        engine.start(at: t0)
        let longerBreak = Durations(focusMinutes: 25, restMinutes: 15)
        #expect(!engine.wouldRestart(with: longerBreak))
        engine.apply(longerBreak)
        #expect(engine.isRunning)
        #expect(engine.remainingSeconds(at: t0 + 60) == 24 * 60)
        #expect(engine.completeIfFinished(at: t0 + 1500) == .focus)
        #expect(engine.remainingSeconds(at: t0 + 1500) == 15 * 60)
    }

    @Test func idleTimerPicksUpNewLengthWithoutRestartWarning() {
        var engine = PomodoroEngine(phase: .rest)
        let durations = Durations(focusMinutes: 120, restMinutes: 30)
        #expect(!engine.wouldRestart(with: durations))
        engine.apply(durations)
        #expect(engine.remainingSeconds(at: t0) == 30 * 60)
    }

    @Test func pausedTimerWarnsBeforeRestart() {
        var engine = PomodoroEngine()
        engine.start(at: t0)
        engine.pause(at: t0 + 30)
        #expect(engine.wouldRestart(with: Durations(focusMinutes: 10, restMinutes: 5)))
    }

    @Test func settingsOptionsIncludeDefaults() {
        #expect(Durations.focusOptions.contains(Durations.standard.focusMinutes))
        #expect(Durations.restOptions.contains(Durations.standard.restMinutes))
    }

    @Test func survivesCodableRoundTrip() throws {
        var engine = PomodoroEngine(durations: Durations(focusMinutes: 90, restMinutes: 15))
        engine.start(at: t0)
        let decoded = try JSONDecoder().decode(PomodoroEngine.self, from: JSONEncoder().encode(engine))
        #expect(decoded == engine)
    }
}

@Suite struct DailyTallyTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    func date(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    @Test func countsWithinADay() {
        var tally = DailyTally()
        #expect(tally.count(on: date(25, 9), calendar: calendar) == 0)
        tally.record(on: date(25, 9), calendar: calendar)
        tally.record(on: date(25, 23), calendar: calendar)
        #expect(tally.count(on: date(25, 23), calendar: calendar) == 2)
    }

    @Test func startsOverOnANewDay() {
        var tally = DailyTally()
        tally.record(on: date(25, 22), calendar: calendar)
        #expect(tally.count(on: date(26, 8), calendar: calendar) == 0)
        tally.record(on: date(26, 8), calendar: calendar)
        #expect(tally.count(on: date(26, 8), calendar: calendar) == 1)
    }
}

@Suite struct PixelSpriteTests {
    @Test func padsShortRows() {
        let sprite = PixelSprite(["#.", "###"])
        #expect(sprite.width == 3)
        #expect(sprite.height == 2)
        #expect(sprite.isLit(x: 0, y: 0))
        #expect(!sprite.isLit(x: 2, y: 0))
        #expect(sprite.isLit(x: 2, y: 1))
        #expect(!sprite.isLit(x: 9, y: 9))
    }

    @Test func catFramesShareASize() {
        for frame in [CatSprites.awakeBlinking, CatSprites.awakeTailUp] {
            #expect(frame.width == CatSprites.awake.width)
            #expect(frame.height == CatSprites.awake.height)
        }
        #expect(CatSprites.sleeping.height == CatSprites.awake.height)
    }
}

@Suite struct SleepDotsTests {
    func opacities(at elapsed: TimeInterval) -> [Double] {
        SleepDots.frame(elapsed: elapsed).map(\.opacity)
    }

    @Test func addsADotEveryHalfSecond() {
        #expect(opacities(at: 0) == [1])
        #expect(opacities(at: 0.49) == [1])
        #expect(opacities(at: 0.5) == [1, 1])
        #expect(opacities(at: 1.2) == [1, 1, 1])
        #expect(opacities(at: 1.7) == [1, 1, 1, 1])
    }

    @Test func fadesAllButTheFirstDotThenRestarts() {
        let faded = SleepDots.fadedOpacity
        #expect(opacities(at: 2.1) == [1, faded, faded, faded])
        #expect(opacities(at: 2.5) == [1])
        #expect(opacities(at: 2.5 * 40 + 0.6) == [1, 1])
    }

    @Test func firstDotNeverMoves() {
        let first = SleepDots.frame(elapsed: 0)[0]
        for elapsed in stride(from: 0.0, to: 5, by: 0.25) {
            #expect(SleepDots.frame(elapsed: elapsed)[0] == first)
        }
    }

    @Test func dotsFloatAboveAndLeftOfTheCat() {
        let overhang = SleepDots.overhang
        #expect(overhang.top > 7 && overhang.top < 9)
        #expect(overhang.left > 1 && overhang.left < 2)
        for dot in SleepDots.frame(elapsed: 2.1) {
            #expect(dot.y < 0)
        }
    }
}
