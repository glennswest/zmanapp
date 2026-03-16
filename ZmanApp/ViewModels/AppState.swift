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
    var showOnboarding = false

    // Debug log
    var debugLog: [String] = []

    func log(_ message: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        debugLog.append("[\(ts)] \(message)")
        if debugLog.count > 50 { debugLog.removeFirst() }
    }

    // Claim flow state
    enum ClaimPhase {
        case idle
        case enterEmail
        case polling
        case claiming
        case complete
    }
    var claimPhase: ClaimPhase = .idle
    var claimEmail: String = ""
    var pendingClaims: [HubClaim] = []

    let api = APIService.shared
    let cloud = CloudService.shared
    let persistence = PersistenceService.shared
    let syncService = SyncService()

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
        // Check for existing API key auth
        let apiKey = persistence.apiKey
        let hubHostname = persistence.hubHostname
        if !apiKey.isEmpty && !hubHostname.isEmpty {
            let serverURL = "https://\(hubHostname)"
            api.configure(baseURL: serverURL, apiKey: apiKey)

            let connected = await api.checkConnection()
            if connected {
                isAuthenticated = true
                await loadBuildings()
                startSyncService()
                return
            }
        }

        // Legacy: check for bearer token auth
        let serverURL = persistence.serverURL
        if !serverURL.isEmpty && !persistence.accessToken.isEmpty {
            api.configure(
                baseURL: serverURL,
                accessToken: persistence.accessToken,
                refreshToken: persistence.refreshToken
            )
            let connected = await api.checkConnection()
            if connected {
                isAuthenticated = true
                await loadBuildings()
                startSyncService()
                return
            }
        }

        // No valid auth — show onboarding
        showOnboarding = true
    }

    // MARK: - Claim Flow

    func startClaimFlow(email: String) async {
        claimEmail = email
        isLoading = true
        defer { isLoading = false }

        log("Connect: sending magic link to \(email)")
        do {
            _ = try await cloud.connect(email: email)
            log("Connect: success, starting poll")
            claimPhase = .polling
            persistence.claimEmail = email
            await pollForClaim()
        } catch {
            log("Connect: FAILED — \(error.localizedDescription)")
            setError(error.localizedDescription)
        }
    }

    private var pollTask: Task<Void, Never>?

    func pollForClaim() async {
        pollTask?.cancel()
        claimPhase = .polling

        pollTask = Task { [weak self] in
            guard let self else { return }
            var consecutiveErrors = 0
            let maxErrors = 5
            let maxPollDuration: TimeInterval = 300 // 5 minutes
            let startTime = Date()

            while !Task.isCancelled {
                // Give up after 5 minutes of polling
                if Date().timeIntervalSince(startTime) > maxPollDuration {
                    self.setError("Timed out waiting for email confirmation. Please try again.")
                    return
                }

                do {
                    let response = try await self.cloud.poll(email: self.claimEmail)
                    consecutiveErrors = 0 // reset on success
                    if response.status == "ready", let claims = response.claims, !claims.isEmpty {
                        self.log("Poll: ready — \(claims.count) hub(s)")
                        for c in claims {
                            self.log("  hub: \(c.hostname) id: \(c.hubId) token: \(c.claimToken.prefix(12))...")
                        }
                        self.pendingClaims = claims
                        self.claimPhase = .claiming
                        // Auto-claim the first hub
                        await self.exchangeClaim(claims[0])
                        return
                    }
                    // Still pending — wait before next poll
                    try await Task.sleep(for: .seconds(3))
                } catch is CancellationError {
                    return
                } catch {
                    consecutiveErrors += 1
                    if consecutiveErrors >= maxErrors {
                        if !Task.isCancelled {
                            self.setError(error.localizedDescription)
                        }
                        return
                    }
                    // Transient error — back off and retry
                    try? await Task.sleep(for: .seconds(Double(consecutiveErrors) * 2))
                }
            }
        }
        await pollTask?.value
    }

    func cancelClaim() {
        pollTask?.cancel()
        pollTask = nil
        claimPhase = .enterEmail
    }

    func exchangeClaim(_ claim: HubClaim) async {
        claimPhase = .claiming
        isLoading = true
        defer { isLoading = false }

        let hubURL = "https://\(claim.hostname)"
        log("Claim: POST \(hubURL)/api/v1/auth/claim")

        do {
            let result = try await cloud.claim(hubURL: hubURL, claimToken: claim.claimToken)
            log("Claim: success — key=\(result.keyId) hub=\(result.hubId)")

            // Store credentials
            persistence.apiKey = result.key
            persistence.hubId = result.hubId
            persistence.hubHostname = result.hostname
            persistence.serverURL = hubURL
            persistence.onboardingComplete = true

            // Configure API service
            api.configure(baseURL: hubURL, apiKey: result.key)

            claimPhase = .complete
            isAuthenticated = true
            showOnboarding = false

            await loadBuildings()
            startSyncService()
        } catch {
            log("Claim: FAILED — \(error.localizedDescription)")
            setError("Claim failed: \(error.localizedDescription)")
            claimPhase = .enterEmail
        }
    }

    // MARK: - Sync

    private func startSyncService() {
        syncService.startSync(api: api) { [weak self] buildings in
            self?.applySyncedData(buildings)
        }
    }

    private func applySyncedData(_ freshBuildings: [Building]) {
        let previousSelectedId = selectedBuilding?.id
        buildings = freshBuildings

        // Preserve selection
        if let prevId = previousSelectedId {
            selectedBuilding = freshBuildings.first(where: { $0.id == prevId })
        }
        if selectedBuilding == nil {
            selectedBuilding = freshBuildings.first
        }
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

    func logout() {
        syncService.stopSync()
        api.logout()
        persistence.resetAll()
        isAuthenticated = false
        buildings = []
        selectedBuilding = nil
        selectedArea = nil
        claimPhase = .enterEmail
        claimEmail = ""
        pendingClaims = []
        showOnboarding = true
    }

    // MARK: - Error Handling

    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
