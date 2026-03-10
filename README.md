# Zman

Home and building control app for iPhone, iPad, and Mac.

## Features

- **Multi-Building Support** — Manage multiple residences/buildings from one app
- **Dynamic Configuration** — Buildings, areas, and devices loaded from Zman backend API
- **Periodic Sync** — Automatic polling (30s active, 5min background) keeps data fresh
- **iPhone (On-the-Go)** — Quick garage actions, area grid, pull-to-refresh dashboard
- **iPad (Fixed Install)** — Three display modes:
  - **General Mode** — Full sidebar navigation, dashboard overview (living room iPad)
  - **Room Mode** — Locked to a specific room's controls (mounted room iPad)
  - **Garage Mode** — Dedicated garage door and sensor controls (garage iPad)
- **Mac** — Native macOS app with NavigationSplitView layout, Settings in app menu, Cmd+R refresh
- **Widget Organization** — Physical and virtual widgets with category grouping and filtering
- **WidgetKit** — Home screen widgets for quick device status and one-tap control (iOS only)
- **Cloudflare Tunnel** — Secure remote access through Cloudflare tunnel
- **Keychain Auth** — Tokens stored securely in Keychain

## Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 16.0+
- Swift 6.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for project generation)

## Setup

```bash
# Install XcodeGen (if not already installed)
brew install xcodegen

# Generate the Xcode project
xcodegen generate

# Open in Xcode
open ZmanApp.xcodeproj
```

## Architecture

- **SwiftUI** — Declarative UI framework
- **MVVM** — Model-View-ViewModel pattern with `@Observable`
- **Adaptive Layout** — `PlatformService` detects phone/pad/mac for layout routing
- **SyncService** — Periodic background polling with scenePhase-aware intervals
- **WidgetKit** — Home screen widget extension (iOS only)

### Project Structure

```
ZmanApp/
├── Models/          — Data models (Building, Area, DeviceWidget, API types)
├── ViewModels/      — AppState, GarageViewModel, RoomViewModel
├── Views/
│   ├── Dashboard/   — PhoneDashboardView, PadDashboardView
│   ├── Garage/      — GarageView, GarageDoorControl
│   ├── Room/        — RoomView with category grid
│   ├── Residence/   — LoginView, OnboardingView
│   ├── Settings/    — SettingsView (server, display mode, sync status, building picker)
│   └── Components/  — StatusBadge, QuickActionButton, WidgetCard, etc.
├── Services/        — APIService, PersistenceService, PlatformService, SyncService
└── Theme/           — AppTheme (colors, spacing, grid layouts)

ZmanWidgets/         — WidgetKit extension (QuickAction + Status widgets, iOS only)
```

## Backend API

The app expects a Zman backend API accessible via Cloudflare tunnel:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/health` | GET | Health check |
| `/api/v1/auth/login` | POST | Authenticate |
| `/api/v1/buildings` | GET | List all buildings |
| `/api/v1/buildings/:id` | GET | Get building with areas |
| `/api/v1/buildings/:id/areas` | GET | List areas in building |
| `/api/v1/buildings/:id/areas/:id` | GET | Get area with widgets |
| `/api/v1/buildings/:id/widgets` | GET | All widgets in building |
| `/api/v1/buildings/:id/areas/:id/widgets` | GET | Widgets in specific area |
| `/api/v1/widgets/:id/command` | POST | Send command to widget |

## Version

Current: `0.2.0`
