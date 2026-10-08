import AppKit
import SwiftUI

@main
struct MacSweepApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        Window("MacSweep", id: "main") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 760, minHeight: 560)
        }
        .defaultSize(width: 980, height: 820)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(model.t.rescan) { Task { await model.rescan() } }
                    .keyboardShortcut("r")
                    .disabled(model.phase == .scanning || model.run != nil)
            }
        }

        Settings {
            SettingsView().environmentObject(model)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)  // also when started as a bare binary (swift run)
        if ProcessInfo.processInfo.environment["MACSWEEP_DEMO_APPEARANCE"] == "dark" {  // screenshots
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
