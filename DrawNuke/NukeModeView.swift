import SwiftUI
import SpriteKit

struct NukeModeView: View {
    @State private var scene = NukeScene(size: UIScreen.main.bounds.size)
    @State private var paintIndex = 0

    private let paints: [Color] = [.green, .red, .orange, .yellow, .cyan, .purple, .pink, .white]

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ForEach(paints.indices, id: \.self) { index in
                            Button {
                                paintIndex = index
                                scene.paintColor = SKColor(paints[index])
                            } label: {
                                Circle()
                                    .fill(paints[index])
                                    .frame(width: 28, height: 28)
                                    .overlay {
                                        Circle().stroke(.white, lineWidth: paintIndex == index ? 3 : 0)
                                    }
                            }
                        }
                    }

                    HStack(spacing: 14) {
                        Button {
                            scene.resetNuke()
                        } label: {
                            Text("Rebuild")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(.white.opacity(0.14)))
                                .foregroundStyle(.white)
                        }

                        Button {
                            scene.launch()
                        } label: {
                            Text("TEST FIRE")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .padding(.horizontal, 26)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(.red.opacity(0.9)))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.bottom, 10)
            }
    }
}

struct NukeModeView_Previews: PreviewProvider {
    static var previews: some View {
        NukeModeView()
    }
}
