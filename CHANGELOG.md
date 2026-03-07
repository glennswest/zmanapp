# Changelog

## [Unreleased]

### 2026-03-07
- **feat:** Initial project structure with XcodeGen (project.yml)
- **feat:** Data models — Building, Area, DeviceWidget (physical/virtual), TunnelConfig, API response types
- **feat:** APIService — REST client for Zman backend via Cloudflare tunnel, auth, CRUD for buildings/areas/widgets
- **feat:** PersistenceService — UserDefaults + Keychain for tokens, iPad mode config, building selection
- **feat:** AppState — centralized observable state with building/area selection, widget commands, auth flow
- **feat:** GarageViewModel — garage door control, camera/sensor/light organization
- **feat:** RoomViewModel — widget grouping by category, physical/virtual filtering
- **feat:** PhoneDashboardView — on-the-go design with garage quick actions, area grid, pull-to-refresh
- **feat:** PadDashboardView — three iPad modes: General (sidebar nav), Room (fixed assignment), Garage (kiosk)
- **feat:** GarageView + GarageDoorControl — large door controls with open/close animation, camera feeds, sensors
- **feat:** RoomView — categorized widget grid with physical/virtual filter chips
- **feat:** SettingsView — server config, iPad mode picker, area assignment, building switcher, sign out
- **feat:** OnboardingView — welcome flow with server URL configuration
- **feat:** LoginView — username/password auth with keyboard flow
- **feat:** WidgetKit extension — QuickAction widget (small/medium) and Status widget for home screen
- **feat:** Theme system with card styles, grid layouts, color scheme
- **feat:** Reusable components — StatusBadge, QuickActionButton, SectionHeader, WidgetCard, AreaCard, FilterChip
