import Foundation
import SwiftUI

@MainActor
@Observable
final class AppState {
    var buildings: [Building] = []
    var selectedBuilding: Building?
    var selectedArea: Area?

    var isLoading = false
    var errorMessage: String?
    var showError = false
    var isAuthenticated = false
    var showLogin = false
    var showOnboarding = false

    let api = APIService.shared
    let persistence = PersistenceService.shared

    var isWideLayout: Bool {
        PlatformService.isWideDevice
    }

    var currentAreas: [Area] {
        selectedBuilding?.areas.sorted(by: { $0.sortOrder < $1.sortOrder }) ?? []
    }

    var garageAreas: [Area] {
        currentAreas.filter { $0.mode == .garage }
    }

    var roomAreas: [Area] {
        currentAreas.filter { $0.mode == .room }
    }

    var generalAreas: [Area] {
        currentAreas.filter { $0.mode == .general }
    }

    // MARK: - Lifecycle

    func initialize() async {
        let serverURL = persistence.serverURL
        guard !serverURL.isEmpty else {
            showOnboarding = true
            return
        }

        api.configure(
            baseURL: serverURL,
            accessToken: persistence.accessToken,
            refreshToken: persistence.refreshToken
        )

        let connected = await api.checkConnection()
        if !connected {
            setError("Cannot connect to Zman server.")
            return
        }

        if persistence.accessToken.isEmpty {
            showLogin = true
            return
        }

        isAuthenticated = true
        await loadBuildings()
    }

    // MARK: - Data Loading

    func loadBuildings() async {
        isLoading = true
        defer { isLoading = false }

        do {
            buildings = try await api.fetchBuildings()
            // Restore last selected building
            if let savedId = persistence.selectedBuildingId {
                selectedBuilding = buildings.first(where: { $0.id == savedId })
            }
            // Default to first building
            if selectedBuilding == nil {
                selectedBuilding = buildings.first
            }
            if let building = selectedBuilding {
                persistence.selectedBuildingId = building.id
            }
        } catch {
            setError(error.localizedDescription)
        }
    }

    func refreshCurrentBuilding() async {
        guard let building = selectedBuilding else { return }
        do {
            selectedBuilding = try await api.fetchBuilding(id: building.id)
            if let idx = buildings.firstIndex(where: { $0.id == building.id }) {
                buildings[idx] = selectedBuilding!
            }
        } catch {
            setError(error.localizedDescription)
        }
    }

    func selectBuilding(_ building: Building) {
        selectedBuilding = building
        selectedArea = nil
        persistence.selectedBuildingId = building.id
        persistence.selectedAreaId = nil
    }

    func selectArea(_ area: Area) {
        selectedArea = area
        persistence.selectedAreaId = area.id
    }

    // MARK: - Widget Actions

    func toggleWidget(_ widget: DeviceWidget) async {
        guard let building = selectedBuilding else { return }
        do {
            let result = try await api.toggleWidget(id: widget.id)
            if result.success {
                await refreshCurrentBuilding()
            } else {
                setError(result.message ?? "Failed to toggle \(widget.name)")
            }
        } catch {
            setError(error.localizedDescription)
            _ = building // suppress unused warning
        }
    }

    func sendWidgetAction(_ widget: DeviceWidget, action: String, parameters: [String: String]? = nil) async {
        do {
            let result = try await api.setWidgetState(id: widget.id, action: action, parameters: parameters)
            if result.success {
                await refreshCurrentBuilding()
            } else {
                setError(result.message ?? "Action failed for \(widget.name)")
            }
        } catch {
            setError(error.localizedDescription)
        }
    }

    // MARK: - Auth

    func login(username: String, password: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let token = try await api.login(username: username, password: password)
            persistence.accessToken = token.accessToken
            persistence.refreshToken = token.refreshToken
            isAuthenticated = true
            showLogin = false
            await loadBuildings()
        } catch {
            setError(error.localizedDescription)
        }
    }

    func logout() {
        api.logout()
        persistence.accessToken = ""
        persistence.refreshToken = ""
        isAuthenticated = false
        buildings = []
        selectedBuilding = nil
        selectedArea = nil
        showLogin = true
    }

    func configureServer(url: String) {
        persistence.serverURL = url
        api.configure(baseURL: url)
        persistence.onboardingComplete = true
        showOnboarding = false
        showLogin = true
    }

    // MARK: - Error Handling

    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
