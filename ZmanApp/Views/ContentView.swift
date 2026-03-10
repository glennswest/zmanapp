import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.showOnboarding {
                OnboardingView()
            } else if appState.showLogin {
                LoginView()
            } else if appState.isWideLayout {
                PadDashboardView()
            } else {
                PhoneDashboardView()
            }
        }
        .alert("Error", isPresented: Bindable(appState).showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.errorMessage ?? "An unknown error occurred.")
        }
        .task {
            await appState.initialize()
        }
    }
}
