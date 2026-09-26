import SwiftUI

@main
struct RemoteTouchApp: App {
    var body: some Scene {
        WindowGroup {
            ConnectView()
                .preferredColorScheme(.dark)
        }
    }
}
