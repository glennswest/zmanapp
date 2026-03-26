# Changelog

## [Unreleased]

## [v0.3.0] — 2026-03-26

### Added
- Full-width thermostat card — setpoint (26pt, mode-colored), room temp (24pt), fan mode in 3-section horizontal layout with dividers
- Rotating weather cards per location — groups Algood/Cookeville widgets, auto-rotates current→today→tomorrow every 5s with swipe support
- Weather fonts now 28-30pt for temps, readable condition/humidity/wind info
- `setpoint` property accessor (hub's active HVAC target, preferred over desiredTemp)
- Weather routing via hub `property` field (today/tomorrow/null) instead of ID matching
- WeatherCurrentWidget shows condition text, wind direction compass arrow, wind speed
- `widgetTypeRaw` and `widgetProperty` fields to DeviceWidget for hub type/property decoding
- `tempUnit` field to Building model from hub API
- thermostatMode, thermostatState, condition, windDirection property accessors
- PropertyValue type for flexible JSON property parsing (string/number/bool)
- WidgetType inference from device_id prefix (garage, thermostat, sensor, weather)
- Dark theme colors matching web UI (#0f1117 background, #161b22 cards, #58a6ff accent blue)
- GarageDoorIcon with Canvas-rendered SVG-style panel graphics (closed/open/moving states)
- DashCardStyle view modifier for dark-themed widget cards
- Cloud claim authentication flow (email magic link → claim token → API key)
- CloudService for cloud.zmanapp.com worker endpoints (connect, poll, claim)
- X-API-Key header auth support to APIService
- Rewrite OnboardingView with email entry, polling, and claim exchange screens
- Hub info display in SettingsView (hostname, hub ID, email)
- apiKey, hubId, hubHostname, claimEmail to PersistenceService (Keychain/UserDefaults)
- Debug log system with View Log sheet in Settings and Onboarding
- App icon — bold Z with lightning bolt on dark navy background
- Plug widget with power icon and on/off toggle animation
- Privacy manifest (PrivacyInfo.xcprivacy) for App Store compliance
- ExportOptions.plist for App Store Connect archive upload
- TestFlight beta release preparation (build 3)

### Changed
- Sectioned dashboard layout — regular widgets in grid, thermostat and weather as full-width cards
- Removed DashboardCell enum — replaced by sectioned VStack approach
- Rewrite DeviceWidget model — now uses deviceId, dashboardId, properties dict instead of kind/category/state enums
- API command endpoint changed to POST /api/v1/devices/{deviceId}/command matching hub API
- AppState now organizes widgets by dashboard tab instead of area mode
- StatusBadge now uses string state instead of WidgetState enum
- Removed WidgetKind, WidgetCategory, WidgetState enums (replaced by properties-based model)
- Removed physical/virtual filter system and AreaCard from dashboard
- Simplified GarageViewModel and RoomViewModel for new widget model
- Replaced username/password login with email magic-link claim flow
- Removed LoginView (superseded by claim flow in OnboardingView)
- Removed TunnelConfig model (replaced by hub persistence fields)
- Switched to automatic code signing with development team

### Fixed
- Unreachable default case in widget type switch
- Retry tolerance in claim poll loop — transient errors no longer kill the flow
- Increased cloud service timeouts (30s request / 60s resource) for email verification
- Thermostat room temp font matches setpoint (both 28pt)
- Use snake_case property keys — convertFromSnakeCase doesn't affect dict keys

### Documentation
- Updated README with cloud worker API endpoints and new auth flow

## [v0.2.0] — 2026-03-10

### Added
- macOS 14.0+ support — native Mac app with NavigationSplitView layout
- PlatformService for cross-platform device detection (phone/pad/mac)
- SyncService with periodic polling (30s active, 5min background)
- Sync status indicators in dashboard headers (pad + phone)
- Sync section in Settings with status, last sync time, error display, manual sync
- macOS Settings scene (accessible from app menu)
- macOS keyboard shortcut Cmd+R for refresh
- macOS window sizing (min 800x500, default 1000x700)

### Changed
- `IPadDisplayMode` renamed to `DisplayMode` (backward-compatible UserDefaults keys)
- `isIPad` replaced with `isWideLayout` (true for iPad + Mac)
- Theme colors use NSColor equivalents on macOS
- iOS-only view modifiers guarded with `#if os(iOS)`
- XcodeGen config uses `supportedDestinations: [iOS, macOS]`
- Info.plist cleaned up: removed `LSRequiresIPhoneOS`, `UIRequiredDeviceCapabilities`
- WidgetKit extension stays iOS-only via platform-scoped dependency
- "iPad Mode" settings label renamed to "Display Mode"

## [v0.1.0] — 2026-03-07

### Added
- Initial project structure with XcodeGen (project.yml)
- Data models — Building, Area, DeviceWidget, TunnelConfig, API response types
- APIService — REST client for Zman backend via Cloudflare tunnel, auth, CRUD for buildings/areas/widgets
- PersistenceService — UserDefaults + Keychain for tokens, iPad mode config, building selection
- AppState — centralized observable state with building/area selection, widget commands, auth flow
- GarageViewModel — garage door control, sensor organization
- RoomViewModel — widget grouping by type
- PhoneDashboardView — dashboard with widget cards, pull-to-refresh
- PadDashboardView — iPad modes: General (sidebar nav), Room (fixed assignment), Garage (kiosk)
- GarageView + GarageDoorControl — door controls with open/close animation, sensors
- RoomView — widget grid
- SettingsView — server config, iPad mode picker, area assignment, building switcher, sign out
- OnboardingView — welcome flow with server URL configuration
- LoginView — username/password auth with keyboard flow
- WidgetKit extension — QuickAction widget (small/medium) and Status widget for home screen
- Theme system with card styles, grid layouts, color scheme
- Reusable components — StatusBadge, QuickActionButton, SectionHeader, WidgetCard
