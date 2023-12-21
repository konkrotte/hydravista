import SwiftUI

extension Notification.Name {
    static let refreshNotification = Notification.Name("RefreshNotification")
}

extension Notification.Name {
    static let searchNotification = Notification.Name("SearchNotification")
}

extension Notification.Name {
    static let previousEntryNotification = Notification.Name("PreviousEntryNotification")
}

extension Notification.Name {
    static let nextEntryNotification = Notification.Name("NextEntryNotification")
}

extension Notification.Name {
    static let zoomImageNotification = Notification.Name("ZoomImageNotification")
}

extension Notification.Name {
    static let resetImageNotification = Notification.Name("ResetImageNotification")
}

@main
struct Hydrus_ClientApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            SidebarCommands()
            InspectorCommands()
            CommandMenu("Find") {
                Button("Search") {
                    NotificationCenter.default.post(name: .searchNotification, object: nil)
                }.keyboardShortcut("f", modifiers: .command)
            }
            // FIXME: Should be under View, not File
            CommandGroup(before: .newItem){
                Button("Refresh") {
                    NotificationCenter.default.post(name: .refreshNotification, object: nil)
                }.keyboardShortcut("r", modifiers: .command)
            }
            CommandGroup(before: .sidebar){
                Button("Previous entry") {
                    NotificationCenter.default.post(name: .previousEntryNotification, object: nil)
                }.keyboardShortcut(.leftArrow, modifiers: .command)
            }
            CommandGroup(before: .sidebar){
                Button("Next entry") {
                    NotificationCenter.default.post(name: .nextEntryNotification, object: nil)
                }.keyboardShortcut(.rightArrow, modifiers: .command)
            }
            CommandGroup(before: .sidebar){
                Button("Zoom in") {
                    NotificationCenter.default.post(name: .zoomImageNotification, object: nil, userInfo: ["factor": CGFloat(0.5)])
                }.keyboardShortcut("+", modifiers: .command)
            }
            CommandGroup(before: .sidebar){
                Button("Zoom out") {
                    NotificationCenter.default.post(name: .zoomImageNotification, object: nil, userInfo: ["factor": CGFloat(-0.5)])
                }.keyboardShortcut("-", modifiers: .command)
            }
            CommandGroup(before: .sidebar){
                Button("Reset") {
                    NotificationCenter.default.post(name: .resetImageNotification, object: nil)
                }.keyboardShortcut("0", modifiers: .command)
            }
            CommandGroup(after: .newItem) {
                Button(action: {
                    if let currentWindow = NSApp.keyWindow,
                       let windowController = currentWindow.windowController {
                        windowController.newWindowForTab(nil)
                        if let newWindow = NSApp.keyWindow,
                           currentWindow != newWindow {
                            currentWindow.addTabbedWindow(newWindow, ordered: .above)
                        }
                    }
                }) {
                    Text("New Tab")
                }
                .keyboardShortcut("t", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}
