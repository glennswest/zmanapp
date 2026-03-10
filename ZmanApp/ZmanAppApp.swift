import SwiftUI

@main
struct ZmanAppApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                #if os(macOS)
                .frame(minWidth: 800, minHeight: 500)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 700)
        #endif
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                appState.syncService.isAppActive = true
            case .background, .inactive:
                appState.syncService.isAppActive = false
            @unknown default:
                break
            }
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .environment(appState)
        }
        #endif
    }
}
