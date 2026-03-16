import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showLogoutConfirm = false
    @State private var showLog = false

    var body: some View {
        Form {
            Section("Hub") {
                if !appState.persistence.hubHostname.isEmpty {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(.secondary)
                        Text(appState.persistence.hubHostname)
                    }
                }

                if !appState.persistence.hubId.isEmpty {
                    HStack {
                        Image(systemName: "tag")
                            .foregroundStyle(.secondary)
                        Text("Hub ID: \(appState.persistence.hubId)")
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Image(systemName: appState.api.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(appState.api.isConnected ? .green : .red)
                    Text(appState.api.isConnected ? "Connected" : "Disconnected")
                }

                if !appState.persistence.claimEmail.isEmpty {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundStyle(.secondary)
                        Text(appState.persistence.claimEmail)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if appState.isWideLayout {
                Section("Display Mode") {
                    Picker("Display Mode", selection: Binding(
                        get: { appState.persistence.displayMode },
                        set: { appState.persistence.displayMode = $0 }
                    )) {
                        Text("General").tag(PersistenceService.DisplayMode.general)
                        Text("Room").tag(PersistenceService.DisplayMode.room)
                        Text("Garage").tag(PersistenceService.DisplayMode.garage)
                    }
                    .pickerStyle(.segmented)

                    if appState.persistence.displayMode == .room {
                        Picker("Assigned Area", selection: Binding(
                            get: { appState.persistence.assignedAreaId },
                            set: { appState.persistence.assignedAreaId = $0 }
                        )) {
                            Text("Not Assigned").tag(nil as UUID?)
                            ForEach(appState.currentAreas) { area in
                                Text(area.name).tag(area.id as UUID?)
                            }
                        }
                    }

                    Text(displayModeDescription)
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

            Section("Sync") {
                HStack {
                    Text("Status")
                    Spacer()
                    if appState.syncService.isSyncing {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Syncing...")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Idle")
                            .foregroundStyle(.secondary)
                    }
                }

                if let lastSync = appState.syncService.lastSyncDate {
                    HStack {
                        Text("Last Sync")
                        Spacer()
                        Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                }

                if let syncError = appState.syncService.syncError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(syncError)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Sync Now") {
                    appState.syncService.triggerSync()
                }
            }

            Section("Account") {
                Button("Sign Out", role: .destructive) {
                    showLogoutConfirm = true
                }
            }

            Section("Debug") {
                Button { showLog = true } label: {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("View Log")
                        Spacer()
                        Text("\(appState.debugLog.count)")
                            .foregroundStyle(.secondary)
                    }
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
        .sheet(isPresented: $showLog) {
            NavigationStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            if appState.debugLog.isEmpty {
                                Text("No log entries yet.")
                                    .foregroundStyle(.secondary)
                                    .padding()
                            }
                            ForEach(Array(appState.debugLog.enumerated()), id: \.offset) { i, entry in
                                Text(entry)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .id(i)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        if let last = appState.debugLog.indices.last {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
                .navigationTitle("Debug Log")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showLog = false }
                    }
                }
            }
        }
        .alert("Sign Out", isPresented: $showLogoutConfirm) {
            Button("Sign Out", role: .destructive) {
                appState.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out? You'll need to re-authenticate with your email.")
        }
    }

    private var displayModeDescription: String {
        switch appState.persistence.displayMode {
        case .general:
            "Shows the full dashboard with sidebar navigation. Best for a central display."
        case .room:
            "Shows only the assigned room's controls. Best for dedicated room displays."
        case .garage:
            "Shows garage controls prominently. Best for a garage display."
        }
    }
}
