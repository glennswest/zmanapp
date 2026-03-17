import SwiftUI

struct PhoneDashboardView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dashboardTabs

                ScrollView {
                    VStack(spacing: 12) {
                        // Regular widgets (garage, sensors) in 3-column grid
                        if !regularWidgets.isEmpty {
                            LazyVGrid(columns: gridColumns, spacing: 10) {
                                ForEach(regularWidgets) { widget in
                                    regularWidgetView(widget)
                                }
                            }
                        }

                        // Full-width thermostat cards
                        ForEach(thermostatWidgets) { widget in
                            ThermostatCard(widget: widget)
                        }

                        // Weather locations — rotating cards
                        ForEach(weatherLocations, id: \.locationId) { loc in
                            WeatherLocationCard(location: loc)
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

    // MARK: - Widget Groups

    private var regularWidgets: [DeviceWidget] {
        appState.currentDashboardWidgets.filter {
            $0.widgetType != .thermostat && $0.widgetType != .weather
        }
    }

    private var thermostatWidgets: [DeviceWidget] {
        appState.currentDashboardWidgets.filter { $0.widgetType == .thermostat }
    }

    private var weatherLocations: [WeatherLocation] {
        let wx = appState.currentDashboardWidgets.filter { $0.widgetType == .weather }
        let grouped = Dictionary(grouping: wx) { $0.deviceId }
        return grouped.map { deviceId, widgets in
            let name = deviceId
                .replacingOccurrences(of: "virtual.weather.", with: "")
                .capitalized
            return WeatherLocation(
                locationId: deviceId,
                name: name,
                current: widgets.first { ($0.widgetProperty ?? "").isEmpty },
                today: widgets.first { $0.widgetProperty == "today" },
                tomorrow: widgets.first { $0.widgetProperty == "tomorrow" }
            )
        }.sorted { $0.name < $1.name }
    }

    // MARK: - Regular Widget View

    @ViewBuilder
    private func regularWidgetView(_ widget: DeviceWidget) -> some View {
        switch widget.widgetType {
        case .garage:
            GarageDoorWidget(widget: widget) {
                Task { await appState.toggleWidget(widget) }
            }
        case .sensor:
            SensorWidget(widget: widget)
        default:
            GenericWidget(widget: widget)
        }
    }

    private var gridColumns: [GridItem] {
        let isWide = PlatformService.isWideDevice
        let columns = isWide ? 6 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
    }
}

// MARK: - Weather Location (groups 3 widgets for one place)

struct WeatherLocation {
    let locationId: String
    let name: String
    let current: DeviceWidget?
    let today: DeviceWidget?
    let tomorrow: DeviceWidget?

    var pageCount: Int {
        (current != nil ? 1 : 0) + (today != nil ? 1 : 0) + (tomorrow != nil ? 1 : 0)
    }
}

// MARK: - Weather Location Card (rotating pages, tappable)

struct WeatherLocationCard: View {
    let location: WeatherLocation
    @State private var currentPage = 0
    @State private var timer: Timer?
    @State private var showDetail = false

    var body: some View {
        VStack(spacing: 0) {
            // Header: location name + page dots
            HStack {
                Text(location.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.dashText)
                Spacer()
                HStack(spacing: 5) {
                    ForEach(0..<location.pageCount, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? AppTheme.dashBlue : AppTheme.dashBorder)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)

            // Pages
            pageContent
                .frame(height: 100)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            if value.translation.width < -30 {
                                withAnimation { currentPage = min(currentPage + 1, location.pageCount - 1) }
                            } else if value.translation.width > 30 {
                                withAnimation { currentPage = max(currentPage - 1, 0) }
                            }
                            restartTimer()
                        }
                )
                .onTapGesture {
                    showDetail = true
                }

            Spacer().frame(height: 10)
        }
        .background(AppTheme.dashCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.dashBorder, lineWidth: 1))
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
        .sheet(isPresented: $showDetail) {
            WeatherDetailSheet(location: location)
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        let pages = buildPages()
        if currentPage < pages.count {
            pages[currentPage]
        }
    }

    private func buildPages() -> [AnyView] {
        var pages: [AnyView] = []
        if let w = location.current {
            pages.append(AnyView(weatherCurrentPage(w)))
        }
        if let w = location.today {
            pages.append(AnyView(weatherForecastPage(w, period: "Today",
                high: w.todayHigh, low: w.todayLow)))
        }
        if let w = location.tomorrow {
            pages.append(AnyView(weatherForecastPage(w, period: "Tomorrow",
                high: w.tomorrowHigh, low: w.tomorrowLow)))
        }
        return pages
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            Task { @MainActor in
                withAnimation {
                    currentPage = (currentPage + 1) % max(location.pageCount, 1)
                }
            }
        }
    }

    private func restartTimer() {
        startTimer()
    }

    // MARK: - Current Conditions Page

    private func weatherCurrentPage(_ widget: DeviceWidget) -> some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Now")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.dashSecondary)
                Text(widget.formatTemp(widget.temperature))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(AppTheme.dashBlue)
                if let cond = widget.condition {
                    Text(cond)
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.dashSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.dashBlue.opacity(0.8))
                    Text(widget.formatHumidity(widget.humidity))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppTheme.dashText)
                }
                if let wind = widget.windSpeed {
                    HStack(spacing: 4) {
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.dashSecondary)
                            .rotationEffect(.degrees(widget.windDirection ?? 0))
                        Text(String(format: "%.0f km/h", wind))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(AppTheme.dashText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    // MARK: - Forecast Page

    private func weatherForecastPage(_ widget: DeviceWidget, period: String, high: Double?, low: Double?) -> some View {
        VStack(spacing: 8) {
            Text(period)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.dashSecondary)

            HStack(spacing: 40) {
                VStack(spacing: 2) {
                    Text(formatDeg(high))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(AppTheme.dashRed)
                    Text("High")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.dashSecondary)
                }
                VStack(spacing: 2) {
                    Text(formatDeg(low))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(AppTheme.dashBlue)
                    Text("Low")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.dashSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func formatDeg(_ value: Double?) -> String {
        guard let v = value else { return "--" }
        return String(format: "%.0f°", v)
    }
}

// MARK: - Weather Detail Sheet

struct WeatherDetailSheet: View {
    let location: WeatherLocation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current conditions
                    if let w = location.current {
                        detailSection("Current Conditions") {
                            detailRow("Temperature", w.formatTemp(w.temperature))
                            detailRow("Condition", w.condition ?? "--")
                            detailRow("Humidity", w.formatHumidity(w.humidity))
                            if let wind = w.windSpeed {
                                detailRow("Wind", String(format: "%.1f km/h", wind))
                            }
                            if let gusts = w.properties["wind_gusts"]?.doubleValue {
                                detailRow("Gusts", String(format: "%.1f km/h", gusts))
                            }
                            if let feels = w.properties["feels_like"]?.doubleValue {
                                detailRow("Feels Like", w.formatTemp(feels))
                            }
                            if let pressure = w.properties["pressure"]?.doubleValue {
                                detailRow("Pressure", String(format: "%.0f hPa", pressure))
                            }
                            if let uv = w.properties["uv_index"]?.doubleValue {
                                detailRow("UV Index", String(format: "%.1f", uv))
                            }
                            if let vis = w.properties["visibility"]?.doubleValue {
                                detailRow("Visibility", String(format: "%.0f m", vis))
                            }
                            if let cloud = w.properties["cloud_cover"]?.doubleValue {
                                detailRow("Cloud Cover", String(format: "%.0f%%", cloud))
                            }
                        }
                    }

                    // Today forecast
                    if let w = location.today {
                        detailSection("Today") {
                            detailRow("High", formatDeg(w.todayHigh), color: AppTheme.dashRed)
                            detailRow("Low", formatDeg(w.todayLow), color: AppTheme.dashBlue)
                        }
                    }

                    // Tomorrow forecast
                    if let w = location.tomorrow {
                        detailSection("Tomorrow") {
                            detailRow("High", formatDeg(w.tomorrowHigh), color: AppTheme.dashRed)
                            detailRow("Low", formatDeg(w.tomorrowLow), color: AppTheme.dashBlue)
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.dashBackground)
            .navigationTitle(location.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .toolbarBackground(AppTheme.dashBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func detailSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.dashText)
            VStack(spacing: 0) {
                content()
            }
            .background(AppTheme.dashCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.dashBorder, lineWidth: 1))
        }
    }

    private func detailRow(_ label: String, _ value: String, color: Color = AppTheme.dashText) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.dashSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func formatDeg(_ value: Double?) -> String {
        guard let v = value else { return "--" }
        return String(format: "%.0f°C", v)
    }
}

// MARK: - Thermostat Card (full width, 3 sections)

struct ThermostatCard: View {
    let widget: DeviceWidget
    @Environment(AppState.self) private var appState

    private var modeColor: Color {
        switch widget.thermostatMode {
        case "heat": AppTheme.dashOrange
        case "cool": AppTheme.dashBlue
        default: AppTheme.dashSecondary
        }
    }

    private var displaySetpoint: Double? {
        widget.desiredTemp ?? widget.setpoint
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text(widget.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.dashText)
                    .lineLimit(1)
                Spacer()
                if let state = widget.thermostatState {
                    Text(state)
                        .font(.system(size: 13))
                        .foregroundStyle(modeColor)
                }
            }

            // 3-section horizontal layout
            HStack(spacing: 0) {
                // Setpoint
                VStack(spacing: 4) {
                    Text(widget.formatTemp(displaySetpoint))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(modeColor)
                    Text("Setpoint")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.dashSecondary)
                    HStack(spacing: 14) {
                        Button {
                            Task { await appState.sendWidgetCommand(widget, command: "set_desired_temp_up") }
                        } label: {
                            Image(systemName: "arrowtriangle.up.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.dashText)
                                .frame(width: 34, height: 28)
                                .background(AppTheme.dashBorder.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Button {
                            Task { await appState.sendWidgetCommand(widget, command: "set_desired_temp_down") }
                        } label: {
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.dashText)
                                .frame(width: 34, height: 28)
                                .background(AppTheme.dashBorder.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(AppTheme.dashBorder)
                    .frame(width: 1, height: 80)

                // Room temp + humidity
                VStack(spacing: 4) {
                    Text(widget.formatTemp(widget.roomTemp))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AppTheme.dashText)
                    HStack(spacing: 3) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.dashGreen)
                        Text(widget.formatHumidity(widget.humidity))
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.dashGreen)
                    }
                    Text("Room")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.dashSecondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(AppTheme.dashBorder)
                    .frame(width: 1, height: 80)

                // Fan mode
                VStack(spacing: 4) {
                    Image(systemName: "fan.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.dashSecondary)
                    Text(widget.fanMode ?? "--")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.dashText)
                    Button {
                        Task { await appState.sendWidgetCommand(widget, command: "set_fan_mode") }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.dashBlue)
                            .frame(width: 34, height: 28)
                            .background(AppTheme.dashBorder.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(AppTheme.dashCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.dashBorder, lineWidth: 1)
        )
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
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.dashSecondary)

                Text(widget.label)
                    .font(.system(size: 12, weight: .medium))
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
        VStack(spacing: 3) {
            Text(widget.formatTemp(widget.temperature))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.dashBlue)

            if let hum = widget.humidity {
                Text(widget.formatHumidity(hum))
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.dashGreen)
            }

            Text(widget.label)
                .font(.system(size: 11))
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
