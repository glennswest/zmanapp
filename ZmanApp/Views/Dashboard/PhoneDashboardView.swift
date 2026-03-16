import SwiftUI

struct PhoneDashboardView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dashboardTabs

                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(dashboardCells) { cell in
                            DashboardCellView(cell: cell)
                        }
                    }
                    .padding(10)
                }
                .background(AppTheme.dashBackground)
            }
            .background(AppTheme.dashBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Zman")
                        .font(.subheadline)
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
                        .font(.caption)
                        .fontWeight(appState.selectedDashboard == dashId ? .semibold : .regular)
                        .foregroundStyle(
                            appState.selectedDashboard == dashId
                                ? AppTheme.dashBlue
                                : AppTheme.dashSecondary
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
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

    // MARK: - Dashboard Cells

    /// Expand widgets into dashboard cells — thermostats become 3 cells
    private var dashboardCells: [DashboardCell] {
        var cells: [DashboardCell] = []
        for widget in appState.currentDashboardWidgets {
            if widget.widgetType == .thermostat {
                cells.append(.thermostatSetpoint(widget))
                cells.append(.thermostatRoom(widget))
                cells.append(.thermostatFan(widget))
            } else if widget.widgetType == .weather {
                cells.append(.widget(widget))
            } else {
                cells.append(.widget(widget))
            }
        }
        return cells
    }

    private var gridColumns: [GridItem] {
        let isWide = PlatformService.isWideDevice
        let columns = isWide ? 6 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
    }
}

// MARK: - Dashboard Cell (one grid item)

enum DashboardCell: Identifiable {
    case widget(DeviceWidget)
    case thermostatSetpoint(DeviceWidget)
    case thermostatRoom(DeviceWidget)
    case thermostatFan(DeviceWidget)

    var id: String {
        switch self {
        case .widget(let w): w.id
        case .thermostatSetpoint(let w): "\(w.id)-sp"
        case .thermostatRoom(let w): "\(w.id)-rm"
        case .thermostatFan(let w): "\(w.id)-fn"
        }
    }
}

struct DashboardCellView: View {
    let cell: DashboardCell
    @Environment(AppState.self) private var appState

    var body: some View {
        switch cell {
        case .widget(let w):
            widgetView(w)
        case .thermostatSetpoint(let w):
            ThermostatSetpointTile(widget: w)
        case .thermostatRoom(let w):
            ThermostatRoomTile(widget: w)
        case .thermostatFan(let w):
            ThermostatFanTile(widget: w)
        }
    }

    @ViewBuilder
    private func widgetView(_ widget: DeviceWidget) -> some View {
        switch widget.widgetType {
        case .garage:
            GarageDoorWidget(widget: widget) {
                Task { await appState.toggleWidget(widget) }
            }
        case .sensor:
            SensorWidget(widget: widget)
        case .weather:
            weatherView(widget)
        case .thermostat:
            GenericWidget(widget: widget)
        case .plug, .unknown:
            GenericWidget(widget: widget)
        }
    }

    @ViewBuilder
    private func weatherView(_ widget: DeviceWidget) -> some View {
        let prop = widget.widgetProperty ?? ""
        if prop == "today" {
            WeatherForecastWidget(widget: widget, period: "Today",
                                  high: widget.properties["todayHigh"]?.doubleValue,
                                  low: widget.properties["todayLow"]?.doubleValue)
        } else if prop == "tomorrow" {
            WeatherForecastWidget(widget: widget, period: "Tomorrow",
                                  high: widget.properties["tomorrowHigh"]?.doubleValue,
                                  low: widget.properties["tomorrowLow"]?.doubleValue)
        } else {
            WeatherCurrentWidget(widget: widget)
        }
    }
}

// MARK: - Garage Door Widget

struct GarageDoorWidget: View {
    let widget: DeviceWidget
    let onToggle: () -> Void

    private var doorState: String { widget.state ?? "unknown" }

    private var borderColor: Color {
        switch doorState {
        case "open": AppTheme.dashGreen
        case "opening", "closing": AppTheme.dashYellow
        default: AppTheme.dashBorder
        }
    }

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 4) {
                GarageDoorIcon(state: doorState)
                    .frame(width: 44, height: 44)

                Text(doorState)
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.dashSecondary)

                Text(widget.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.dashText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(AppTheme.dashCard)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 1)
            )
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
        default: Color(red: 0.282, green: 0.310, blue: 0.345)
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

            let frame = RoundedRectangle(cornerRadius: w * 0.08)
                .path(in: CGRect(x: w * 0.08, y: w * 0.08, width: w * 0.84, height: h * 0.84))
            context.fill(frame, with: .color(Color(red: 0.102, green: 0.118, blue: 0.141)))
            context.stroke(frame, with: .color(borderStroke), lineWidth: 1.5)

            let panelX = w * 0.17
            let panelW = w * 0.66
            let panelH = h * 0.125
            let gap = h * 0.04

            if state == "open" {
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

// MARK: - Sensor Widget

struct SensorWidget: View {
    let widget: DeviceWidget

    var body: some View {
        VStack(spacing: 2) {
            Text(widget.formatTemp(widget.temperature))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.dashBlue)

            if let hum = widget.humidity {
                Text(widget.formatHumidity(hum))
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.dashGreen)
            }

            Text(widget.label)
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.dashSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .dashCardStyle()
    }
}

