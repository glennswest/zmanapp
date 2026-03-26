import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var email = ""
    @State private var password = ""
    @State private var showLog = false

    var body: some View {
        Group {
            switch appState.claimPhase {
            case .idle, .enterEmail:
                emailEntryView
            case .polling:
                pollingView
            case .claiming:
                claimingView
            case .complete:
                completeView
            }
        }
        .background(AppTheme.background)
        .onAppear {
            if appState.claimPhase == .idle {
                appState.claimPhase = .enterEmail
            }
            if email.isEmpty {
                email = appState.persistence.claimEmail
            }
        }
        .sheet(isPresented: $showLog) {
            debugLogSheet
        }
    }

    // MARK: - Email Entry

    private var emailEntryView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "house.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: 12) {
                Text("Welcome to Zman")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Enter the email address associated\nwith your Zman hub to get started.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 16) {
                Feature(icon: "envelope.fill", title: "Magic Link", description: "We'll email you a secure link")
                Feature(icon: "lock.shield.fill", title: "No Password", description: "Connect securely with one tap")
                Feature(icon: "building.2.fill", title: "Multiple Hubs", description: "Manage all your properties")
            }
            .padding(.horizontal, 40)

            VStack(spacing: 16) {
                TextField("email@example.com", text: $email)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)
                    .padding()
                    .background(AppTheme.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if isDemoEmail {
                    SecureField("Password", text: $password)
                        .padding()
                        .background(AppTheme.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    if isDemoEmail && password == "user" {
                        appState.enterDemoMode()
                    } else {
                        Task { await appState.startClaimFlow(email: email) }
                    }
                } label: {
                    Group {
                        if appState.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(isDemoEmail ? "Enter Demo" : "Send Link")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? AppTheme.accent : AppTheme.offGray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canSubmit || appState.isLoading)
            }
            .padding(.horizontal, 40)

            Spacer()

            if !appState.debugLog.isEmpty {
                Button { showLog = true } label: {
                    Text("View Log")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Polling (Check Your Email)

    private var pollingView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "envelope.open.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: 12) {
                Text("Check Your Email")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("We sent a link to\n**\(appState.claimEmail)**\n\nTap the link in the email to connect your app.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            ProgressView()
                .scaleEffect(1.5)
                .padding()

            Text("Waiting for confirmation...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 24) {
                Button { showLog = true } label: {
                    Text("View Log")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button {
                    appState.cancelClaim()
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Claiming

    private var claimingView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: 12) {
                Text("Connecting...")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Setting up your connection to the hub.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            ProgressView()
                .scaleEffect(1.5)

            Spacer()
        }
    }

    // MARK: - Complete

    private var completeView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            VStack(spacing: 12) {
                Text("Connected!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your app is connected to your Zman hub.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    // MARK: - Debug Log

    private var debugLogSheet: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        #if os(iOS)
                        UIPasteboard.general.string = appState.debugLog.joined(separator: "\n")
                        #else
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(appState.debugLog.joined(separator: "\n"), forType: .string)
                        #endif
                    } label: {
                        Label("Copy All", systemImage: "doc.on.doc")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showLog = false }
                }
            }
        }
    }

    private var isDemoEmail: Bool {
        email.lowercased().trimmingCharacters(in: .whitespaces) == "demo"
    }

    private var isValidEmail: Bool {
        email.contains("@") && email.contains(".") && email.count >= 5
    }

    private var canSubmit: Bool {
        if isDemoEmail { return !password.isEmpty }
        return isValidEmail
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
