import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var serverURL: String = ""
    @State private var showLogoutConfirm = false

    var body: some View {
        Form {
            Section("Server") {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(.secondary)
                    Text(appState.persistence.serverURL.isEmpty ? "Not configured" : appState.persistence.serverURL)
                        .foregroundStyle(appState.persistence.serverURL.isEmpty ? .secondary : .primary)
                }

                HStack {
                    Image(systemName: appState.api.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(appState.api.isConnected ? .green : .red)
                    Text(appState.api.isConnected ? "Connected" : "Disconnected")
                }

                Button("Change Server") {
                    serverURL = appState.persistence.serverURL
                }
            }

            if appState.isIPad {
                Section("iPad Mode") {
                    Picker("Display Mode", selection: Binding(
                        get: { appState.persistence.ipadMode },
                        set: { appState.persistence.ipadMode = $0 }
                    )) {
                        Text("General").tag(PersistenceService.IPadDisplayMode.general)
                        Text("Room").tag(PersistenceService.IPadDisplayMode.room)
                        Text("Garage").tag(PersistenceService.IPadDisplayMode.garage)
                    }
                    .pickerStyle(.segmented)

                    if appState.persistence.ipadMode == .room {
                        Picker("Assigned Area", selection: Binding(
                            get: { appState.persistence.ipadAssignedAreaId },
                            set: { appState.persistence.ipadAssignedAreaId = $0 }
                        )) {
                            Text("Not Assigned").tag(nil as UUID?)
                            ForEach(appState.currentAreas) { area in
                                Text(area.name).tag(area.id as UUID?)
                            }
                        }
                    }

                    Text(ipadModeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Building") {
                if let building = appState.selectedBuilding {
                    HStack {
                        Text("Current")
                        Spacer()
                        Text(building.name)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Areas")
                        Spacer()
                        Text("\(building.areas.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                if appState.buildings.count > 1 {
                    Picker("Active Building", selection: Binding(
                        get: { appState.selectedBuilding },
                        set: { if let b = $0 { appState.selectBuilding(b) } }
                    )) {
                        ForEach(appState.buildings) { building in
                            Text(building.name).tag(building as Building?)
                        }
                    }
                }
            }

            Section("Account") {
                Button("Sign Out", role: .destructive) {
                    showLogoutConfirm = true
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Sign Out", isPresented: $showLogoutConfirm) {
            Button("Sign Out", role: .destructive) {
                appState.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    private var ipadModeDescription: String {
        switch appState.persistence.ipadMode {
        case .general:
            "Shows the full dashboard with sidebar navigation. Best for a central living room iPad."
        case .room:
            "Shows only the assigned room's controls. Best for iPads mounted in specific rooms."
        case .garage:
            "Shows garage controls prominently. Best for an iPad in the garage."
        }
    }
}
