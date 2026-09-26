import UIKit
import SpriteKit

class NukeScene: SKScene {
    var paintColor: SKColor = .systemGreen

    private let missileSize = CGSize(width: 72, height: 175)
    private var missile = SKNode()
    private var paintPath = UIBezierPath()
    private var paintNode: SKShapeNode?
    private var hasLaunched = false

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.04, blue: 0.08, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        scaleMode = .resizeFill
        setup()
    }

    private func setup() {
        addBorder()
        spawnBuildings()
        spawnMissile()
        showHint()
    }

    private func addBorder() {
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let border = SKShapeNode(rect: frame)
        border.name = "border"
        border.strokeColor = SKColor(white: 0.25, alpha: 1)
        border.lineWidth = 3
        border.physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        border.physicsBody?.friction = 0.8
        border.zPosition = 1
        addChild(border)
    }

    private func spawnBuildings() {
        var x: CGFloat = 36
        while x < size.width - 70 {
            let width = CGFloat.random(in: 52...92)
            let height = CGFloat.random(in: 70...170)
            let building = SKShapeNode(rect: CGRect(x: 0, y: 0, width: width, height: height))
            building.fillColor = SKColor(white: 0.22, alpha: 1)
            building.strokeColor = SKColor(white: 0.35, alpha: 1)
            building.lineWidth = 2
            building.position = CGPoint(x: x, y: 0)
            building.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: width, height: height), center: CGPoint(x: width / 2, y: height / 2))
            building.physicsBody?.isDynamic = false
            building.physicsBody?.friction = 0.9
            building.zPosition = 1
            addChild(building)
            x += width + CGFloat.random(in: 18...46)
        }
    }

    private func spawnMissile() {
        missile = SKNode()
        missile.position = CGPoint(x: size.width / 2, y: 100)
        missile.zPosition = 2

        let hull = SKShapeNode(path: missilePath().cgPath)
        hull.fillColor = SKColor(white: 0.3, alpha: 1)
        hull.strokeColor = .white
        hull.lineWidth = 2
        hull.glowWidth = 3
        missile.addChild(hull)

        missile.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: missileSize.width + 16, height: missileSize.height))
        missile.physicsBody?.isDynamic = true
        missile.physicsBody?.affectedByGravity = false
        missile.physicsBody?.friction = 0.6

        addChild(missile)
    }

    private func missilePath() -> UIBezierPath {
        let w = missileSize.width
        let h = missileSize.height
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: -h / 2))
        path.addLine(to: CGPoint(x: -w / 2, y: -h / 2 + 28))
        path.addLine(to: CGPoint(x: -w / 4, y: -h / 2 + 34))
        path.addLine(to: CGPoint(x: -w / 2, y: h / 2 - 42))
        path.addQuadCurve(to: CGPoint(x: 0, y: h / 2), controlPoint: CGPoint(x: -w / 2 - 8, y: h / 2 - 12))
        path.addQuadCurve(to: CGPoint(x: w / 2, y: h / 2 - 42), controlPoint: CGPoint(x: w / 2 + 8, y: h / 2 - 12))
        path.addLine(to: CGPoint(x: w / 4, y: -h / 2 + 34))
        path.addLine(to: CGPoint(x: w / 2, y: -h / 2 + 28))
        path.close()
        return path
    }

    private func showHint() {
        let hint = SKLabelNode(text: "Paint your nuke   -   Then TEST FIRE")
        hint.fontName = "ArialRoundedMTBold"
        hint.fontSize = 17
        hint.fontColor = SKColor(white: 0.75, alpha: 1)
        hint.position = CGPoint(x: size.width / 2, y: size.height - 84)
        hint.zPosition = 20
        addChild(hint)
        hint.run(.sequence([.wait(forDuration: 4), .fadeAlpha(to: 0, duration: 1), .removeFromParent()]))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !hasLaunched, let touch = touches.first else { return }

        paintPath = UIBezierPath()
        paintPath.move(to: convert(touch.location(in: self), to: missile))

        let node = SKShapeNode(path: paintPath.cgPath)
        node.strokeColor = paintColor
        node.lineWidth = 6
        node.lineCap = .round
        node.lineJoin = .round
        node.glowWidth = 4
        node.zPosition = 3
        paintNode = node
        missile.addChild(node)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !hasLaunched, let touch = touches.first, paintNode != nil else { return }
        paintPath.addLine(to: convert(touch.location(in: self), to: missile))
        paintNode?.path = paintPath.cgPath
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        paintNode = nil
    }

    func launch() {
        guard !hasLaunched else { return }
        hasLaunched = true

        addTrail()

        let duration: CGFloat = 0.85
        let targetY = size.height * 0.68
        let rise = max(targetY - missile.position.y, 100)
        missile.physicsBody?.affectedByGravity = true
        missile.physicsBody?.velocity = CGVector(dx: 0, dy: rise / duration)
        missile.physicsBody?.angularVelocity = CGFloat.random(in: -0.8...0.8)

        run(.sequence([
            .wait(forDuration: Double(duration)),
            .run { [weak self] in self?.detonate() }
        ]))
    }

    private func addTrail() {
        let trail = SKEmitterNode()
        trail.particleTexture = TextureFactory.glowCircleTexture(radius: 12, color: UIColor(red: 1.0, green: 0.65, blue: 0.2, alpha: 1.0))
        trail.numParticles = 0
        trail.particleBirthRate = 350
        trail.particleLifetime = 0.7
        trail.particleSpeed = 90
        trail.particleScale = 1.1
        trail.particleScaleSpeed = -1.4
        trail.particleColor = .orange
        trail.position = CGPoint(x: 0, y: -missileSize.height / 2)
        trail.zPosition = 1
        missile.addChild(trail)
    }

    private func detonate() {
        let center = missile.position
        missile.removeFromParent()

        flashWhite()
        fireball(at: center)
        shockRing(at: center)
        mushroomCloud(at: center)
        boomLabel(at: center)
        shakeScreen()
        blastBuildings(from: center)
    }

    private func blastBuildings(from center: CGPoint) {
        let radius = max(size.width, size.height) * 1.4
        physicsWorld.enumerateBodies { body, _ in
            guard let node = body.node, node.name != "border" else { return }
            if !body.isDynamic {
                body.isDynamic = true
            }
            let dx = node.position.x - center.x
            let dy = node.position.y - center.y
            let distance = sqrt(dx * dx + dy * dy)
            guard distance < radius, distance > 0 else { return }
            let strength = 1100 * (1 - distance / radius)
            let length = max(distance, 1)
            body.applyImpulse(CGVector(dx: dx / length * strength, dy: dy / length * strength + 250))
            body.applyAngularImpulse(CGFloat.random(in: -4...4))
        }
    }

    private func mushroomCloud(at point: CGPoint) {
        let smoke = TextureFactory.glowCircleTexture(radius: 42, color: UIColor(white: 0.55, alpha: 0.85))

        let stem = SKEmitterNode()
        stem.particleTexture = smoke
        stem.numParticles = 380
        stem.particleBirthRate = 420
        stem.particleLifetime = 2.2
        stem.particleLifetimeRange = 0.8
        stem.particleSpeed = 310
        stem.particleSpeedRange = 60
        stem.emissionAngle = .pi / 2
        stem.emissionAngleRange = 0.3
        stem.particleColor = SKColor(white: 0.45, alpha: 1)
        stem.particleScale = 1.5
        stem.particleScaleRange = 0.6
        stem.particleScaleSpeed = 0.25
        stem.position = point
        stem.zPosition = 25
        addChild(stem)
        stem.run(.sequence([.wait(forDuration: 3.5), .removeFromParent()]))

        let cap = SKEmitterNode()
        cap.particleTexture = smoke
        cap.numParticles = 240
        cap.particleBirthRate = 260
        cap.particleLifetime = 2.8
        cap.particleLifetimeRange = 0.8
        cap.particleSpeed = 130
        cap.particleSpeedRange = 70
        cap.emissionAngle = .pi / 2
        cap.emissionAngleRange = .pi
        cap.particleColor = SKColor(white: 0.62, alpha: 1)
        cap.particleScale = 2.4
        cap.particleScaleRange = 0.8
        cap.particleScaleSpeed = 0.15
        cap.position = CGPoint(x: point.x, y: point.y + 210)
        cap.zPosition = 25
        addChild(cap)
        cap.run(.sequence([.wait(forDuration: 4), .removeFromParent()]))
    }

    private func boomLabel(at point: CGPoint) {
        let label = SKLabelNode(text: "BOOM")
        label.fontName = "ArialRoundedMTBold"
        label.fontSize = 96
        label.fontColor = .yellow
        label.position = point
        label.zPosition = 45
        label.setScale(0.1)
        label.alpha = 0
        addChild(label)
        label.run(.sequence([
            .group([.scale(to: 1.35, duration: 0.3), .fadeAlpha(to: 1, duration: 0.15)]),
            .wait(forDuration: 1.1),
            .fadeAlpha(to: 0, duration: 0.5),
            .removeFromParent()
        ]))
    }

    func resetNuke() {
        removeAllChildren()
        paintNode = nil
        hasLaunched = false
        setup()
    }
}
