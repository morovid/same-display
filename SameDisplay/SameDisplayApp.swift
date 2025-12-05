//
//  SameDisplayApp.swift
//  SameDisplay
//
//  A menu bar app that moves new windows to the display where the mouse cursor is located
//

import SwiftUI

@main
struct SameDisplayApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    
    var body: some Scene {
        MenuBarExtra("SameDisplay", image: "MenuBarIcon") {
            // App Name - non-clickable
            Text("SameDisplay")
            
            // Info Submenu
            Menu("Info") {
                // Accessibility Status
                if appCoordinator.hasAccessibilityPermission {
                    Text("Accessibility: Enabled")
                } else {
                    Button("Accessibility: Disabled") {
                        appCoordinator.openAccessibilitySettings()
                    }
                }
                
                // Mouse On Status
                if let screenName = appCoordinator.currentScreenName {
                    Text("Mouse on: \(screenName)")
                } else {
                    Text("Mouse on: Unknown")
                }
            }
            
            Divider()
            
            // About
            Button("About") {
                appCoordinator.openAboutWindow()
            }
            
            // Quit
            Button("Quit SameDisplay") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}
