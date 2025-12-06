# SameDisplay 🖥️

A macOS menu bar application that automatically moves newly opened windows to the display where your mouse cursor is located.

## Features

- **Menu Bar Only**: Lives in the menu bar without cluttering your Dock
- **Automatic Window Moving**: Detects when any application opens a new window and moves it to the display where your mouse is
- **Multi-Display Support**: Works seamlessly with multiple monitors in any arrangement
- **Permission Management**: Guides you through granting necessary Accessibility permissions

## Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permissions (the app will guide you through granting these)

## Building and Running

### With Xcode

1. Open `SameDisplay.xcodeproj` in Xcode
2. Select the "SameDisplay" scheme
3. Build and run (⌘R)

### First Launch

On first launch, the app will:

1. Appear in your menu bar with a window icon
2. Request Accessibility permissions
3. Guide you to System Settings if needed

**Important**: You must grant Accessibility permissions for the app to function. Without these permissions, the app cannot detect or move windows from other applications.

### Granting Accessibility Permissions

1. Click the SameDisplay icon in the menu bar
2. Click "Open Accessibility Settings"
3. In System Settings → Privacy & Security → Accessibility:
   - Click the lock icon to make changes
   - Find "SameDisplay" in the list
   - Toggle it ON
4. Return to the app - it will automatically detect the permission change

## Usage

Once running and permissions are granted:

1. The app runs silently in the menu bar
2. Move your mouse to the display where you want new windows to appear
3. Open any new window in any application
4. The window will automatically move to the display under your cursor

### Menu Bar Options

Click the menu bar icon to see:

- **Accessibility Status**: Shows if permissions are granted (green checkmark) or denied (red X)
- **Current Display**: Shows which display your mouse is currently on
- **Open Accessibility Settings**: Quick link to system settings
- **Quit SameDisplay**: Exit the application (⌘Q)

## How It Works

SameDisplay uses macOS Accessibility APIs to:

1. **Monitor Mouse Position**: Tracks which display contains the cursor
2. **Observe Window Creation**: Listens for new window events across all running applications
3. **Move Windows**: Repositions new windows to the display where the cursor is located

The app intelligently filters out:

- System dialogs and sheets
- Floating windows
- Minimized windows
- Menu bar utilities

## Privacy & Permissions

SameDisplay requires Accessibility permissions to:

- Monitor when new windows are created in other applications
- Read window positions and properties
- Move windows to different displays

**The app does NOT:**

- Record or log any window content
- Track your activity
- Send any data over the network
- Store any personal information

The app is not sandboxed to allow Accessibility API access, which is required for system-wide window management.

## Development

### Project Structure

```
SameDisplay/
├── SameDisplayApp.swift              # Main app entry and menu bar UI
├── AppCoordinator.swift             # Central coordinator for all components
├── AccessibilityPermissionManager.swift  # Manages Accessibility permissions
├── ScreenTracker.swift              # Tracks mouse position and display
├── AXWindowObserver.swift          # Observes window creation events
├── WindowMover.swift                # Handles window repositioning logic
├── Info.plist                       # App configuration (LSUIElement = true)
└── SameDisplay.entitlements          # Non-sandboxed entitlements
```

### Key Technologies

- **SwiftUI**: For menu bar UI
- **Accessibility API**: For system-wide window monitoring and manipulation
- **Combine**: For reactive state management
- **NSWorkspace**: For tracking running applications

## Troubleshooting

### Windows aren't moving

1. Check that Accessibility permissions are granted (green checkmark in menu)
2. Try toggling the permission off and on in System Settings
3. Restart the app

### App not appearing in menu bar

- Check that you're running macOS 13.0 or later
- Try quitting all instances and relaunching

### Permission dialog keeps appearing

- Make sure you actually enabled the app in System Settings
- You may need to unlock System Settings (click the lock icon) before toggling

## License

MIT

## Credits

Developed for managing windows across multiple displays efficiently.

