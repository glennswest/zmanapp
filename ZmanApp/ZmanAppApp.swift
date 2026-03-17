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
                .frame(minWidth: 420, minHeight: 600)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 460, height: 800)
        #endif
        #if os(macOS)
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Refresh") {
                    Task { await appState.refreshCurrentBuilding() }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
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
