import AppKit
import Combine
import CoreGraphics
import SwiftUI

final class PinPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class PinWindowController: NSWindowController, NSWindowDelegate {
    private let model: AppModel
    private let panel: PinPanel
    private var cancellable: AnyCancellable?
    private var isClosingFromApp = false

    var onUserClosed: (() -> Void)?

    init(model: AppModel) {
        self.model = model

        let rect = NSRect(x: 0, y: 0, width: 340, height: 400)
        panel = PinPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init(window: panel)

        panel.delegate = self
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = true
        panel.isFloatingPanel = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.acceptsMouseMovedEvents = true

        panel.contentView = NSHostingView(
            rootView: PinWidgetView(
                model: model,
                onClose: { [weak self] in
                    self?.closeByUser()
                }
            )
        )

        resize()

        cancellable = model.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.resize()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        resize()
        position()
        panel.orderFrontRegardless()
    }

    func closeByUser() {
        isClosingFromApp = false
        panel.close()
    }

    func closeFromApp() {
        isClosingFromApp = true
        panel.close()
    }

    func windowWillClose(_ notification: Notification) {
        guard !isClosingFromApp else {
            return
        }
        onUserClosed?()
    }

    func windowDidMove(_ notification: Notification) {
        model.updateWidgetPosition(left: panel.frame.origin.x, top: panel.frame.origin.y)
    }

    private func resize() {
        let count = model.selectedAccounts.count
        let height: CGFloat
        if count == 0 {
            height = 36 + 28 + 62
        } else {
            let contentHeight = min(372, CGFloat(count) * 58 + 8)
            height = min(600, 36 + 28 + contentHeight)
        }

        let currentHeight = panel.contentRect(forFrameRect: panel.frame).height
        if abs(currentHeight - height) > 0.5 {
            panel.setContentSize(NSSize(width: 340, height: height))
        }
    }

    private func position() {
        let settings = PinSettingsStore.load()
        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width: CGFloat = 340
        let height = panel.frame.height

        var x = settings.left ?? (visible.maxX - width - 32)
        var y = settings.top ?? (visible.maxY - height - 80)

        x = min(max(x, visible.minX + 8), visible.maxX - width - 8)
        y = min(max(y, visible.minY + 8), visible.maxY - height - 8)

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
