import SwiftUI

/// The whole popup: the device, or the settings card in its place. Both share one size and outline,
/// so the borderless window around them never changes shape.
public struct PanelView: View {
    public static let size = CGSize(width: 332, height: 388)
    static let cornerRadius: CGFloat = 32

    @Environment(AppModel.self) private var model

    public init() {}

    public var body: some View {
        ZStack {
            if model.showingSettings {
                SettingsCard()
                    .transition(.opacity)
            } else {
                DeviceView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: model.showingSettings)
        .frame(width: Self.size.width, height: Self.size.height)
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }
}
