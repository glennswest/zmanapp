# Changelog

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

## [Unreleased]

### 2026-03-16
- **fix:** Add retry tolerance to claim poll loop — transient errors no longer kill the flow
- **fix:** Increase cloud service timeouts (30s request / 60s resource) for email verification
- **feat:** Implement cloud claim authentication flow (email magic link → claim token → API key)
- **feat:** Add CloudService for cloud.zmanapp.com worker endpoints (connect, poll, claim)
- **feat:** Add X-API-Key header auth support to APIService
- **feat:** Rewrite OnboardingView with email entry, polling, and claim exchange screens
- **refactor:** Replace username/password login with email magic-link claim flow
- **refactor:** Remove LoginView (superseded by claim flow in OnboardingView)
- **refactor:** Remove TunnelConfig model (replaced by hub persistence fields)
- **feat:** Add hub info display in SettingsView (hostname, hub ID, email)
- **feat:** Add apiKey, hubId, hubHostname, claimEmail to PersistenceService (Keychain/UserDefaults)
- **docs:** Update README with cloud worker API endpoints and new auth flow

### 2026-03-11
- **chore:** Switch to automatic code signing with development team for device builds
- **feat:** Add app icon — bold Z with lightning bolt on dark navy background

## [v0.1.0] — 2026-03-07

### Added
- Initial project structure with XcodeGen (project.yml)
- Data models — Building, Area, DeviceWidget (physical/virtual), TunnelConfig, API response types
- APIService — REST client for Zman backend via Cloudflare tunnel, auth, CRUD for buildings/areas/widgets
- PersistenceService — UserDefaults + Keychain for tokens, iPad mode config, building selection
- AppState — centralized observable state with building/area selection, widget commands, auth flow
- GarageViewModel — garage door control, camera/sensor/light organization
- RoomViewModel — widget grouping by category, physical/virtual filtering
- PhoneDashboardView — on-the-go design with garage quick actions, area grid, pull-to-refresh
- PadDashboardView — three iPad modes: General (sidebar nav), Room (fixed assignment), Garage (kiosk)
- GarageView + GarageDoorControl — large door controls with open/close animation, camera feeds, sensors
- RoomView — categorized widget grid with physical/virtual filter chips
- SettingsView — server config, iPad mode picker, area assignment, building switcher, sign out
- OnboardingView — welcome flow with server URL configuration
- LoginView — username/password auth with keyboard flow
- WidgetKit extension — QuickAction widget (small/medium) and Status widget for home screen
- Theme system with card styles, grid layouts, color scheme
- Reusable components — StatusBadge, QuickActionButton, SectionHeader, WidgetCard, AreaCard, FilterChip
