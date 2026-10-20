import AppKit
import SwiftUI

struct PinWidgetView: View {
    @ObservedObject var model: AppModel
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear

            VStack(spacing: 0) {
                card
            }
            .padding(18)

            if let toast = model.toast {
                ToastView(message: toast, error: model.toastIsError)
                    .padding(.bottom, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.2), value: model.toast)
            }
        }
        .frame(width: 340)
        .background(Color.clear)
    }

    private var card: some View {
        ZStack {
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.80),
                            Color(red: 0.94, green: 0.98, blue: 1.0).opacity(0.58),
                            Color(red: 0.92, green: 0.98, blue: 0.97).opacity(0.62)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.74), lineWidth: 1)

            NoiseOverlay()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .opacity(0.8)

            VStack(spacing: 0) {
                dragBar

                if model.selectedAccounts.isEmpty {
                    Text("没有可显示的账户")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(model.selectedAccounts) { account in
                                PinWidgetRow(model: model, account: account)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                    .frame(maxHeight: 372)
                    .scrollIndicators(.hidden)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(red: 0.05, green: 0.09, blue: 0.18).opacity(0.28), radius: 24, x: 0, y: 12)
    }

    private var dragBar: some View {
        ZStack {
            HStack {
                Spacer()

                Capsule()
                    .fill(Color.white.opacity(0.50))
                    .frame(width: 30, height: 4)

                Spacer()
            }

            HStack {
                Spacer()
                WindowDragHandle()
                    .frame(width: 180, height: 28)
                Spacer()
            }

            HStack {
                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.secondary.opacity(0.82))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.white.opacity(0.28)))
                }
                .buttonStyle(.plain)
                .help("返回应用")
            }
        }
        .frame(height: 28)
        .padding(.horizontal, 6)
    }
}

private final class WindowDragView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        WindowDragView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct PinWidgetRow: View {
    @ObservedObject var model: AppModel
    let account: Account

    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.avatarGradient(for: account.displayIssuer))
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.56), lineWidth: 1)
                Text(account.initial)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayIssuer)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)

                if !account.displayAccount.isEmpty {
                    Text(account.displayAccount)
                        .font(.system(size: 9.5))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(model.code(for: account))
                .font(.system(size: 19, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Theme.text)
                .lineLimit(1)

            CountdownRing(
                fraction: model.remainingFraction(for: account),
                seconds: model.remainingSeconds(for: account),
                size: 28
            )
            .padding(.leading, 2)
        }
        .padding(.horizontal, 8)
        .frame(height: 58)
        .contentShape(Rectangle())
        .onTapGesture {
            model.copy(account)
        }
        .help("点击复制验证码")
    }
}
