import Foundation

struct ServerConfig: Codable {
    var ip: String
    var token: String
    var port: Int = 8666
}

enum RemoteAPI {
    static func url(_ config: ServerConfig, _ path: String) -> URL? {
        URL(string: "http://\(config.ip):\(config.port)\(path)")
    }

    static func get(_ config: ServerConfig, _ path: String) async -> (Bool, String?) {
        guard let url = url(config, path) else { return (false, "Bad address") }
        var req = URLRequest(url: url)
        req.setValue(config.token, forHTTPHeaderField: "X-Auth-Token")
        req.timeoutInterval = 4
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              let http = resp as? HTTPURLResponse else {
            return (false, "No response from PC - check IP, Wi-Fi and that the server is running")
        }
        if http.statusCode == 200 {
            return (true, String(data: data, encoding: .utf8))
        } else if http.statusCode == 401 {
            return (false, "Wrong PIN")
        } else {
            return (false, "PC said HTTP \(http.statusCode)")
        }
    }

    @discardableResult
    static func post(_ config: ServerConfig, _ path: String, body: [String: Any]) async -> String? {
        guard let url = url(config, path) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(config.token, forHTTPHeaderField: "X-Auth-Token")
        req.timeoutInterval = 20
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return obj["out"] as? String
        }
        return "OK"
    }
}
