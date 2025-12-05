//
//  AppCoordinator.swift
//  SameDisplay
//
//  Coordinates all components of the app
//

import Cocoa
import SwiftUI
import Combine
import ApplicationServices

class AppCoordinator: ObservableObject {
    
    // Component instances
    private let permissionManager = AccessibilityPermissionManager()
    private let screenTracker = ScreenTracker()
    private let windowObserver = AXWindowObserver()
    private let windowMover = WindowMover()
    private let aboutWindowController = AboutWindowController()
    
    // Published state for UI
    @Published var hasAccessibilityPermission: Bool = false
    @Published var currentScreenName: String?
    
    // Track windows we've recently moved to avoid moving them multiple times
    private var recentlyMovedWindows: Set<UnsafeRawPointer> = []
    private var moveResetTimer: Timer?
    
    init() {
        setupBindings()
        checkAndRequestPermissions()
        
        // Start screen tracking immediately
        screenTracker.startTracking()
    }
    
    /// Set up bindings between components
    private func setupBindings() {
        // Observe permission changes
        permissionManager.$isTrusted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isTrusted in
                self?.hasAccessibilityPermission = isTrusted
                if isTrusted {
                    self?.startWindowMonitoring()
                } else {
                    self?.stopWindowMonitoring()
                }
            }
            .store(in: &cancellables)
        
        // Observe screen changes
        screenTracker.$currentScreenName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] screenName in
                self?.currentScreenName = screenName
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Check permissions and request if needed
    private func checkAndRequestPermissions() {
        permissionManager.checkPermission()
        
        // If not trusted, request permission immediately on startup
        if !permissionManager.isTrusted {
            // Use a slight delay to ensure the app loop is running, then request/prompt
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.permissionManager.requestPermission()
                // Also explicitly open the settings if not trusted, to be helpful
                // But only do this if we really want to force the user. 
                // The prompt from requestPermission() usually has a button to open settings.
                // Let's stick to requestPermission() which shows the system alert "SameDisplay would like to control this computer..."
            }
        }
    }
    
    /// Start monitoring for new windows
    private func startWindowMonitoring() {
        windowObserver.onNewWindow = { [weak self] app, window in
            self?.handleNewWindow(app: app, window: window)
        }
        
        windowObserver.startObserving()
    }
    
    /// Stop monitoring for new windows
    private func stopWindowMonitoring() {
        windowObserver.stopObserving()
    }
    
    /// Handle a new window being created
    private func handleNewWindow(app: AXUIElement, window: AXUIElement) {
        // Create a unique identifier for this window
        let windowPtr = UnsafeRawPointer(Unmanaged.passUnretained(window as AnyObject).toOpaque())
        
        // Skip if we've recently moved this window
        guard !recentlyMovedWindows.contains(windowPtr) else {
            return
        }
        
        // Check if we should move this window
        guard windowMover.shouldMoveWindow(window) else {
            return
        }
        
        // Get the current mouse screen
        guard let targetScreen = screenTracker.getCurrentMouseScreen() else {
            return
        }
        
        // Add a small delay to let the window finish initializing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // Move the window
            self.windowMover.moveWindow(window, to: targetScreen)
            
            // Mark this window as recently moved
            self.recentlyMovedWindows.insert(windowPtr)
            
            // Reset the recently moved set after a delay
            self.scheduleRecentlyMovedReset()
        }
    }
    
    /// Schedule cleanup of recently moved windows tracker
    private func scheduleRecentlyMovedReset() {
        moveResetTimer?.invalidate()
        moveResetTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.recentlyMovedWindows.removeAll()
        }
    }
    
    /// Open Accessibility settings
    func openAccessibilitySettings() {
        permissionManager.openAccessibilitySettings()
    }
    
    /// Open About Window
    func openAboutWindow() {
        aboutWindowController.show()
    }
    
    deinit {
        moveResetTimer?.invalidate()
    }
}


