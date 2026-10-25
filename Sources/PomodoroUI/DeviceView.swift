import SwiftUI

/// The retro timer device: LCD, two chunky keys, a settings key and a (decorative) speaker grille.
struct DeviceView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 10) {
            LCDScreen(
                stage: model.stageText,
                clock: model.clockText,
                phase: model.phase,
                runningSince: model.engine.runningSince
            )
            .frame(height: 232)

            HStack(spacing: 10) {
                Button(action: model.toggle) {
                    KeyLabel(title: model.isRunning ? "PAUSE" : "START", symbol: model.isRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(DeviceKeyStyle(palette: .red))
                .keyboardShortcut(.space, modifiers: [])
                .accessibilityLabel(model.isRunning ? "Pause" : "Start")

                Button(action: model.reset) {
                    KeyLabel(title: "RESET", symbol: "arrow.clockwise")
                }
                .buttonStyle(DeviceKeyStyle(palette: .graphite))
                .accessibilityLabel("Reset")
            }
            .frame(height: 74)

            HStack(spacing: 12) {
                Button {
                    model.showingSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(DeviceKeyStyle(palette: .graphite, cornerRadius: 9))
                .frame(width: 34, height: 34)
                .keyboardShortcut(",", modifiers: .command)
                .help("Settings")
                .accessibilityLabel("Settings")

                SpeakerGrille(isActive: model.isRunning)
                    .frame(height: 34)
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            let shape = RoundedRectangle(cornerRadius: PanelView.cornerRadius, style: .continuous)
            shape
                .fill(LinearGradient(colors: [Palette.bodyTop, Palette.bodyBottom], startPoint: .top, endPoint: .bottom))
                .overlay {
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.75), .white.opacity(0.1), .black.opacity(0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                }
        }
    }
}

private struct KeyLabel: View {
    let title: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .tracking(0.3)
            Spacer(minLength: 0)
            HStack {
                Spacer(minLength: 0)
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
    }
}

/// A glossy physical key that sinks a little when pressed.
struct DeviceKeyStyle: ButtonStyle {
    let palette: KeyPalette
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        configuration.label
            .foregroundStyle(palette.text)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(shape)
            .background {
                shape
                    .fill(LinearGradient(
                        colors: pressed ? [palette.bottom, palette.bottom] : [palette.top, palette.bottom],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .overlay {
                        // Glossy top lip.
                        shape
                            .inset(by: 1.5)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(pressed ? 0.12 : 0.4), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                ),
                                lineWidth: 1.5
                            )
                    }
                    .overlay { shape.strokeBorder(palette.edge, lineWidth: 1.5) }
            }
            .shadow(color: .black.opacity(pressed ? 0.12 : 0.28), radius: pressed ? 0.5 : 2, y: pressed ? 0.5 : 2)
            .offset(y: pressed ? 1 : 0)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

/// A grid of speaker holes. While the timer runs a few holes shimmer, like the device is humming.
private struct SpeakerGrille: View {
    let isActive: Bool

    private let rows = 4
    private let dot: CGFloat = 4.5
    private let pitch: CGFloat = 8.4

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 3, paused: !isActive)) { timeline in
            let step = Int(timeline.date.timeIntervalSinceReferenceDate * 3)
            Canvas { context, size in
                let columns = Int((size.width - dot) / pitch) + 1
                let usedWidth = CGFloat(columns - 1) * pitch + dot
                let originX = (size.width - usedWidth) / 2
                let originY = (size.height - (CGFloat(rows - 1) * pitch + dot)) / 2
                for row in 0..<rows {
                    for column in 0..<columns {
                        let rect = CGRect(
                            x: originX + CGFloat(column) * pitch,
                            y: originY + CGFloat(row) * pitch,
                            width: dot,
                            height: dot
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(color(row: row, column: column, step: step)))
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func color(row: Int, column: Int, step: Int) -> Color {
        guard isActive else { return Palette.grilleDot }
        var hash = UInt64(truncatingIfNeeded: row &* 73_856_093 ^ column &* 19_349_663 ^ step &* 83_492_791)
        hash = (hash ^ (hash >> 13)) &* 0x5BD1_E995
        switch (hash >> 7) % 100 {
        case 0..<14: return Palette.grilleDotLit
        case 14..<26: return Palette.grilleDotDark
        default: return Palette.grilleDot
        }
    }
}
