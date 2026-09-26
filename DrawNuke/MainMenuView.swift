import SwiftUI

struct ModeCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 64, height: 64)
                .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 22))
    }
}

struct MainMenuView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 22) {
                    VStack(spacing: 6) {
                        Text("DRAW·NUKE")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("three ways to cause chaos")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(.bottom, 14)

                    NavigationLink {
                        DrawModeView()
                    } label: {
                        ModeCard(title: "Draw", subtitle: "Neon paint. No rules.", symbol: "paintbrush.point.fill", color: .green)
                    }

                    NavigationLink {
                        SandboxView()
                    } label: {
                        ModeCard(title: "Sandbox", subtitle: "Build it. Then nuke it.", symbol: "hammer.fill", color: .orange)
                    }

                    NavigationLink {
                        NukeModeView()
                    } label: {
                        ModeCard(title: "Nuke", subtitle: "Paint your own warhead. Test fire.", symbol: "burst.fill", color: .red)
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationBarHidden(true)
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
            .preferredColorScheme(.dark)
    }
}