// MARK: - Thermostat Tiles (3 separate cards)

struct ThermostatSetpointTile: View {
    let widget: DeviceWidget
    @Environment(AppState.self) private var appState

    private var modeColor: Color {
        switch widget.thermostatMode {
        case "heat": AppTheme.dashOrange
        case "cool": AppTheme.dashBlue
        default: AppTheme.dashSecondary
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(widget.formatTemp(widget.desiredTemp))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(modeColor)

            if let state = widget.thermostatState {
                Text(state)
                    .font(.system(size: 8))
                    .foregroundStyle(modeColor.opacity(0.8))
            }

            HStack(spacing: 10) {
                Button {
                    Task { await appState.sendWidgetCommand(widget, command: "set_desired_temp_up") }
                } label: {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(AppTheme.dashSecondary)
                        .frame(width: 20, height: 16)
                        .background(AppTheme.dashBorder.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                Button {
                    Task { await appState.sendWidgetCommand(widget, command: "set_desired_temp_down") }
                } label: {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(AppTheme.dashSecondary)
                        .frame(width: 20, height: 16)
                        .background(AppTheme.dashBorder.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .dashCardStyle()
    }
}

struct ThermostatRoomTile: View {
    let widget: DeviceWidget

    var body: some View {
        VStack(spacing: 2) {
            Text(widget.formatTemp(widget.roomTemp))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.dashText)

            HStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(AppTheme.dashGreen)
                Text(widget.formatHumidity(widget.humidity))
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.dashGreen)
            }

            Text("Room")
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.dashSecondary)
        }
        .frame(maxWidth: .infinity)
        .dashCardStyle()
    }
}

struct ThermostatFanTile: View {
    let widget: DeviceWidget
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "gearshape")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.dashSecondary)

            Text(widget.fanMode ?? "--")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.dashText)

            Button {
                Task { await appState.sendWidgetCommand(widget, command: "set_fan_mode") }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.dashBlue)
                    .frame(width: 22, height: 18)
                    .background(AppTheme.dashBorder.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
        .frame(maxWidth: .infinity)
        .dashCardStyle()
    }
}

// MARK: - Weather Forecast Widget (Today/Tomorrow high-low)

struct WeatherForecastWidget: View {
    let widget: DeviceWidget
    let period: String
    let high: Double?
    let low: Double?

    var body: some View {
        VStack(spacing: 3) {
            Text(period)
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.dashSecondary)

            HStack(spacing: 8) {
                VStack(spacing: 1) {
                    Text(formatDeg(high))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.dashRed)
                    Text("High")
                        .font(.system(size: 7))
                        .foregroundStyle(AppTheme.dashSecondary)
                }
                VStack(spacing: 1) {
                    Text(formatDeg(low))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.dashBlue)
                    Text("Low")
                        .font(.system(size: 7))
                        .foregroundStyle(AppTheme.dashSecondary)
                }
            }

            Text(widget.label)
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.dashSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .dashCardStyle()
    }

    private func formatDeg(_ value: Double?) -> String {
        guard let v = value else { return "--" }
        return String(format: "%.0f°", v)
    }
}

// MARK: - Weather Current Conditions Widget (temp, humidity, wind)

struct WeatherCurrentWidget: View {
    let widget: DeviceWidget

    var body: some View {
        VStack(spacing: 2) {
            Text(widget.formatTemp(widget.temperature))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.dashBlue)

            if let cond = widget.condition {
                Text(cond)
                    .font(.system(size: 8))
                    .foregroundStyle(AppTheme.dashSecondary)
                    .lineLimit(1)
            }

            HStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(AppTheme.dashBlue.opacity(0.8))
                Text(widget.formatHumidity(widget.humidity))
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.dashSecondary)
            }

            if let wind = widget.windSpeed {
                HStack(spacing: 2) {
                    windArrow(degrees: widget.windDirection ?? 0)
                        .frame(width: 10, height: 10)
                    Text(String(format: "%.0f km/h", wind))
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.dashSecondary)
                }
            }

            Text(widget.label)
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.dashSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .dashCardStyle()
    }

    private func windArrow(degrees: Double) -> some View {
        Image(systemName: "location.north.fill")
            .font(.system(size: 8))
            .foregroundStyle(AppTheme.dashSecondary)
            .rotationEffect(.degrees(degrees))
    }
}

// MARK: - Generic Widget (fallback)

struct GenericWidget: View {
    let widget: DeviceWidget

    var body: some View {
        VStack(spacing: 3) {
            Text(widget.label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.dashText)
                .lineLimit(1)

            if let state = widget.state {
                Text(state)
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.dashSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .dashCardStyle()
    }
}
