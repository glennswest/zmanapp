import SwiftUI

struct PhoneDashboardView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Dashboard tabs
                dashboardTabs

                // Widget content
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(appState.currentDashboardWidgets) { widget in
                            DashboardWidgetView(widget: widget)
                        }
                    }
                    .padding(12)
                }
                .background(AppTheme.dashBackground)
            }
            .background(AppTheme.dashBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Zman")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.dashBlue)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(AppTheme.dashSecondary)
                    }
                }
            }
            .toolbarBackground(AppTheme.dashBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .refreshable {
                await appState.refreshCurrentBuilding()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Dashboard Tabs

    private var dashboardTabs: some View {
        HStack(spacing: 0) {
            ForEach(appState.dashboardIds, id: \.self) { dashId in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.selectedDashboard = dashId
                    }
                } label: {
                    Text(appState.dashboardName(dashId))
                        .font(.subheadline)
                        .fontWeight(appState.selectedDashboard == dashId ? .semibold : .regular)
                        .foregroundStyle(
                            appState.selectedDashboard == dashId
                                ? AppTheme.dashBlue
                                : AppTheme.dashSecondary
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            if appState.selectedDashboard == dashId {
                                Rectangle()
                                    .fill(AppTheme.dashBlue)
                                    .frame(height: 2)
                            }
                        }
                }
            }
            Spacer()
        }
        .background(AppTheme.dashBackground)
        .overlay(alignment: .bottom) {
            Divider().background(AppTheme.dashBorder)
        }
    }

    private var gridColumns: [GridItem] {
        let isWide = PlatformService.isWideDevice
        let columns = isWide ? 4 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)
    }
}

// MARK: - Dashboard Widget View (routes to correct card type)

struct DashboardWidgetView: View {
    let widget: DeviceWidget
    @Environment(AppState.self) private var appState

    var body: some View {
        switch widget.widgetType {
        case .garage:
            GarageDoorWidget(widget: widget) {
                Task { await appState.toggleWidget(widget) }
            }
        case .thermostat:
            ThermostatWidget(widget: widget)
        case .sensor:
            SensorWidget(widget: widget)
        case .weather:
            WeatherWidget(widget: widget)
        default:
            GenericWidget(widget: widget)
        }
    }
}

// MARK: - Garage Door Widget

struct GarageDoorWidget: View {
    let widget: DeviceWidget
    let onToggle: () -> Void

    private var doorState: String { widget.state ?? "unknown" }
    private var isClosed: Bool { doorState == "closed" }
    private var isMoving: Bool { doorState == "opening" || doorState == "closing" }

    private var borderColor: Color {
        switch doorState {
        case "open": AppTheme.dashGreen
        case "opening", "closing": AppTheme.dashYellow
        default: AppTheme.dashBorder
        }
    }

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 6) {
                // Garage door SVG-style icon
                GarageDoorIcon(state: doorState)
                    .frame(width: 48, height: 48)

                // State text
                Text(doorState)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.dashSecondary)

                // Label
                Text(widget.label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.dashText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(AppTheme.dashCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isMoving ? 2 : 1)
            )
            .opacity(isMoving ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isMoving)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Garage Door Icon (SVG-style panels)

struct GarageDoorIcon: View {
    let state: String

    private var panelColor: Color {
        switch state {
        case "open": AppTheme.dashGreen
        case "opening", "closing": AppTheme.dashYellow
        default: Color(red: 0.282, green: 0.310, blue: 0.345) // #484f58
        }
    }

    private var borderStroke: Color {
        switch state {
        case "open": AppTheme.dashGreen
        case "opening", "closing": AppTheme.dashYellow
        default: AppTheme.dashBorder
        }
    }

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // Outer frame
            let frame = RoundedRectangle(cornerRadius: w * 0.08)
                .path(in: CGRect(x: w * 0.08, y: w * 0.08, width: w * 0.84, height: h * 0.84))
            context.fill(frame, with: .color(AppTheme.dashCard))
            context.stroke(frame, with: .color(borderStroke), lineWidth: 1.5)

            let panelX = w * 0.17
            let panelW = w * 0.66
            let panelH = h * 0.125
            let gap = h * 0.04

