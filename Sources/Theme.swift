import AppKit
import SwiftUI

enum Theme {
    static let text = Color(red: 0.11, green: 0.12, blue: 0.16)
    static let secondary = Color(red: 0.40, green: 0.43, blue: 0.49)
    static let muted = Color(red: 0.55, green: 0.58, blue: 0.64)
    static let accent = Color(red: 0.20, green: 0.48, blue: 0.96)
    static let accentDeep = Color(red: 0.12, green: 0.34, blue: 0.82)
    static let danger = Color(red: 0.91, green: 0.27, blue: 0.30)
    static let ringTrack = Color(red: 0.78, green: 0.81, blue: 0.86).opacity(0.45)

    static let windowGradient = LinearGradient(
        colors: [
            Color(red: 0.992, green: 0.994, blue: 1.0),
            Color(red: 0.948, green: 0.972, blue: 1.0),
            Color(red: 0.966, green: 0.984, blue: 0.978)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.72),
            Color(red: 0.94, green: 0.97, blue: 1.0).opacity(0.44),
            Color(red: 0.92, green: 0.98, blue: 0.97).opacity(0.32)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sheetGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.86),
            Color(red: 0.94, green: 0.97, blue: 1.0).opacity(0.76),
            Color(red: 0.92, green: 0.98, blue: 0.97).opacity(0.72)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let brandGradient = LinearGradient(
        colors: [
            Color(red: 0.22, green: 0.56, blue: 0.99),
            Color(red: 0.31, green: 0.38, blue: 0.92),
            Color(red: 0.48, green: 0.40, blue: 0.92)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func avatarGradient(for seed: String) -> LinearGradient {
        let palettes: [[Color]] = [
            [Color(red: 0.30, green: 0.56, blue: 0.99), Color(red: 0.24, green: 0.34, blue: 0.90)],
            [Color(red: 0.64, green: 0.47, blue: 0.96), Color(red: 0.43, green: 0.28, blue: 0.86)],
            [Color(red: 0.25, green: 0.72, blue: 0.67), Color(red: 0.14, green: 0.51, blue: 0.56)],
            [Color(red: 0.98, green: 0.62, blue: 0.36), Color(red: 0.91, green: 0.40, blue: 0.30)],
            [Color(red: 0.94, green: 0.50, blue: 0.66), Color(red: 0.79, green: 0.30, blue: 0.55)],
            [Color(red: 0.43, green: 0.68, blue: 0.42), Color(red: 0.23, green: 0.51, blue: 0.33)]
        ]

        var hash = 0
        for scalar in seed.unicodeScalars {
            hash = (hash &* 31 &+ Int(scalar.value)) & 0x7FFF_FFFF
        }
        let colors = palettes[hash % palettes.count]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 1.0, green: 0.84, blue: 0.75).opacity(0.64), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 260
                ))
                .frame(width: 520, height: 520)
                .offset(x: -230, y: -300)
                .blur(radius: 70)

            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 0.82, green: 0.80, blue: 1.0).opacity(0.58), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 240
                ))
                .frame(width: 480, height: 480)
                .offset(x: 250, y: -300)
                .blur(radius: 70)

            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 0.74, green: 0.96, blue: 0.86).opacity(0.52), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 220
                ))
                .frame(width: 450, height: 450)
                .offset(x: -250, y: 300)
                .blur(radius: 70)

            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 0.76, green: 0.87, blue: 1.0).opacity(0.48), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 210
                ))
                .frame(width: 390, height: 390)
                .offset(x: 230, y: 290)
                .blur(radius: 70)
        }
        .allowsHitTesting(false)
    }
}

struct NoiseOverlay: View {
    var body: some View {
        if let url = Bundle.main.url(forResource: "noise", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            GeometryReader { geo in
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(0.045)
                    .blendMode(.multiply)
                    .allowsHitTesting(false)
            }
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Theme.cardGradient)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.64), lineWidth: 1)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color(red: 0.06, green: 0.10, blue: 0.20).opacity(0.13), radius: 16, x: 0, y: 8)
    }
}

struct GlassIconButton: View {
    let systemName: String
    var helpText: String = ""
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Theme.text.opacity(0.72))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.white.opacity(hovering ? 0.58 : 0.32))
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.62), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(helpText)
        .onHover { hovering = $0 }
    }
}

struct AddCircleButton: View {
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(Theme.brandGradient)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.58), lineWidth: 1)
                )
                .shadow(color: Theme.accentDeep.opacity(0.28), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .help("添加账户")
        .onHover { hovering = $0 }
        .scaleEffect(hovering ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.15), value: hovering)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(height: 46)
            .padding(.horizontal, 20)
            .background(
                Capsule()
                    .fill(Theme.brandGradient)
                    .opacity(configuration.isPressed ? 0.84 : 1.0)
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.42), lineWidth: 1)
            )
            .shadow(color: Theme.accentDeep.opacity(0.22), radius: 10, x: 0, y: 5)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .medium))
            .foregroundStyle(Theme.text.opacity(0.78))
            .frame(height: 46)
            .padding(.horizontal, 18)
            .background(
                Capsule()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.48 : 0.30))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
            )
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(height: 42)
            .padding(.horizontal, 18)
            .background(
                Capsule()
                    .fill(Theme.danger.opacity(configuration.isPressed ? 0.82 : 1.0))
            )
    }
}

struct SheetSurface: View {
    var cornerRadius: CGFloat = 32

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.sheetGradient)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.72), lineWidth: 1)
        }
    }
}

struct ToastView: View {
    let message: String
    let error: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: error ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(error ? Theme.danger : Theme.accent)
            Text(message)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Theme.text)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(Color.white.opacity(0.70)))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.06, green: 0.10, blue: 0.20).opacity(0.16), radius: 14, x: 0, y: 6)
    }
}
