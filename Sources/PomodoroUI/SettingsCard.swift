import PomodoroCore
import SwiftUI

/// The settings sheet that replaces the device. Changes are drafted and only take effect on Apply.
struct SettingsCard: View {
    @Environment(AppModel.self) private var model

    @State private var focusMinutes = Durations.standard.focusMinutes
    @State private var restMinutes = Durations.standard.restMinutes
    @State private var launchesAtLogin = false

    private var draft: Durations {
        Durations(focusMinutes: focusMinutes, restMinutes: restMinutes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Palette.cardText)
                Spacer()
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.cardText)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close settings")
            }

            SectionLabel("Focus Length")
            MinuteOptions(options: Durations.focusOptions, selection: $focusMinutes)

            SectionLabel("Break Length")
            MinuteOptions(options: Durations.restOptions, selection: $restMinutes)

            if model.engine.wouldRestart(with: draft) {
                Text("Applying restarts the current \(model.phase == .focus ? "session" : "break").")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Palette.cardSecondary)
                    .padding(.top, 10)
            }

            HStack {
                Text("Open at login")
                    .font(.system(size: 13.5))
                    .foregroundStyle(Palette.cardText)
                Spacer()
                Toggle("Open at login", isOn: $launchesAtLogin)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(Palette.selectedFill)
            }
            .padding(.top, 26)

            Spacer(minLength: 18)

            HStack(spacing: 8) {
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Palette.cardSecondary)
                    .keyboardShortcut("q")
                Spacer()
                // Esc is handled by the panel, which closes settings first and then the popup.
                PillButton(title: "CANCEL", isProminent: false, action: close)
                PillButton(title: "APPLY", isProminent: true, action: apply)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.card)
        .onAppear {
            focusMinutes = model.durations.focusMinutes
            restMinutes = model.durations.restMinutes
            launchesAtLogin = model.launchesAtLogin
        }
    }

    private func close() {
        model.showingSettings = false
    }

    private func apply() {
        model.apply(draft)
        if launchesAtLogin != model.launchesAtLogin {
            model.launchesAtLogin = launchesAtLogin
        }
        close()
    }
}

private struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 12.5, weight: .medium))
            .foregroundStyle(Palette.cardSecondary)
            .padding(.top, 22)
            .padding(.bottom, 10)
    }
}

/// A row of round minute buttons, spread edge to edge.
private struct MinuteOptions: View {
    let options: [Int]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element) { index, minutes in
                if index > 0 {
                    Spacer(minLength: 6)
                }
                let isSelected = minutes == selection
                Button {
                    selection = minutes
                } label: {
                    Text("\(minutes)")
                        .font(.system(size: 15))
                        .monospacedDigit()
                        .foregroundStyle(isSelected ? Palette.selectedText : Palette.cardSecondary)
                        .frame(width: 48, height: 48)
                        .background {
                            Circle()
                                .fill(isSelected ? Palette.selectedFill : Palette.chipFill)
                                .overlay { Circle().strokeBorder(isSelected ? .clear : Palette.cardHairline, lineWidth: 1) }
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(minutes) minutes")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

private struct PillButton: View {
    let title: String
    let isProminent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11.5, weight: .medium))
                .tracking(0.3)
                .foregroundStyle(isProminent ? Palette.selectedText : Palette.cardText)
                .padding(.horizontal, 16)
                .frame(height: 30)
                .background {
                    Capsule()
                        .fill(isProminent ? Palette.selectedFill : Palette.chipFill)
                        .overlay { Capsule().strokeBorder(isProminent ? .clear : Palette.cardHairline, lineWidth: 1) }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
