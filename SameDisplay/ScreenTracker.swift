//
//  ScreenTracker.swift
//  SameDisplay
//
//  Tracks the current mouse position and determines which display it's on
//

import Cocoa
import SwiftUI

class ScreenTracker: ObservableObject {
    @Published var currentScreen: NSScreen?
    @Published var currentScreenName: String?
    
    private var mouseMonitor: Any?
    private var timer: Timer?
    
    init() {
        updateCurrentScreen()
    }
    
    /// Start monitoring mouse movements
    func startTracking() {
        // Use a timer-based approach for better reliability
        // Global mouse monitor can be flaky in some scenarios
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.updateCurrentScreen()
        }
    }
    
    /// Stop monitoring mouse movements
    func stopTracking() {
        timer?.invalidate()
        timer = nil
        
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
    }
    
    /// Get the current mouse screen without updating published properties
    func getCurrentMouseScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        }
    }
    
    /// Update the current screen based on mouse position
    private func updateCurrentScreen() {
        let mouseLocation = NSEvent.mouseLocation
        
        // Find which screen contains the mouse
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) {
            DispatchQueue.main.async {
                self.currentScreen = screen
                self.currentScreenName = self.getScreenName(screen)
            }
        }
    }
    
    /// Get a human-readable name for a screen
    private func getScreenName(_ screen: NSScreen) -> String {
        // On modern macOS, NSScreen already exposes a localizedName
        // that typically matches what the user sees in System Settings.
        if #available(macOS 10.15, *) {
            return screen.localizedName
        }
        
        // Fallback for older systems: main vs indexed displays
        if screen == NSScreen.main {
            return "Main Display"
        }
        
        if let index = NSScreen.screens.firstIndex(of: screen) {
            return "Display \(index + 1)"
        }
        
        return "Unknown Display"
    }
    
    deinit {
        stopTracking()
    }
}

