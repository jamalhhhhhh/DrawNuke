import SwiftUI
import SpriteKit

struct SandboxView: View {
    @State private var scene = SandboxScene(size: UIScreen.main.bounds.size)

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                HStack(spacing: 14) {
                    Button {
                        scene.spawnDebris()
                    } label: {
                        Text("Crates")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(.white.opacity(0.14)))
                            .foregroundStyle(.white)
                    }

                    Button {
                        scene.detonate()
                    } label: {
                        Text("NUKE")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .padding(.horizontal, 26)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(.red.opacity(0.9)))
                            .foregroundStyle(.white)
                    }

                    Button {
                        scene.clearAll()
                    } label: {
                        Text("Clear")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(.white.opacity(0.14)))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 10)
            }
    }
}

struct SandboxView_Previews: PreviewProvider {
    static var previews: some View {
        SandboxView()
    }
}
