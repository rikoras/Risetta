import SwiftUI

struct PinSheetOverlay: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.13)
                .ignoresSafeArea()
                .onTapGesture {
                    model.pinSheetVisible = false
                }

            VStack {
                Spacer()
                pinSheet
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .transition(.opacity)
    }

    private var pinSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color(red: 0.80, green: 0.81, blue: 0.84))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 17)

            HStack {
                Text("桌面展示")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.text)

                Spacer()

                Button {
                    model.pinSheetVisible = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.secondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.white.opacity(0.34)))
                }
                .buttonStyle(.plain)
                .help("关闭")
            }
            .padding(.bottom, 8)

            Text("选择要显示的账户")
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.secondary)
                .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(model.accounts) { account in
                        PinOptionRow(
                            account: account,
                            isSelected: Binding(
                                get: { model.selectedIDs.contains(account.id) },
                                set: { model.setSelected(account.id, selected: $0) }
                            )
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 286)
            .scrollIndicators(.hidden)

            HStack {
                if model.selectedIDs.isEmpty {
                    Text("至少选择一个账户")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.danger)
                }

                Spacer()

                Button("取消") {
                    model.pinSheetVisible = false
                }
                .buttonStyle(GhostButtonStyle())
                .frame(width: 86)
                .keyboardShortcut(.cancelAction)

                Button {
                    model.confirmPin()
                } label: {
                    Label("显示到桌面", systemImage: "pin")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .frame(height: 46)
                        .background(Capsule().fill(Theme.brandGradient))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.40), lineWidth: 1))
                        .shadow(color: Theme.accentDeep.opacity(0.22), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                .disabled(model.selectedIDs.isEmpty)
                .opacity(model.selectedIDs.isEmpty ? 0.48 : 1.0)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 16)
        }
        .padding(24)
        .background(SheetSurface())
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Color(red: 0.06, green: 0.10, blue: 0.20).opacity(0.24), radius: 35, x: 0, y: 16)
    }
}

struct PinOptionRow: View {
    let account: Account
    @Binding var isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Theme.avatarGradient(for: account.displayIssuer))
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.56), lineWidth: 1)
                Text(account.initial)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(account.displayIssuer)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)

                if !account.displayAccount.isEmpty {
                    Text(account.displayAccount)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: $isSelected)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(Theme.accent)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(isSelected ? 0.46 : 0.26))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(isSelected ? 0.68 : 0.40), lineWidth: 1)
        )
    }
}
