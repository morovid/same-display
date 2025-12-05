//
//  WindowMover.swift
//  SameDisplay
//
//  Handles moving windows to the target display
//

import Cocoa
import ApplicationServices

class WindowMover {
    
    /// Move a window to a specific screen
    /// - Parameters:
    ///   - window: The AXUIElement representing the window
    ///   - targetScreen: The NSScreen to move the window to
    func moveWindow(_ window: AXUIElement, to targetScreen: NSScreen) {
        // Get current window position and size
        guard let currentPosition = getWindowPosition(window),
              let windowSize = getWindowSize(window) else {
            return
        }
        
        // Validate window size (some windows report 0x0 before fully initializing)
        guard windowSize.width > 0 && windowSize.height > 0 else {
            return
        }
        
        // Get current screen (where the window currently is)
        let currentScreen = NSScreen.screens.first { screen in
            let windowCenter = CGPoint(
                x: currentPosition.x + windowSize.width / 2,
                y: currentPosition.y + windowSize.height / 2
            )
            return NSPointInRect(windowCenter, screen.frame)
        }
        
        // If window is already on target screen, don't move it
        if currentScreen == targetScreen {
            return
        }
        
        // Calculate the relative position of the window on its current screen
        var relativeX: CGFloat = 0.5 // Default to center
        var relativeY: CGFloat = 0.5
        
        if let currentScreen = currentScreen {
            let screenWidth = currentScreen.frame.width
            let screenHeight = currentScreen.frame.height
            
            // Avoid division by zero
            if screenWidth > 0 && screenHeight > 0 {
                relativeX = (currentPosition.x - currentScreen.frame.origin.x) / screenWidth
                relativeY = (currentPosition.y - currentScreen.frame.origin.y) / screenHeight
                
                // Clamp relative positions to [0, 1] range
                relativeX = max(0, min(1, relativeX))
                relativeY = max(0, min(1, relativeY))
            }
        }
        
        // Calculate new position on target screen (preserving relative position)
        let targetWidth = targetScreen.frame.width
        let targetHeight = targetScreen.frame.height
        
        // Calculate position, accounting for window size
        let availableWidth = max(0, targetWidth - windowSize.width)
        let availableHeight = max(0, targetHeight - windowSize.height)
        
        var newX = targetScreen.frame.origin.x + (relativeX * availableWidth)
        var newY = targetScreen.frame.origin.y + (relativeY * availableHeight)
        
        // Ensure the window fits within the target screen bounds
        // Add a small margin (20 points) from screen edges for safety
        let margin: CGFloat = 20
        newX = max(targetScreen.frame.origin.x + margin, 
                   min(newX, targetScreen.frame.maxX - windowSize.width - margin))
        newY = max(targetScreen.frame.origin.y + margin, 
                   min(newY, targetScreen.frame.maxY - windowSize.height - margin))
        
        // Set the new position
        setWindowPosition(window, to: CGPoint(x: newX, y: newY))
    }
    
    /// Get the position of a window
    private func getWindowPosition(_ window: AXUIElement) -> CGPoint? {
        var positionValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
        
        guard result == .success, let positionValue = positionValue else {
            return nil
        }
        
        var point = CGPoint.zero
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &point) else {
            return nil
        }
        
        return point
    }
    
    /// Get the size of a window
    private func getWindowSize(_ window: AXUIElement) -> CGSize? {
        var sizeValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
        
        guard result == .success, let sizeValue = sizeValue else {
            return nil
        }
        
        var size = CGSize.zero
        guard AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) else {
            return nil
        }
        
        return size
    }
    
    /// Set the position of a window
    private func setWindowPosition(_ window: AXUIElement, to position: CGPoint) {
        var point = position
        if let positionValue = AXValueCreate(.cgPoint, &point) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        }
    }
    
    /// Check if a window should be moved (filters out certain window types)
    func shouldMoveWindow(_ window: AXUIElement) -> Bool {
        // Check if window has a position attribute (some windows like menus don't)
        var positionValue: AnyObject?
        let hasPosition = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
        guard hasPosition == .success else {
            return false
        }
        
        // Check if position is settable (some windows are read-only)
        var settable: DarwinBoolean = false
        let settableResult = AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &settable)
        guard settableResult == .success && settable.boolValue else {
            return false
        }
        
        // Check window role
        var roleValue: AnyObject?
        let roleResult = AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &roleValue)
        if roleResult == .success, let role = roleValue as? String {
            // Only move standard windows
            if role != kAXWindowRole as String {
                return false
            }
        }
        
        // Check window subrole (avoid moving dialogs, sheets, etc.)
        var subroleValue: AnyObject?
        let subroleResult = AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subroleValue)
        if subroleResult == .success, let subrole = subroleValue as? String {
            // Skip floating windows, dialogs, sheets, tooltips, and utility windows
            let excludedSubroles = [
                kAXFloatingWindowSubrole as String,
                kAXDialogSubrole as String,
                kAXSystemDialogSubrole as String,
                "AXSheet", // Not defined in constants but used by some apps
                "AXSystemSheet",
                "AXToolbarWindow",
                "AXTooltip"
            ]
            
            if excludedSubroles.contains(subrole) {
                return false
            }
        }
        
        // Check if window is minimized
        var minimizedValue: AnyObject?
        let minimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedValue)
        if minimizedResult == .success,
           let minimized = minimizedValue as? Bool,
           minimized {
            return false
        }
        
        // Check if window is in fullscreen mode.
        // Not all SDKs expose kAXFullscreenAttribute, so use the raw attribute name.
        var fullscreenValue: AnyObject?
        let fullscreenAttribute = "AXFullscreen" as CFString
        let fullscreenResult = AXUIElementCopyAttributeValue(window, fullscreenAttribute, &fullscreenValue)
        if fullscreenResult == .success,
           let fullscreen = fullscreenValue as? Bool,
           fullscreen {
            return false // Don't move fullscreen windows
        }
        
        // Check window title (some apps use empty titles for utility windows)
        var titleValue: AnyObject?
        let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
        if titleResult == .success, let title = titleValue as? String {
            // Skip windows with very short or empty titles (often utility windows)
            // But allow some short titles like "1" or "2" for certain apps
            if title.isEmpty {
                return false
            }
        }
        
        return true
    }
}

