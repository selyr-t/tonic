import SwiftUI

@main
struct tonicApp: App {
    var body: some Scene {
        #if os(macOS)
        // The main window does not open at launch; the splash window opens it after 3 seconds.
        // It stays the first scene, so the app keeps running after the splash window closes.
        WindowGroup(id: Splash.mainWindowID) {
            ContentView()
        }
        // 425 points wide and as tall as the screen's visible area (the screen without the menu
        // bar and the Dock).
        .defaultSize(width: 425, height: NSScreen.main?.visibleFrame.height ?? 900)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        // A borderless window that is exactly the size of the image, centered on the screen.
        Window("tonic", id: Splash.windowID) {
            SplashView()
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.presented)
        .restorationBehavior(.disabled)
        .defaultWindowPlacement { content, context in
            let display = context.defaultDisplay.visibleRect
            let size = content.sizeThatFits(.unspecified)
            let position = CGPoint(x: display.midX - size.width / 2,
                                   y: display.midY - size.height / 2)
            return WindowPlacement(position, size: size)
        }
        #else
        WindowGroup {
            SplashGate()
        }
        #endif
    }
}
