import AppKit
import SwiftUI

struct MainView: View {
    @ObservedObject var model: AppModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            Theme.windowGradient
                .ignoresSafeArea()
            AmbientBackground()
                .ignoresSafeArea()
            NoiseOverlay()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                titleRow
                searchArea
                accountsArea
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 22)

            overlays
            toastOverlay
        }
        .frame(minWidth: 480, minHeight: 620)
        .background(Theme.windowGradient)
        .onExitCommand {
            model.closeTopOverlay()
        }
        .onChange(of: model.searchVisible) { visible in
            if visible {
                DispatchQueue.main.async {
                    searchFocused = true
                }
            } else {
                searchFocused = false
            }
        }
        .alert(
            "无法读取账户",
            isPresented: Binding(
                get: { model.loadError != nil },
                set: { if !$0 { model.loadError = nil } }
            )
        ) {
            Button("好", role: .cancel) {
                model.loadError = nil
            }
        } message: {
            Text(model.loadError ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Theme.brandGradient)
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
                Text("R")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: -0.5)
            }
            .frame(width: 28, height: 28)
            .shadow(color: Theme.accentDeep.opacity(0.18), radius: 8, x: 0, y: 4)

            Text("Risetta")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.text)

            Spacer()

            GlassIconButton(systemName: "pin", helpText: "桌面展示") {
                model.pinSheetVisible = true
            }

            GlassIconButton(systemName: "magnifyingglass", helpText: "搜索") {
                model.searchVisible.toggle()
            }

            AddCircleButton {
                model.beginAdd()
            }
        }
        .frame(height: 44)
        .overlay(alignment: .topLeading) {
            Button("") {
                model.beginAdd()
            }
            .keyboardShortcut("n", modifiers: .command)
            .frame(width: 0, height: 0)
            .opacity(0)

            Button("") {
                model.searchVisible.toggle()
            }
            .keyboardShortcut("f", modifiers: .command)
            .frame(width: 0, height: 0)
            .opacity(0)
        }
    }

    private var titleRow: some View {
        HStack {
            Text("验证码")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.text)
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var searchArea: some View {
        if model.searchVisible {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.muted)

                TextField("搜索账户", text: $model.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.text)
                    .focused($searchFocused)

                if !model.searchText.isEmpty {
                    Button {
                        model.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.muted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.48))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.62), lineWidth: 1)
                    )
            )
            .padding(.bottom, 14)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var accountsArea: some View {
        if model.accounts.isEmpty {
            EmptyStateView {
                model.beginAdd()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.filteredAccounts.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.muted)
                Text("没有匹配的账户")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(model.filteredAccounts) { account in
                        AccountCard(model: model, account: account)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private var overlays: some View {
        if model.editor != nil, let draft = model.editor {
            EditorOverlay(
                model: model,
                draft: Binding(
                    get: { model.editor ?? draft },
                    set: { model.editor = $0 }
                )
            )
            .zIndex(20)
        }

        if model.pinSheetVisible {
            PinSheetOverlay(model: model)
                .zIndex(21)
        }

        if let account = model.pendingDelete {
            DeleteConfirmOverlay(model: model, account: account)
                .zIndex(22)
        }
    }

    @ViewBuilder
    private var toastOverlay: some View {
        if let toast = model.toast {
            VStack {
                Spacer()
                ToastView(message: toast, error: model.toastIsError)
                    .padding(.bottom, 24)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .animation(.easeOut(duration: 0.2), value: model.toast)
            .zIndex(30)
        }
    }
}

struct AccountCard: View {
    @ObservedObject var model: AppModel
    let account: Account

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Theme.avatarGradient(for: account.displayIssuer))
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.58), lineWidth: 1)
                Text(account.initial)
                    .font(.system(size: 17.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(account.displayIssuer)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)

                if !account.displayAccount.isEmpty {
                    Text(account.displayAccount)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(model.code(for: account))
                .font(.system(size: 23, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Theme.text)
                .lineLimit(1)

            CountdownRing(
                fraction: model.remainingFraction(for: account),
                seconds: model.remainingSeconds(for: account),
                size: 36
            )

            Menu {
                Button {
                    model.beginEdit(account)
                } label: {
                    Label("编辑账户", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    model.pendingDelete = account
                } label: {
                    Label("删除账户", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 24, height: 28)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
        .padding(.horizontal, 16)
        .frame(height: 72)
        .modifier(GlassCardModifier())
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(hovering ? 0.82 : 0.0), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            model.copy(account)
        }
        .contextMenu {
            Button {
                model.beginEdit(account)
            } label: {
                Label("编辑账户", systemImage: "pencil")
            }

            Button(role: .destructive) {
                model.pendingDelete = account
            } label: {
                Label("删除账户", systemImage: "trash")
            }
        }
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.16), value: hovering)
        .help("点击复制验证码")
    }
}

struct CountdownRing: View {
    let fraction: Double
    let seconds: Int
    var size: CGFloat = 36

    private var color: Color {
        seconds <= 5 ? Theme.danger : Theme.accent
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.ringTrack, lineWidth: 2.5)

            Circle()
                .trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: fraction)

            Text("\(seconds)")
                .font(.system(size: size < 30 ? 9.0 : 9.5, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.muted)
                .monospacedDigit()
        }
        .frame(width: size, height: size)
    }
}

struct EmptyStateView: View {
    let addAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(Theme.brandGradient)
                    .opacity(0.16)
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.70), lineWidth: 1)
                Image(systemName: "key.horizontal.fill")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }
            .frame(width: 74, height: 74)
            .shadow(color: Theme.accentDeep.opacity(0.12), radius: 14, x: 0, y: 7)

            Text("还没有账户")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.text)
                .padding(.top, 20)

            Text("添加后，验证码会实时显示在这里。")
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 7)

            Button(action: addAction) {
                Label("添加账户", systemImage: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 42)
                    .background(Capsule().fill(Theme.brandGradient))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.40), lineWidth: 1))
                    .shadow(color: Theme.accentDeep.opacity(0.20), radius: 9, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
        }
    }
}
