import SwiftUI

struct EditorOverlay: View {
    @ObservedObject var model: AppModel
    @Binding var draft: EditorState

    @FocusState private var issuerFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.13)
                .ignoresSafeArea()
                .onTapGesture {
                    model.editor = nil
                }

            VStack {
                Spacer()
                editorSheet
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .transition(.opacity)
    }

    private var editorSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color(red: 0.80, green: 0.81, blue: 0.84))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 17)

            HStack {
                Text(draft.mode == .add ? "添加账户" : "编辑账户")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.text)

                Spacer()

                Button {
                    model.editor = nil
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
            .padding(.bottom, 18)

            fieldLabel("名称")
            TextField("例如 GitHub", text: $draft.issuer)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Theme.text)
                .focused($issuerFocused)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(inputBackground)
                .padding(.bottom, 12)

            fieldLabel("账户")
            TextField("例如 you@example.com", text: $draft.accountName)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(inputBackground)
                .padding(.bottom, 12)

            fieldLabel("密钥")
            HStack(spacing: 8) {
                Group {
                    if draft.revealSecret {
                        TextField("粘贴密钥或链接", text: $draft.secret)
                    } else {
                        SecureField("粘贴密钥或链接", text: $draft.secret)
                    }
                }
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: draft.revealSecret ? .default : .monospaced))
                .foregroundStyle(Theme.text)

                Button {
                    draft.revealSecret.toggle()
                } label: {
                    Image(systemName: draft.revealSecret ? "eye.slash" : "eye")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.secondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help(draft.revealSecret ? "隐藏密钥" : "显示密钥")
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(inputBackground)

            if let error = draft.error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.danger)
                    .padding(.top, 9)
            }

            HStack(spacing: 8) {
                if draft.mode == .edit {
                    Button("删除账户", role: .destructive) {
                        model.requestDeleteEditing()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(Theme.danger)
                }

                Spacer()

                Button("取消") {
                    model.editor = nil
                }
                .buttonStyle(GhostButtonStyle())
                .keyboardShortcut(.cancelAction)

                Button(draft.mode == .add ? "添加" : "保存") {
                    model.saveEditor()
                }
                .buttonStyle(PrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 18)
        }
        .padding(24)
        .background(SheetSurface())
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Color(red: 0.06, green: 0.10, blue: 0.20).opacity(0.24), radius: 35, x: 0, y: 16)
        .onAppear {
            issuerFocused = true
        }
        .onChange(of: draft.secret) { value in
            guard let parsed = OtpAuthParser.parse(value) else {
                return
            }

            if draft.issuer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let issuer = parsed.issuer {
                draft.issuer = issuer
            }

            if draft.accountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let accountName = parsed.accountName {
                draft.accountName = accountName
            }
        }
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.48))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.62), lineWidth: 1)
            )
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(Theme.secondary)
            .padding(.bottom, 7)
    }
}

struct DeleteConfirmOverlay: View {
    @ObservedObject var model: AppModel
    let account: Account

    var body: some View {
        ZStack {
            Color.black.opacity(0.16)
                .ignoresSafeArea()
                .onTapGesture {
                    model.pendingDelete = nil
                }

            VStack(alignment: .leading, spacing: 0) {
                Text("删除账户？")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.text)

                Text("此账户将从列表中移除。")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondary)
                    .padding(.top, 8)

                HStack(spacing: 8) {
                    Spacer()

                    Button("取消") {
                        model.pendingDelete = nil
                    }
                    .buttonStyle(GhostButtonStyle())
                    .frame(width: 86)
                    .keyboardShortcut(.cancelAction)

                    Button("删除") {
                        model.delete(account)
                    }
                    .buttonStyle(DangerButtonStyle())
                    .frame(width: 90)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.top, 22)
            }
            .padding(24)
            .frame(width: 330)
            .background(SheetSurface(cornerRadius: 24))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color(red: 0.06, green: 0.10, blue: 0.20).opacity(0.24), radius: 28, x: 0, y: 14)
        }
        .transition(.opacity)
    }
}
