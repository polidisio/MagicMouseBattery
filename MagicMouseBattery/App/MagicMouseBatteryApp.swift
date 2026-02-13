import SwiftUI
import AppKit

@main
struct MagicMouseBatteryApp: App {
    @StateObject private var batteryService = BatteryService()
    @StateObject private var notificationService = NotificationService()

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var popover: NSPopover!
    var statusItem: NSStatusItem!
    var eventMonitor: Any?

    let batteryService = BatteryService()
    let notificationService = NotificationService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        setupEventMonitor()

        batteryService.startMonitoring(interval: 60)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelsChanged),
            name: .init("BatteryLevelsChanged"),
            object: nil
        )
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateStatusItemImage()
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func updateStatusItemImage() {
        guard let button = statusItem.button else { return }

        let lowestLevel = batteryService.devices.compactMap { $0.batteryLevel }.min() ?? 100

        if let image = NSImage(named: "battery") {
            let resizedImage = NSImage(size: NSSize(width: 18, height: 18))
            resizedImage.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: resizedImage.size),
                      from: NSRect(origin: .zero, size: image.size),
                      operation: .sourceOver,
                      fraction: 1.0)
            resizedImage.unlockFocus()
            button.image = resizedImage
        }

        if lowestLevel < 100 {
            button.attributedTitle = attributedTitle(for: lowestLevel)
        }
    }

    private func attributedTitle(for level: Int) -> NSAttributedString {
        let color: NSColor
        if level < 10 {
            color = .systemRed
        } else if level < 20 {
            color = .systemYellow
        } else {
            color = .labelColor
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        ]

        return NSAttributedString(string: "\(level)%", attributes: attributes)
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 300)
        popover.behavior = .transient
        popover.delegate = self

        let menuBarView = MenuBarView(
            batteryService: batteryService,
            notificationService: notificationService
        )
        popover.contentViewController = NSHostingController(rootView: menuBarView)
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    @objc func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem.button {
                batteryService.refresh()
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    @objc private func batteryLevelsChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusItemImage()
        }
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
