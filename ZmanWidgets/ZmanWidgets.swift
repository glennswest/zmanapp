import WidgetKit
import SwiftUI

// MARK: - Shared Types for Widget Extension

struct WidgetDeviceEntry: TimelineEntry {
    let date: Date
    let deviceName: String
    let deviceState: String
    let deviceIcon: String
    let isConnected: Bool
}

// MARK: - Provider

struct ZmanWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetDeviceEntry {
        WidgetDeviceEntry(
            date: .now,
            deviceName: "Garage Door",
            deviceState: "Closed",
            deviceIcon: "door.garage.closed",
            isConnected: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetDeviceEntry) -> Void) {
        let entry = WidgetDeviceEntry(
            date: .now,
            deviceName: "Garage Door",
            deviceState: "Closed",
            deviceIcon: "door.garage.closed",
            isConnected: true
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetDeviceEntry>) -> Void) {
        // Fetch latest state from UserDefaults (shared app group)
        let defaults = UserDefaults(suiteName: "group.com.zmanapp.shared")

        let deviceName = defaults?.string(forKey: "widget_device_name") ?? "Garage Door"
        let deviceState = defaults?.string(forKey: "widget_device_state") ?? "Unknown"
        let deviceIcon = defaults?.string(forKey: "widget_device_icon") ?? "door.garage.closed"
        let isConnected = defaults?.bool(forKey: "widget_is_connected") ?? false

        let entry = WidgetDeviceEntry(
            date: .now,
            deviceName: deviceName,
            deviceState: deviceState,
            deviceIcon: deviceIcon,
            isConnected: isConnected
        )

        // Refresh every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Quick Action Widget

struct QuickActionWidgetView: View {
    var entry: WidgetDeviceEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.deviceIcon)
                    .font(.title2)
                    .foregroundStyle(stateColor)
                Spacer()
                Circle()
                    .fill(entry.isConnected ? .green : .red)
                    .frame(width: 8, height: 8)
            }

            Spacer()

            Text(entry.deviceName)
                .font(.headline)
                .lineLimit(1)

            Text(entry.deviceState)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Device status
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: entry.deviceIcon)
                    .font(.largeTitle)
                    .foregroundStyle(stateColor)

                Spacer()

                Text(entry.deviceName)
                    .font(.headline)

                Text(entry.deviceState)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Action hint
            VStack {
                Spacer()
                Image(systemName: "hand.tap.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Tap to toggle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private var stateColor: Color {
        switch entry.deviceState.lowercased() {
        case "open", "on", "unlocked": .orange
        case "closed", "off", "locked": .green
        case "opening", "closing": .yellow
        default: .gray
        }
    }
}

// MARK: - Status Widget

struct StatusWidgetView: View {
    var entry: WidgetDeviceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "house.fill")
                    .foregroundStyle(.blue)
                Spacer()
                Circle()
                    .fill(entry.isConnected ? .green : .red)
                    .frame(width: 8, height: 8)
            }

            Spacer()

            Text("Zman")
                .font(.headline)

            Text(entry.isConnected ? "Connected" : "Offline")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Widget Declarations

struct QuickActionWidget: Widget {
    let kind: String = "QuickAction"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZmanWidgetProvider()) { entry in
            QuickActionWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Action")
        .description("Quick access to a device control.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StatusWidget: Widget {
    let kind: String = "Status"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZmanWidgetProvider()) { entry in
            StatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Zman Status")
        .description("Shows your Zman server connection status.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct ZmanWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickActionWidget()
        StatusWidget()
    }
}
