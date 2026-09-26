import SwiftUI

final class ScreenStreamer: ObservableObject {
    @Published var image: UIImage?
    var fps: Double = 3
    private var task: Task<Void, Never>?
    var config: ServerConfig?

    func start() {
        stop()
        guard let config else { return }
        task = Task {
            while !Task.isCancelled {
                await self.fetch(config)
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000.0 / self.fps))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func fetch(_ config: ServerConfig) async {
        guard let url = RemoteAPI.url(config, "/screenshot.jpg") else { return }
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue(config.token, forHTTPHeaderField: "X-Auth-Token")
        req.timeoutInterval = 3
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let img = UIImage(data: data) else { return }
        await MainActor.run { self.image = img }
    }
}

struct RemoteView: View {
    let config: ServerConfig
    @StateObject private var streamer = ScreenStreamer()
    @State private var commandText = ""
    @State private var output: String?
    @State private var showOutput = false
    @State private var began = false
    @State private var beganAt = Date()
    @State private var lastMove = Date.distantPast

    private let apps: [(String, String)] = [
        ("calculator", "Calc"),
        ("notepad", "Notepad"),
        ("paint", "Paint"),
        ("explorer", "Files"),
        ("chrome", "Chrome"),
        ("taskmanager", "Tasks"),
        ("steam", "Steam"),
        ("cmd", "CMD"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            screenArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)

            controls
                .background(Color(white: 0.08))
        }
        .navigationTitle("Remote")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            streamer.config = config
            streamer.start()
        }
        .onDisappear {
            streamer.stop()
        }
        .sheet(isPresented: $showOutput) {
            outputSheet
        }
    }

    private var screenArea: some View {
        GeometryReader { geo in
            ZStack {
                if let image = streamer.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if !began {
                                        began = true
                                        beganAt = Date()
                                    }
                                    guard let img = streamer.image,
                                          let (xp, yp) = percent(value.location, geo: geo, img: img) else { return }
                                    if Date().timeIntervalSince(lastMove) > 0.08 {
                                        lastMove = Date()
                                        Task { await RemoteAPI.post(config, "/move", body: ["x": xp, "y": yp]) }
                                    }
                                }
                                .onEnded { value in
                                    began = false
                                    guard let img = streamer.image,
                                          let (xp, yp) = percent(value.location, geo: geo, img: img) else { return }
                                    if Date().timeIntervalSince(beganAt) < 0.35 {
                                        Task { await RemoteAPI.post(config, "/tap", body: ["x": xp, "y": yp]) }
                                    }
                                }
                        )
                } else {
                    VStack(spacing: 10) {
                        ProgressView().tint(.green)
                        Text("Connecting to your PC...")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }

    private var controls: some View {
        ScrollView {
            VStack(spacing: 14) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(apps, id: \.0) { app in
                        Button {
                            Task { await RemoteAPI.post(config, "/app", body: ["name": app.0]) }
                        } label: {
                            Text(app.1)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.1)))
                                .foregroundStyle(.white)
                        }
                    }
                }

                HStack(spacing: 10) {
                    keyButton("Vol -", "volumedown")
                    keyButton("Mute", "mute")
                    keyButton("Vol +", "volumeup")
                }

                HStack(spacing: 10) {
                    TextField("Run command on PC...", text: $commandText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                    Button {
                        runCommand()
                    } label: {
                        Text("Run")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(.green))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(12)
        }
    }

    private var outputSheet: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Output")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            ScrollView {
                Text(output ?? "(empty)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(white: 0.08).ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }

    private func keyButton(_ label: String, _ key: String) -> some View {
        Button {
            Task { await RemoteAPI.post(config, "/key", body: ["name": key]) }
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.1)))
                .foregroundStyle(.white)
        }
    }

    private func runCommand() {
        let cmd = commandText.trimmingCharacters(in: .whitespaces)
        guard !cmd.isEmpty else { return }
        Task {
            let result = await RemoteAPI.post(config, "/command", body: ["cmd": cmd]) ?? "(failed - is the server running?)"
            await MainActor.run {
                output = result
                showOutput = true
            }
        }
    }

    private func percent(_ location: CGPoint, geo: GeometryProxy, img: UIImage) -> (Double, Double)? {
        let imgAspect = img.size.width / img.size.height
        let viewSize = geo.size
        let viewAspect = viewSize.width / viewSize.height
        let dispW: CGFloat
        let dispH: CGFloat
        if imgAspect > viewAspect {
            dispW = viewSize.width
            dispH = viewSize.width / imgAspect
        } else {
            dispH = viewSize.height
            dispW = viewSize.height * imgAspect
        }
        let originX = (viewSize.width - dispW) / 2
        let originY = (viewSize.height - dispH) / 2
        let px = location.x - originX
        let py = location.y - originY
        guard px >= 0, py >= 0, px <= dispW, py <= dispH else { return nil }
        return (Double(px / dispW) * 100, Double(py / dispH) * 100)
    }
}

struct RemoteView_Previews: PreviewProvider {
    static var previews: some View {
        RemoteView(config: ServerConfig(ip: "192.168.1.50", token: "123456"))
    }
}
