import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("fynch")
                .font(.system(size: 48, weight: .bold, design: .default))
                .foregroundStyle(.primary)

            Spacer().frame(height: 16)

            VStack(spacing: 12) {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if showError {
                Text("Incorrect username or password.")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    let success = appState.login(username: username, password: password)
                    showError = !success
                }
            } label: {
                Text("Sign In")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
