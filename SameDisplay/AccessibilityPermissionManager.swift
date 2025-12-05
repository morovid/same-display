//
//  AccessibilityPermissionManager.swift
//  SameDisplay
//
//  Manages Accessibility permission checking and requesting
//

import Cocoa
import ApplicationServices

class AccessibilityPermissionManager: ObservableObject {
    @Published var isTrusted: Bool = false
    
    init() {
        checkPermission()
    }
    
    /// Check if the app has Accessibility permissions
    func checkPermission() {
        let trusted = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.isTrusted = trusted
        }
    }
    
    /// Request Accessibility permissions (shows system dialog)
    func requestPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        DispatchQueue.main.async {
            self.isTrusted = trusted
        }
        
        // Start polling to detect when permission is granted
        if !trusted {
            startPolling()
        }
    }
    
    /// Open System Settings to Accessibility preferences
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    /// Poll for permission changes (called after requesting permission)
    private func startPolling() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let trusted = AXIsProcessTrusted()
            if trusted != self.isTrusted {
                DispatchQueue.main.async {
                    self.isTrusted = trusted
                }
                
                if trusted {
                    timer.invalidate()
                }
            }
        }
    }
}


