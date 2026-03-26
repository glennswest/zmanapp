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
    var demoMode = false

    // Dashboard tab state
    var selectedDashboard: String = "default"

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

    // MARK: - Dashboard Widget Access

    /// All widgets from the selected building, flattened from all areas
    var allWidgets: [DeviceWidget] {
        selectedBuilding?.areas.flatMap(\.widgets) ?? []
    }

    /// Unique dashboard IDs, with "default" first
    var dashboardIds: [String] {
        var seen = Set<String>()
        var ids: [String] = []
        for widget in allWidgets.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            if seen.insert(widget.dashboardId).inserted {
                ids.append(widget.dashboardId)
            }
        }
        // Ensure "default" is always first if present
        if let idx = ids.firstIndex(of: "default"), idx > 0 {
            ids.remove(at: idx)
            ids.insert("default", at: 0)
        }
        return ids
    }

    /// Display name for a dashboard ID
    func dashboardName(_ id: String) -> String {
        switch id {
        case "default": "Main"
        case "weather": "Weather"
        default: id.capitalized
        }
    }

    /// Widgets for the currently selected dashboard, sorted by order
    var currentDashboardWidgets: [DeviceWidget] {
        allWidgets
            .filter { $0.dashboardId == selectedDashboard }
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    /// Garage door widgets on current dashboard
    var garageWidgets: [DeviceWidget] {
        currentDashboardWidgets.filter { $0.widgetType == .garage }
    }

    /// Temperature/humidity sensor widgets on current dashboard
    var sensorWidgets: [DeviceWidget] {
        currentDashboardWidgets.filter { $0.widgetType == .sensor }
    }

    /// Thermostat/HVAC widgets on current dashboard
    var thermostatWidgets: [DeviceWidget] {
        currentDashboardWidgets.filter { $0.widgetType == .thermostat }
    }

    /// Weather widgets on current dashboard
    var weatherWidgets: [DeviceWidget] {
        currentDashboardWidgets.filter { $0.widgetType == .weather }
    }

    // MARK: - Legacy area access (for iPad modes)

    var currentAreas: [Area] {
        selectedBuilding?.areas.sorted(by: { $0.sortOrder < $1.sortOrder }) ?? []
    }

    var garageAreas: [Area] {
        currentAreas.filter { $0.mode == .garage }
    }

    // MARK: - Lifecycle

    func initialize() async {
        // Check for existing API key auth
        let apiKey = persistence.apiKey
        let hubHostname = persistence.hubHostname
        if !apiKey.isEmpty && !hubHostname.isEmpty {
            let serverURL = "https://\(hubHostname)"
            log("Init: API key auth → \(serverURL)")
            api.configure(baseURL: serverURL, apiKey: apiKey)

            let connected = await api.checkConnection()
            log("Init: health check → \(connected ? "OK" : "FAILED")")
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
            log("Init: legacy token auth → \(serverURL)")
            api.configure(
                baseURL: serverURL,
                accessToken: persistence.accessToken,
                refreshToken: persistence.refreshToken
            )
            let connected = await api.checkConnection()
            log("Init: health check → \(connected ? "OK" : "FAILED")")
            if connected {
                isAuthenticated = true
                await loadBuildings()
                startSyncService()
                return
            }
        }

        // No valid auth — show onboarding
        log("Init: no valid auth, showing onboarding")
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
            let maxPollDuration: TimeInterval = 300
            let startTime = Date()

            while !Task.isCancelled {
                if Date().timeIntervalSince(startTime) > maxPollDuration {
                    self.setError("Timed out waiting for email confirmation. Please try again.")
                    return
                }

                do {
                    let response = try await self.cloud.poll(email: self.claimEmail)
                    consecutiveErrors = 0
                    if response.status == "ready", let claims = response.claims, !claims.isEmpty {
                        self.log("Poll: ready — \(claims.count) hub(s)")
                        for c in claims {
                            self.log("  hub: \(c.hostname) id: \(c.hubId) token: \(c.claimToken.prefix(12))...")
                        }
                        self.pendingClaims = claims
                        self.claimPhase = .claiming
                        await self.exchangeClaim(claims[0])
                        return
                    }
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

            persistence.apiKey = result.key
            persistence.hubId = result.hubId
            persistence.hubHostname = result.hostname
            persistence.serverURL = hubURL
            persistence.onboardingComplete = true

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

        log("LoadBuildings: GET /api/v1/buildings")
        do {
            buildings = try await api.fetchBuildings()
            log("LoadBuildings: OK — \(buildings.count) building(s)")
            for b in buildings {
                let widgetCount = b.areas.flatMap(\.widgets).count
                log("  building '\(b.name)': \(b.areas.count) area(s), \(widgetCount) widget(s)")
            }

            if let savedId = persistence.selectedBuildingId {
                selectedBuilding = buildings.first(where: { $0.id == savedId })
            }
            if selectedBuilding == nil {
                selectedBuilding = buildings.first
            }
            if let building = selectedBuilding {
                persistence.selectedBuildingId = building.id
            }

            // Default to first dashboard
            if !dashboardIds.isEmpty && !dashboardIds.contains(selectedDashboard) {
                selectedDashboard = dashboardIds.first ?? "default"
            }
        } catch {
            log("LoadBuildings: FAILED — \(error.localizedDescription)")
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
        log("Toggle: \(widget.deviceId) (widget: \(widget.id))")

        if demoMode {
            mutateWidgetProperties(widgetId: widget.id) { props in
                switch widget.widgetType {
                case .garage:
                    let current = props["state"]?.stringValue ?? "closed"
                    props["state"] = .string(current == "closed" ? "open" : "closed")
                case .plug:
                    let current = props["on_off"]?.boolValue ?? false
                    props["on_off"] = .bool(!current)
                default:
                    break
                }
            }
            return
        }

        do {
            try await api.sendDeviceCommand(deviceId: widget.deviceId, command: "toggle")
            await refreshCurrentBuilding()
        } catch {
            log("Toggle FAILED: \(error.localizedDescription)")
            setError(error.localizedDescription)
        }
    }

    func sendWidgetCommand(_ widget: DeviceWidget, command: String) async {
        log("Command: \(command) → \(widget.deviceId)")

        if demoMode {
            mutateWidgetProperties(widgetId: widget.id) { props in
                switch command {
                case "temp_up":
                    let current = props["desired_temp"]?.doubleValue ?? 22.0
                    props["desired_temp"] = .number(current + 0.5)
                case "temp_down":
                    let current = props["desired_temp"]?.doubleValue ?? 22.0
                    props["desired_temp"] = .number(current - 0.5)
                case "fan_mode":
                    let modes = ["auto", "low", "medium", "high"]
                    let current = props["fan_mode"]?.stringValue ?? "auto"
                    let idx = modes.firstIndex(of: current) ?? 0
                    props["fan_mode"] = .string(modes[(idx + 1) % modes.count])
                default:
                    break
                }
            }
            return
        }

        do {
            try await api.sendDeviceCommand(deviceId: widget.deviceId, command: command)
            await refreshCurrentBuilding()
        } catch {
            log("Command FAILED: \(error.localizedDescription)")
            setError(error.localizedDescription)
        }
    }

    // MARK: - Auth

    func logout() {
        syncService.stopSync()
        api.logout()
        persistence.resetAll()
        demoMode = false
        isAuthenticated = false
        buildings = []
        selectedBuilding = nil
        selectedArea = nil
        claimPhase = .enterEmail
        claimEmail = ""
        pendingClaims = []
        showOnboarding = true
    }

    // MARK: - Demo Mode

    func enterDemoMode() {
        log("Demo: entering demo mode")
        demoMode = true
        buildings = createDemoBuildings()
        selectedBuilding = buildings.first
        selectedDashboard = "default"
        isAuthenticated = true
        showOnboarding = false
        claimPhase = .complete
    }

    private func createDemoBuildings() -> [Building] {
        // Main dashboard widgets
        let garage1 = DeviceWidget(
            id: "demo-garage-1", deviceId: "virtual.esphome.main_door",
            label: "Main Door", dashboardId: "default",
            properties: ["state": .string("closed")],
            sortOrder: 0, widgetTypeRaw: "garage"
        )
        let garage2 = DeviceWidget(
            id: "demo-garage-2", deviceId: "virtual.esphome.side_door",
            label: "Side Door", dashboardId: "default",
            properties: ["state": .string("open")],
            sortOrder: 1, widgetTypeRaw: "garage"
        )
        let thermostat = DeviceWidget(
            id: "demo-hvac-1", deviceId: "virtual.hvac.living_room",
            label: "Living Room", dashboardId: "default",
            properties: [
                "desired_temp": .number(22.5),
                "room_temp": .number(21.2),
                "humidity": .number(45),
                "fan_mode": .string("auto"),
                "thermostat_mode": .string("heat"),
                "thermostat_state": .string("idle"),
                "setpoint": .number(23.0)
            ],
            sortOrder: 2, widgetTypeRaw: "hvac"
        )
        let sensor1 = DeviceWidget(
            id: "demo-sensor-1", deviceId: "zwave.hallway",
            label: "Hallway", dashboardId: "default",
            properties: ["temperature": .number(20.5), "humidity": .number(42)],
            sortOrder: 3, widgetTypeRaw: "sensor"
        )
        let sensor2 = DeviceWidget(
            id: "demo-sensor-2", deviceId: "zwave.bedroom",
            label: "Bedroom", dashboardId: "default",
            properties: ["temperature": .number(19.8), "humidity": .number(38)],
            sortOrder: 4, widgetTypeRaw: "sensor"
        )
        let sensor3 = DeviceWidget(
            id: "demo-sensor-3", deviceId: "zwave.kitchen",
            label: "Kitchen", dashboardId: "default",
            properties: ["temperature": .number(21.0), "humidity": .number(55)],
            sortOrder: 5, widgetTypeRaw: "sensor"
        )
        let plug1 = DeviceWidget(
            id: "demo-plug-1", deviceId: "virtual.esphome.desk_lamp",
            label: "Desk Lamp", dashboardId: "default",
            properties: ["on_off": .bool(true)],
            sortOrder: 6, widgetTypeRaw: "plug"
        )

        // Weather dashboard widgets — Algood
        let algoodCurrent = DeviceWidget(
            id: "demo-weather-algood-current", deviceId: "virtual.weather.algood",
            label: "Algood", dashboardId: "weather",
            properties: [
                "temperature": .number(18),
                "humidity": .number(52),
                "condition": .string("Partly Cloudy"),
                "weather_code": .number(2),
                "wind_speed": .number(12),
                "wind_direction": .number(220),
                "today_high": .number(24), "today_low": .number(12),
                "tomorrow_high": .number(22), "tomorrow_low": .number(10)
            ],
            sortOrder: 0, widgetTypeRaw: "weather", widgetProperty: nil
        )
        let algoodToday = DeviceWidget(
            id: "demo-weather-algood-today", deviceId: "virtual.weather.algood",
            label: "Algood", dashboardId: "weather",
            properties: algoodCurrent.properties,
            sortOrder: 1, widgetTypeRaw: "forecast", widgetProperty: "today"
        )
        let algoodTomorrow = DeviceWidget(
            id: "demo-weather-algood-tomorrow", deviceId: "virtual.weather.algood",
            label: "Algood", dashboardId: "weather",
            properties: algoodCurrent.properties,
            sortOrder: 2, widgetTypeRaw: "forecast", widgetProperty: "tomorrow"
        )

        // Weather dashboard widgets — Cookeville
        let cookevilleCurrent = DeviceWidget(
            id: "demo-weather-cookeville-current", deviceId: "virtual.weather.cookeville",
            label: "Cookeville", dashboardId: "weather",
            properties: [
                "temperature": .number(17),
                "humidity": .number(48),
                "condition": .string("Clear"),
                "weather_code": .number(0),
                "wind_speed": .number(8),
                "wind_direction": .number(180),
                "today_high": .number(23), "today_low": .number(11),
                "tomorrow_high": .number(21), "tomorrow_low": .number(9)
            ],
            sortOrder: 3, widgetTypeRaw: "weather", widgetProperty: nil
        )
        let cookevilleToday = DeviceWidget(
            id: "demo-weather-cookeville-today", deviceId: "virtual.weather.cookeville",
            label: "Cookeville", dashboardId: "weather",
            properties: cookevilleCurrent.properties,
            sortOrder: 4, widgetTypeRaw: "forecast", widgetProperty: "today"
        )
        let cookevilleTomorrow = DeviceWidget(
            id: "demo-weather-cookeville-tomorrow", deviceId: "virtual.weather.cookeville",
            label: "Cookeville", dashboardId: "weather",
            properties: cookevilleCurrent.properties,
            sortOrder: 5, widgetTypeRaw: "forecast", widgetProperty: "tomorrow"
        )

        let mainArea = Area(
            id: "demo-area-main", name: "Main",
            icon: "square.grid.2x2.fill", mode: .general,
            widgets: [garage1, garage2, thermostat, sensor1, sensor2, sensor3, plug1,
                      algoodCurrent, algoodToday, algoodTomorrow,
                      cookevilleCurrent, cookevilleToday, cookevilleTomorrow],
            sortOrder: 0
        )

        return [Building(id: "demo-building", name: "Demo Home", areas: [mainArea])]
    }

    /// Mutate a widget's properties in-place and reassign selectedBuilding to trigger SwiftUI refresh
    private func mutateWidgetProperties(widgetId: String, update: (inout [String: PropertyValue]) -> Void) {
        guard var building = selectedBuilding else { return }
        for ai in building.areas.indices {
            for wi in building.areas[ai].widgets.indices {
                if building.areas[ai].widgets[wi].id == widgetId {
                    update(&building.areas[ai].widgets[wi].properties)
                    if let bi = buildings.firstIndex(where: { $0.id == building.id }) {
                        buildings[bi] = building
                    }
                    selectedBuilding = building
                    return
                }
            }
        }
    }

    // MARK: - Error Handling

    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
