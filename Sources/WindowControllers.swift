import AppKit
import SwiftUI

@MainActor
final class MainWindowController: NSWindowController, NSWindowDelegate {
    private let model: AppModel
    private var pinController: PinWindowController?
    private var isShuttingDown = false

    init(model: AppModel) {
        self.model = model

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)

        window.delegate = self
        window.isReleasedWhenClosed = false
        window.title = "Risetta"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(red: 0.992, green: 0.994, blue: 1.0, alpha: 1.0)
        window.isMovableByWindowBackground = true
        window.contentMinSize = NSSize(width: 480, height: 620)
        window.hasShadow = true
        window.contentView = NSHostingView(rootView: MainView(model: model))
        window.center()
        window.setFrameAutosaveName("RisettaMainWindow")

        model.onPinRequested = { [weak self] in
            self?.showPinWidget()
        }
        model.onWidgetClosed = { [weak self] in
            self?.restoreMainWindow()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    func prepareForTermination() {
        guard !isShuttingDown else {
            return
        }
        isShuttingDown = true
        pinController?.closeFromApp()
    }

    func windowWillClose(_ notification: Notification) {
        guard !isShuttingDown else {
            return
        }

        prepareForTermination()
        NSApp.terminate(nil)
    }

    private func showPinWidget() {
        if pinController == nil {
            let controller = PinWindowController(model: model)
            controller.onUserClosed = { [weak self] in
                self?.restoreMainWindow()
            }
            pinController = controller
        }

        pinController?.show()

        DispatchQueue.main.async { [weak self] in
            self?.window?.miniaturize(nil)
        }
    }

    private func restoreMainWindow() {
        guard let window else {
            return
        }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
