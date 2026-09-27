import Foundation
import Network

struct DiscoveredPC: Identifiable, Equatable {
    var id: String { ip }
    let name: String
    let ip: String
    let port: Int
}

final class PCDiscovery: ObservableObject {
    @Published var pcs: [DiscoveredPC] = []
    private var listener: NWListener?
    private var timer: Timer?
    private var seen: [String: (pc: DiscoveredPC, lastSeen: Date)] = [:]

    func start() {
        guard listener == nil else { return }
        guard let port = NWEndpoint.Port(rawValue: 8667) else { return }
        guard let listener = try? NWListener(using: .udp, on: port) else { return }
        self.listener = listener
        listener.newConnectionHandler = { [weak self] connection in
            connection.receiveMessage { [weak self] data, _, _, _ in
                self?.handle(data, connection)
            }
            connection.start(queue: .global())
        }
        listener.start(queue: .global())
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.prune()
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        timer?.invalidate()
        timer = nil
        seen.removeAll()
        pcs = []
    }

    private func handle(_ data: Data?, _ connection: NWConnection) {
        guard let data,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              obj["app"] as? String == "RemoteTouch",
              let name = obj["name"] as? String,
              let port = obj["port"] as? Int else { return }

        var ip = ""
        if case let .hostPort(host, _) = connection.endpoint {
            ip = "\(host)"
        }
        guard !ip.isEmpty else { return }

        seen[ip] = (DiscoveredPC(name: name, ip: ip, port: port), Date())
        publish()
    }

    private func prune() {
        let cutoff = Date().addingTimeInterval(-8)
        seen = seen.filter { $0.value.lastSeen > cutoff }
        publish()
    }

    private func publish() {
        let list = seen.values.map { $0.pc }.sorted { $0.name < $1.name }
        DispatchQueue.main.async { self.pcs = list }
    }
}
