import SwiftUI

struct Stroke {
    var points: [CGPoint]
    var color: Color
    var width: CGFloat
    var glow: Bool
}

struct DrawModeView: View {
    @State private var strokes: [Stroke] = []
    @State private var current: Stroke?
    @State private var selectedColor: Color = .green
    @State private var brushWidth: Double = 6
    @State private var glow = true

    private let palette: [Color] = [.white, .red, .orange, .yellow, .green, .mint, .cyan, .blue, .purple, .pink]

    var body: some View {
        VStack(spacing: 0) {
            canvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)

            controls
                .padding(16)
                .background(Color(white: 0.08))
        }
        .navigationTitle("Draw")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canvas: some View {
        Canvas { context, size in
            for stroke in strokes {
                render(stroke, in: &context)
            }
            if let current {
                render(current, in: &context)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if current == nil {
                        current = Stroke(points: [value.location], color: selectedColor, width: CGFloat(brushWidth), glow: glow)
                    } else {
                        current?.points.append(value.location)
                    }
                }
                .onEnded { _ in
                    if let finished = current, finished.points.count > 1 {
                        strokes.append(finished)
                    }
                    current = nil
                }
        )
    }

    private func render(_ stroke: Stroke, in context: inout GraphicsContext) {
        guard let first = stroke.points.first else { return }

        if stroke.points.count == 1 {
            let dot = CGRect(x: first.x - stroke.width / 2, y: first.y - stroke.width / 2, width: stroke.width, height: stroke.width)
            context.fill(Path(ellipseIn: dot), with: .color(stroke.color))
            return
        }

        var path = Path()
        path.move(to: first)
        for point in stroke.points.dropFirst() {
            path.addLine(to: point)
        }

        if stroke.glow {
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: stroke.width * 0.55))
                layer.stroke(path, with: .color(stroke.color), lineWidth: stroke.width)
            }
        }
        context.stroke(path, with: .color(stroke.color), lineWidth: stroke.width)
    }

    private var controls: some View {
        VStack(spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(palette, id: \.self) { color in
                        Button {
                            selectedColor = color
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Circle().stroke(.white, lineWidth: selectedColor == color ? 3 : 0)
                                }
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Text("Size")
                    .foregroundStyle(.white)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Slider(value: $brushWidth, in: 2...30)
                Toggle("Glow", isOn: $glow)
                    .fixedSize()
            }

            HStack(spacing: 12) {
                Button("Undo") {
                    if !strokes.isEmpty { strokes.removeLast() }
                }
                Button("Clear All") {
                    strokes.removeAll()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }
}

struct DrawModeView_Previews: PreviewProvider {
    static var previews: some View {
        DrawModeView()
    }
}
