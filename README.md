# Risetta for macOS

Risetta 的 macOS 版本，使用 SwiftUI + AppKit 编写，界面和功能与 Windows 版保持一致：浅色液体玻璃、实时验证码、桌面悬浮展示。

## 构建

需要 macOS 13 或更高版本，以及 Xcode Command Line Tools：

```bash
xcode-select --install
```

然后在当前目录运行：

```bash
bash build.sh
```

也可以双击 `build.command`。构建完成后会生成：

```
build/Risetta.app
```

脚本会自动打开 App。

macOS 的隔离标记（quarantine）由浏览器或解压工具添加，不是 App 本身的一部分。首次使用请双击 `Start Risetta.command`，它会自动清除隔离标记并打开 App；如果这个脚本本身也被拦截，右键点击它 -> **打开** 一次即可。也可以手动执行：

```bash
xattr -dr com.apple.quarantine build/Risetta.app
```

清除一次后不会再弹。重新下载压缩包会重新带上标记，重新运行一次 `Start Risetta.command` 即可。

## 没有 Mac 时：用 GitHub Actions 构建

仓库里已经包含 `.github/workflows/build-macos.yml`。把项目推到 GitHub 后，在 Actions 页面运行 **Build macOS app**，它会使用 GitHub 提供的 macOS 运行器编译，并上传 `Risetta-macos-app.zip` 构建产物。

- 公开仓库免费；私有仓库会消耗 macOS Actions 分钟数
- 构建产物是未签名的 `.app`，下载后仍需清除一次隔离标记
- CI 只能编译，不能交互调试界面；调试仍建议租用云端 Mac 或使用 MacinCloud 等远程桌面

如果仓库根目录就是本项目（`build.sh` 在根目录），workflow 会直接构建；如果项目放在 `risetta-macos/` 子目录，也会自动识别。

## 功能

- 添加、编辑、删除多个 2FA 账户
- 支持 Base32 密钥和 `otpauth://totp/...` 链接
- SHA1 / SHA256 / SHA512，6 / 8 位验证码
- 点击卡片复制验证码
- 图钉按钮进入“桌面展示”：选择账户后，桌面悬浮卡片显示实时验证码
- 桌面悬浮卡片位于壁纸上方、普通窗口下方；可拖动，位置会保存
- 关闭悬浮卡片会回到主窗口

## 数据

- 账户数据：`~/Library/Application Support/Risetta/vault.dat`
- 悬浮窗位置与选择：`~/Library/Application Support/Risetta/settings.json`
- 加密密钥：macOS 钥匙串（Keychain）
- 账户数据使用 AES-GCM 加密后落盘，不会以明文保存

## 快捷键

- `⌘ N` 添加账户
- `⌘ F` 搜索
- `Esc` 关闭当前弹层
- `⌘ Q` 退出

## 说明

这是 macOS 源码包。当前工作环境是 Windows，无法直接编译 macOS 二进制，因此提供完整的 Swift 源码和一键构建脚本；在 Mac 上运行 `build.sh` 即可得到可运行的 `Risetta.app`。
