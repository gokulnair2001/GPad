import AppKit
import SwiftUI

final class FloatingPanelController {

    private var panel: NSPanel?
    private var manager: MultipeerManager

    init(manager: MultipeerManager) {
        self.manager = manager
    }

    func show() {
        guard panel == nil else { return }

        let panelContent = FloatingPanelView(manager: manager)
        let hostingView = NSHostingView(rootView: panelContent)
        hostingView.sizingOptions = .intrinsicContentSize

        let panelWidth: CGFloat = 200
        let panelHeight: CGFloat = 300

        // Position: vertically centered on the left edge
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let originX = screenFrame.minX
        let originY = screenFrame.midY - panelHeight / 2

        let panel = NSPanel(
            contentRect: NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden

        // Remove standard window buttons
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        panel.orderFrontRegardless()
        self.panel = panel
    }

    func close() {
        panel?.close()
        panel = nil
    }
}
