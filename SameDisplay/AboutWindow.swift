//
//  AboutWindow.swift
//  SameDisplay
//
//  About window for the application
//

import SwiftUI
import AppKit

class AboutWindowController {
    private var window: NSWindow?
    
    func show() {
        // If window already exists, just bring it to front
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create the about view
        let aboutView = AboutView()
        let hostingController = NSHostingController(rootView: aboutView)
        
        // Create the window
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "About SameDisplay"
        newWindow.styleMask = [.titled, .closable]
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        newWindow.level = .floating
        
        // Set window size
        newWindow.setContentSize(NSSize(width: 400, height: 280))
        
        // Prevent resizing
        newWindow.styleMask.remove(.resizable)
        
        self.window = newWindow
        
        // Show the window
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // App Name
            Text("SameDisplay")
                .font(.title)
                .fontWeight(.bold)
            
            // Version
            Text("Version \(appVersion)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.horizontal, 40)
            
            // Description
            Text("Automatically moves newly opened windows to the display where your mouse cursor is located.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
                .padding(.horizontal, 40)
            
            // Author
            VStack(spacing: 4) {
                Text("Author")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Morovid s.r.o.")
                    .font(.body)
                
                Button(action: {
                    if let url = URL(string: "mailto:jan.malcak@morovid.com") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("jan.malcak@morovid.com")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(30)
        .frame(width: 400, height: 280)
    }
    
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0"
    }
}
