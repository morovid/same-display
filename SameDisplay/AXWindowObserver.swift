//
//  AXWindowObserver.swift
//  SameDisplay
//
//  Observes window creation events across all running applications using Accessibility API
//

import Cocoa
import ApplicationServices

class AXWindowObserver {
    
    // Callback when a new window is created
    var onNewWindow: ((AXUIElement, AXUIElement) -> Void)?
    
    // Store observers for running applications
    private var observers: [pid_t: AXObserver] = [:]
    
    // Store CFRunLoopSource references to keep them alive
    private var runLoopSources: [pid_t: CFRunLoopSource] = [:]
    
    // Store workspace notification observers
    private var workspaceObservers: [NSObjectProtocol] = []
    
    init() {}
    
    /// Start observing all running applications
    func startObserving() {
        // Observe currently running applications
        for app in NSWorkspace.shared.runningApplications {
            observeApplication(app)
        }
        
        // Observe new applications being launched
        let launchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                self?.observeApplication(app)
            }
        }
        workspaceObservers.append(launchObserver)
        
        // Observe applications terminating
        let terminateObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                self?.removeObserver(for: app.processIdentifier)
            }
        }
        workspaceObservers.append(terminateObserver)
    }
    
    /// Stop observing all applications
    func stopObserving() {
        // Remove all observers
        for pid in observers.keys {
            removeObserver(for: pid)
        }
        
        // Remove workspace observers
        for observer in workspaceObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        workspaceObservers.removeAll()
    }
    
    /// Observe a specific application for window events
    private func observeApplication(_ app: NSRunningApplication) {
        let pid = app.processIdentifier
        
        // Skip if already observing
        guard observers[pid] == nil else { return }
        
        // Skip our own app
        guard pid != ProcessInfo.processInfo.processIdentifier else { return }
        
        // Skip non-UI apps
        guard app.activationPolicy == .regular || app.activationPolicy == .accessory else { return }
        
        // Create AX observer
        var observer: AXObserver?
        let result = AXObserverCreate(pid, axObserverCallback, &observer)
        
        guard result == .success, let observer = observer else {
            return
        }
        
        // Create application element
        let appElement = AXUIElementCreateApplication(pid)
        
        // Add notification for window created
        let addResult = AXObserverAddNotification(
            observer,
            appElement,
            kAXWindowCreatedNotification as CFString,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        guard addResult == .success else {
            return
        }
        
        // Also observe focused window changes (some apps don't fire window created consistently)
        _ = AXObserverAddNotification(
            observer,
            appElement,
            kAXFocusedWindowChangedNotification as CFString,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        // Add observer to run loop
        let runLoopSource = AXObserverGetRunLoopSource(observer)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        
        // Store observer and run loop source
        observers[pid] = observer
        runLoopSources[pid] = runLoopSource
    }
    
    /// Remove observer for a specific process
    private func removeObserver(for pid: pid_t) {
        if let runLoopSource = runLoopSources[pid] {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
            runLoopSources.removeValue(forKey: pid)
        }
        
        observers.removeValue(forKey: pid)
    }
    
    /// Handle accessibility notification callback
    fileprivate func handleNotification(observer: AXObserver, element: AXUIElement, notification: CFString) {
        let notificationName = notification as String
        
        // We registered notifications on the application AXUIElement, so `element`
        // is the app. We need to derive the relevant window from it.
        guard notificationName == kAXWindowCreatedNotification as String ||
                notificationName == kAXFocusedWindowChangedNotification as String else {
            return
        }
        
        let appElement = element
        var windowValue: AnyObject?
        
        // Prefer the focused window (works well for most apps)
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &windowValue
        )
        
        // Fallback: use the first window in the app's window list
        if (result != .success || windowValue == nil) {
            var windowsValue: AnyObject?
            let windowsResult = AXUIElementCopyAttributeValue(
                appElement,
                kAXWindowsAttribute as CFString,
                &windowsValue
            )
            
            if windowsResult == .success,
               let windows = windowsValue as? [AXUIElement],
               let firstWindow = windows.first {
                windowValue = firstWindow as AnyObject
            }
        }
        
        if let windowValue = windowValue {
            // For CoreFoundation types like AXUIElement, conditional downcast is
            // guaranteed to succeed if the value is non-nil, so we cast directly.
            let windowElement = windowValue as! AXUIElement
            onNewWindow?(appElement, windowElement)
        }
    }
    
    deinit {
        stopObserving()
    }
}

// Global callback function for AXObserver
private func axObserverCallback(
    observer: AXObserver,
    element: AXUIElement,
    notification: CFString,
    refcon: UnsafeMutableRawPointer?
) {
    guard let refcon = refcon else { return }
    
    let windowObserver = Unmanaged<AXWindowObserver>.fromOpaque(refcon).takeUnretainedValue()
    windowObserver.handleNotification(observer: observer, element: element, notification: notification)
}

