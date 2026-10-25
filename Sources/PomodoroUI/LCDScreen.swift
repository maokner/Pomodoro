import PomodoroCore
import SwiftUI

/// The green LCD: stage, countdown and the cat.
struct LCDScreen: View {
    let stage: String
    let clock: String
    let phase: Phase
    let runningSince: Date?

    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Palette.bezel)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Palette.bezelRim, lineWidth: 1)
            }
            .overlay {
                display
                    .padding(6)
            }
    }

    private var display: some View {
        let shape = RoundedRectangle(cornerRadius: 19, style: .continuous)
        return VStack(spacing: 0) {
            Text(stage)
                .font(.system(size: 13, weight: .regular))
                .tracking(0.6)
                .foregroundStyle(Palette.lcdLabel)
                .padding(.top, 18)
                .lcdShadow()
            Text(clock)
                .font(.system(size: 66, weight: .light))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .foregroundStyle(Palette.lcdInk)
                .lcdShadow()
                .padding(.top, -2)
            Spacer(minLength: 0)
            LCDCat(phase: phase, runningSince: runningSince)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.lcd)
        .overlay { Scanlines() }
        .overlay {
            // Recessed edge: a soft dark rim just inside the glass.
            shape
                .strokeBorder(Color.black.opacity(0.28), lineWidth: 3)
                .blur(radius: 2.5)
        }
        .clipShape(shape)
    }
}

private extension View {
    /// Real LCD segments cast a faint shadow onto the backplate. The pixel cat stays crisp, like the reference.
    func lcdShadow() -> some View {
        shadow(color: Palette.lcdInk.opacity(0.16), radius: 0, x: 1.5, y: 1.5)
    }
}

private struct Scanlines: View {
    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.black.opacity(0.035)))
                y += 2.5
            }
        }
        .allowsHitTesting(false)
    }
}

/// Sleeps during focus, with "z" dots that build up from the moment the timer starts, and sits up during breaks.
/// It holds still while the timer is idle or paused.
private struct LCDCat: View {
    let phase: Phase
    /// When the running phase started; nil while idle or paused.
    let runningSince: Date?

    /// Sized so the cat takes the same share of the device as in the reference design.
    private let pixel: CGFloat = 2.5
    private let headroom = CGFloat(SleepDots.overhang.top.rounded(.up))

    var body: some View {
        Group {
            if let runningSince {
                // Ticks land exactly on the step boundaries, counted from when the timer started.
                TimelineView(.periodic(from: runningSince, by: phase == .focus ? SleepDots.stepDuration : 0.1)) { timeline in
                    canvas(elapsed: timeline.date.timeIntervalSince(runningSince))
                }
            } else {
                canvas(elapsed: nil)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: (CGFloat(CatSprites.sleeping.height) + headroom) * pixel)
        .accessibilityElement()
        .accessibilityLabel(phase == .focus ? "Sleeping cat" : "Cat awake")
    }

    private func canvas(elapsed: TimeInterval?) -> some View {
        let (sprite, dots) = content(elapsed: elapsed)
        return Canvas { context, size in
            // Snap to device pixels (2x) so every square stays crisp.
            func snap(_ value: CGFloat) -> CGFloat { (value * 2).rounded() / 2 }
            let origin = CGPoint(
                x: snap((size.width - CGFloat(sprite.width) * pixel) / 2),
                y: size.height - CGFloat(sprite.height) * pixel
            )
            // One path for the whole cat, so antialiasing leaves no seams between neighbours.
            var cat = Path()
            for (x, y) in sprite.litPixels {
                cat.addRect(CGRect(x: origin.x + CGFloat(x) * pixel, y: origin.y + CGFloat(y) * pixel, width: pixel, height: pixel))
            }
            context.fill(cat, with: .color(Palette.lcdSprite))

            let side = snap(SleepDots.size * pixel)
            for dot in dots {
                let rect = CGRect(
                    x: snap(origin.x + dot.x * pixel - side / 2),
                    y: snap(origin.y + dot.y * pixel - side / 2),
                    width: side,
                    height: side
                )
                context.fill(Path(rect), with: .color(Palette.lcdSprite.opacity(dot.opacity)))
            }
        }
    }

    private func content(elapsed: TimeInterval?) -> (PixelSprite, [SleepDots.Dot]) {
        // A hair past the tick, so a tick that lands exactly on a boundary counts as the new step.
        let elapsed = elapsed.map { $0 + 0.001 }
        switch phase {
        case .focus:
            return (CatSprites.sleeping, elapsed.map(SleepDots.frame) ?? [])
        case .rest:
            guard let elapsed else { return (CatSprites.awake, []) }
            if elapsed.truncatingRemainder(dividingBy: 4.2) < 0.2 {
                return (CatSprites.awakeBlinking, [])
            }
            if elapsed.truncatingRemainder(dividingBy: 2.6) > 2.1 {
                return (CatSprites.awakeTailUp, [])
            }
            return (CatSprites.awake, [])
        }
    }
}
