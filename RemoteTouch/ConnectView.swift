import SwiftUI

struct ConnectView: View {
    @AppStorage("rt_ip") private var ip = ""
    @AppStorage("rt_token") private var token = ""
    @State private var connecting = false
    @State private var error: String?
    @State private var connected = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 18) {
                    VStack(spacing: 6) {
                        Text("REMOTE TOUCH")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("control your PC from your phone")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(.bottom, 10)

                    VStack(spacing: 12) {
                        TextField("PC IP address (e.g. 192.168.1.50)", text: $ip)
                            .keyboardType(.numbersAndPunctuation)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                        SecureField("PIN shown by the PC server", text: $token)
                            .keyboardType(.numberPad)
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        connect()
                    } label: {
                        Text("Connect")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(.green))
                            .foregroundStyle(.white)
                    }
                    .disabled(connecting)

                    if connecting {
                        ProgressView().tint(.green)
                    }

                    if let error {
                        Text(error)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationDestination(isPresented: $connected) {
                RemoteView(config: ServerConfig(ip: ip, token: token))
            }
        }
    }

    private func connect() {
        error = nil
        guard !ip.isEmpty, !token.isEmpty else {
            error = "Enter the PC IP and the PIN from the server window"
            return
        }
        connecting = true
        Task {
            let config = ServerConfig(ip: ip, token: token)
            let (ok, message) = await RemoteAPI.get(config, "/status")
            await MainActor.run {
                connecting = false
                if ok {
                    connected = true
                } else {
                    error = message ?? "Could not reach the PC"
                }
            }
        }
    }
}

struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectView()
    }
}
