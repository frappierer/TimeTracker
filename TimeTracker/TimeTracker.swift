import Foundation
import AppKit
import SwiftUI
import Vision

#if os(macOS)
import Cocoa

typealias UIImage = NSImage

extension NSImage {
    var cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
    }

    convenience init?(named name: String) {
        self.init(named: NSImage.Name(name))
    }
}
#endif

class TimeTracker: ObservableObject {
    @Published var isTracking = false
    private var timer: Timer?
    private var screenshotHandler: ScreenshotHandler
    private lazy var apiHandler: APIHandler = APIHandler(apiKey: self.apiKey) // Use lazy initialization
    private var csvHandler: CSVHandler

    @AppStorage("interval") private var interval: TimeInterval = 60.0
    @AppStorage("keepScreenshots") private var keepScreenshots: Bool = false
    @AppStorage("openai_api_key") private var apiKey: String = ""

    private var outputFolder: URL
    private var csvFilePath: URL
    private var wasTrackingBeforeLock = false // Track if it was tracking before lock

    init() {
        // Initialize properties that don't depend on self
        let outputFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            .appendingPathComponent("TimeTracker", isDirectory: true)
        try? FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        let csvFilePath = outputFolder.appendingPathComponent("activity_log.csv")
        
        // Assign to self properties
        self.outputFolder = outputFolder
        self.csvFilePath = csvFilePath
        
        // Initialize handlers
        self.screenshotHandler = ScreenshotHandler(outputFolder: outputFolder)
        self.csvHandler = CSVHandler(csvFilePath: csvFilePath)
        
        // Add system event observers
        addSystemEventObservers()
    }

    deinit {
        // Remove system event observers
        removeSystemEventObservers()
    }

    private var settingsWindow: NSWindow?

    func start() {
        guard !isTracking else { return }
        isTracking = true
        
        // Capture a screenshot immediately
        captureScreenshots()
        
        // Set up the timer to capture screenshots at the specified interval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.captureScreenshots()
        }
    }

    func stop() {
        isTracking = false
        timer?.invalidate()
    }

    func captureScreenshots() {
        screenshotHandler.captureAndProcessScreenshots(apiHandler: apiHandler, csvHandler: csvHandler, keepScreenshots: keepScreenshots)
    }

    func openSettings() {
        if settingsWindow == nil {
            DispatchQueue.main.async {
                self.settingsWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                    styleMask: [.titled, .closable, .miniaturizable],
                    backing: .buffered, defer: false
                )
                self.settingsWindow?.center()
                self.settingsWindow?.setFrameAutosaveName("Settings")

                self.settingsWindow?.appearance = NSAppearance(named: .vibrantLight)

                let hostingController = NSHostingController(rootView: SettingsView())
                self.settingsWindow?.contentView = hostingController.view
                self.settingsWindow?.isReleasedWhenClosed = false

                self.settingsWindow?.level = .floating

                self.settingsWindow?.makeKeyAndOrderFront(nil)
            }
        } else {
            DispatchQueue.main.async {
                self.settingsWindow?.makeKeyAndOrderFront(nil)
            }
        }
    }

    // MARK: - System Event Observers

    private func addSystemEventObservers() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(systemDidWake), name: NSWorkspace.didWakeNotification, object: nil)
        center.addObserver(self, selector: #selector(systemWillSleep), name: NSWorkspace.willSleepNotification, object: nil)
        
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(screenIsLocked), name: Notification.Name("com.apple.screenIsLocked"), object: nil)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(screenIsUnlocked), name: Notification.Name("com.apple.screenIsUnlocked"), object: nil)
    }

    private func removeSystemEventObservers() {
        let center = NSWorkspace.shared.notificationCenter
        center.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func systemDidWake() {
        // Handle system wakeup
        print("System woke up")
        if wasTrackingBeforeLock {
            start()
        }
    }

    @objc private func systemWillSleep() {
        // Handle system sleep
        print("System will sleep")
        if isTracking {
            wasTrackingBeforeLock = true
            stop()
        } else {
            wasTrackingBeforeLock = false
        }
    }

    @objc private func screenIsLocked() {
        // Handle screen locking (screensaver starts)
        print("Screen is locked")
        if isTracking {
            wasTrackingBeforeLock = true
            stop()
        } else {
            wasTrackingBeforeLock = false
        }
    }

    @objc private func screenIsUnlocked() {
        // Handle screen unlocking (screensaver ends)
        print("Screen is unlocked")
        if wasTrackingBeforeLock {
            start()
        }
    }
}