            if state == "open" {
                // Open: top panel is green, rest are dashed outlines
                let topPanel = RoundedRectangle(cornerRadius: 2)
                    .path(in: CGRect(x: panelX, y: h * 0.17, width: panelW, height: panelH))
                context.fill(topPanel, with: .color(panelColor))

                for i in 1...3 {
                    let y = h * 0.17 + Double(i) * (panelH + gap)
                    let rect = CGRect(x: panelX, y: y, width: panelW, height: panelH)
                    let panel = RoundedRectangle(cornerRadius: 2).path(in: rect)
                    context.stroke(panel, with: .color(panelColor.opacity(0.3)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            } else {
                // Closed / moving: 4 solid panels
                for i in 0...3 {
                    let y = h * 0.17 + Double(i) * (panelH + gap)
                    let rect = CGRect(x: panelX, y: y, width: panelW, height: panelH)
                    let panel = RoundedRectangle(cornerRadius: 2).path(in: rect)
                    context.fill(panel, with: .color(panelColor))
                }
            }
        }
    }
}

// MARK: - Sensor Widget (Temperature / Humidity)

struct SensorWidget: View {
    let widget: DeviceWidget

    var body: some View {
        VStack(spacing: 4) {
            // Temperature
            Text(widget.formatTemp(widget.temperature))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.dashBlue)

            // Humidity
            if let hum = widget.humidity {
                Text(widget.formatHumidity(hum))
                    .font(.caption)
                    .foregroundStyle(AppTheme.dashGreen)
            }

            // Label
            Text(widget.label)
                .font(.caption)
                .foregroundStyle(AppTheme.dashSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .dashCardStyle()
    }
}

// MARK: - Thermostat Widget (multi-tile)

struct ThermostatWidget: View {
    let widget: DeviceWidget
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                // Setpoint with arrows
                VStack(spacing: 2) {
                    Text(widget.formatTemp(widget.desiredTemp))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.dashBlue)

                    HStack(spacing: 12) {
                        Button {
                            Task { await appState.sendWidgetCommand(widget, command: "set_desired_temp_up") }
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.dashSecondary)
                        }
                        Button {
                            Task { await appState.sendWidgetCommand(widget, command: "set_desired_temp_down") }
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.dashSecondary)
                        }
                    }
                }

                Divider()
                    .frame(height: 40)
                    .background(AppTheme.dashBorder)

                // Room temp + humidity
                VStack(spacing: 2) {
                    Text(widget.formatTemp(widget.roomTemp))
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.dashText)

                    if let hum = widget.humidity {
                        HStack(spacing: 2) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(AppTheme.dashGreen)
                            Text(widget.formatHumidity(hum))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.dashGreen)
                        }
                    }
                    Text("Room")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.dashSecondary)
                }
            }

            // Label
            Text(widget.label)
                .font(.caption2)
                .foregroundStyle(AppTheme.dashSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .dashCardStyle()
    }
}

// MARK: - HVAC Mode Widget (fan mode display)

struct HVACModeWidget: View {
    let widget: DeviceWidget
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "fan.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.dashSecondary)

            Text(widget.fanMode ?? "--")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.dashText)

            Button {
                Task { await appState.sendWidgetCommand(widget, command: "set_fan_mode") }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundStyle(AppTheme.dashBlue)
            }
        }
        .frame(maxWidth: .infinity)
        .dashCardStyle()
    }
}

// MARK: - Weather Widget

struct WeatherWidget: View {
    let widget: DeviceWidget

    var body: some View {
        VStack(spacing: 4) {
            if let temp = widget.temperature {
                Text(widget.formatTemp(temp))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.dashBlue)
            }

            if let hum = widget.humidity {
                Text(widget.formatHumidity(hum))
                    .font(.caption)
                    .foregroundStyle(AppTheme.dashGreen)
            }

            if let wind = widget.windSpeed {
                HStack(spacing: 2) {
                    Image(systemName: "wind")
                        .font(.system(size: 8))
                    Text(String(format: "%.0f mph", wind))
                }
                .font(.caption2)
                .foregroundStyle(AppTheme.dashSecondary)
            }

            Text(widget.label)
                .font(.caption)
                .foregroundStyle(AppTheme.dashSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .dashCardStyle()
    }
}

// MARK: - Generic Widget (fallback)

struct GenericWidget: View {
    let widget: DeviceWidget

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "square.grid.2x2")
                .font(.title3)
                .foregroundStyle(AppTheme.dashSecondary)

            Text(widget.label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.dashText)
                .lineLimit(1)

            if let state = widget.state {
                Text(state)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.dashSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .dashCardStyle()
    }
}
