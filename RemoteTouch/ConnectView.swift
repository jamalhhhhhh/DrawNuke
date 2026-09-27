import SwiftUI

struct ConnectView: View {
    @StateObject private var discovery = PCDiscovery()
    @AppStorage("rt_ip") private var ip = ""
    @AppStorage("rt_token") private var token = ""
    @State private var connecting = false
    @State private var error: String?
    @State private var connected = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 6) {
                            Text("REMOTE TOUCH")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text("see your PC's screen from your phone")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .padding(.top, 10)

                        if !discovery.pcs.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("PCs on your network - tap yours")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))

                                ForEach(discovery.pcs) { pc in
                                    Button {
                                        ip = pc.ip
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "desktopcomputer")
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundStyle(.green)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(pc.name)
                                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                                    .foregroundStyle(.white)
                                                Text(pc.ip)
                                                    .font(.system(size: 12, design: .monospaced))
                                                    .foregroundStyle(.white.opacity(0.5))
                                            }
                                            Spacer()
                                            if ip == pc.ip {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.green)
                                            }
                                        }
                                        .padding(14)
                                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                                    }
                                }
                            }
                        } else {
                            HStack(spacing: 10) {
                                ProgressView().tint(.green)
                                Text("Looking for PCs on your network...")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .padding(14)
                            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                        }

                        VStack(spacing: 12) {
                            TextField("Or enter PC IP manually (e.g. 192.168.1.50)", text: $ip)
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
            }
            .navigationDestination(isPresented: $connected) {
                RemoteView(config: ServerConfig(ip: ip, token: token))
            }
            .onAppear {
                discovery.start()
            }
            .onDisappear {
                discovery.stop()
            }
        }
    }

    private func connect() {
        error = nil
        guard !ip.isEmpty, !token.isEmpty else {
            error = "Pick a PC (or type the IP) and enter the PIN from the server window"
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
