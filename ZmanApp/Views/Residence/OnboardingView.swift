import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var serverURL = ""
    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                serverPage.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .background(AppTheme.background)
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "house.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: 12) {
                Text("Welcome to Zman")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Control your home from anywhere.\nManage multiple buildings, rooms, and devices.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 16) {
                Feature(icon: "building.2.fill", title: "Multiple Buildings", description: "Manage all your properties")
                Feature(icon: "square.grid.2x2.fill", title: "Room Control", description: "Dedicated controls per room")
                Feature(icon: "ipad.landscape", title: "iPad Kiosk Mode", description: "Mount iPads as room panels")
                Feature(icon: "lock.shield.fill", title: "Secure Tunnel", description: "Connect via Cloudflare tunnel")
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Server Page

    private var serverPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: 12) {
                Text("Connect to Zman")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Enter your Zman server URL.\nThis is typically your Cloudflare tunnel address.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 16) {
                TextField("https://home.example.com", text: $serverURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .textContentType(.URL)
                    .padding()
                    .background(AppTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    appState.configureServer(url: serverURL)
                } label: {
                    Text("Connect")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(serverURL.isEmpty ? AppTheme.offGray : AppTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(serverURL.isEmpty)
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Feature Row

private struct Feature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
