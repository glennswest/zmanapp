import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var username = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case username, password
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                // Logo area
                VStack(spacing: 12) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(AppTheme.accent)

                    Text("Zman")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Sign in to manage your home")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Login form
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .focused($focusedField, equals: .username)
                        .padding()
                        .background(AppTheme.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .padding()
                        .background(AppTheme.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        Task { await appState.login(username: username, password: password) }
                    } label: {
                        Group {
                            if appState.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(username.isEmpty || password.isEmpty || appState.isLoading)
                }
                .padding(.horizontal)

                Spacer()
                Spacer()
            }
            .padding()
            .background(AppTheme.background)
            .onSubmit {
                switch focusedField {
                case .username:
                    focusedField = .password
                case .password:
                    Task { await appState.login(username: username, password: password) }
                case nil:
                    break
                }
            }
        }
    }
}
