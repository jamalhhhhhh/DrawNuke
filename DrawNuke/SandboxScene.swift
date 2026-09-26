import UIKit
import SpriteKit

class SandboxScene: SKScene {
    private var paintPath = UIBezierPath()
    private var paintNode: SKShapeNode?

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        scaleMode = .resizeFill
        addBorder()
        showHint()
        spawnDebris()
    }

    private func addBorder() {
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let border = SKShapeNode(rect: frame)
        border.strokeColor = SKColor(white: 0.25, alpha: 1)
        border.lineWidth = 3
        border.physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        border.physicsBody?.friction = 0.8
        border.zPosition = 1
        addChild(border)
    }

    private func showHint() {
        let hint = SKLabelNode(text: "Draw ramps & walls   -   Drop crates   -   Press NUKE")
        hint.fontName = "ArialRoundedMTBold"
        hint.fontSize = 17
        hint.fontColor = SKColor(white: 0.75, alpha: 1)
        hint.position = CGPoint(x: size.width / 2, y: size.height - 84)
        hint.zPosition = 20
        addChild(hint)
        hint.run(.sequence([.wait(forDuration: 4), .fadeAlpha(to: 0, duration: 1), .removeFromParent()]))
    }

    func spawnDebris() {
        for _ in 0..<8 {
            let isBall = Bool.random()
            let side = CGFloat.random(in: 22...42)

            let node = isBall
                ? SKShapeNode(circleOfRadius: side / 2)
                : SKShapeNode(rectOf: CGSize(width: side, height: side))
            let body = isBall
                ? SKPhysicsBody(circleOfRadius: side / 2)
                : SKPhysicsBody(rectangleOf: CGSize(width: side, height: side))

            node.fillColor = isBall ? SKColor.systemYellow : SKColor.systemOrange
            node.strokeColor = .white
            node.lineWidth = 2
            node.position = CGPoint(x: CGFloat.random(in: 40...(size.width - 40)), y: size.height - 60)
            node.physicsBody = body
            node.physicsBody?.restitution = 0.55
            node.physicsBody?.friction = 0.5
            node.name = "debris"
            node.zPosition = 2
            addChild(node)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        paintPath = UIBezierPath()
        paintPath.move(to: point)

        let node = SKShapeNode(path: paintPath.cgPath)
        node.strokeColor = .systemGreen
        node.lineWidth = 6
        node.lineCap = .round
        node.lineJoin = .round
        node.glowWidth = 4
        node.zPosition = 3
        node.name = "drawing"
        paintNode = node
        addChild(node)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, paintNode != nil else { return }
        paintPath.addLine(to: touch.location(in: self))
        paintNode?.path = paintPath.cgPath
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = paintNode else { return }
        paintNode = nil

        let bounds = paintPath.cgPath.boundingBox
        guard bounds.width > 6 || bounds.height > 6 else {
            node.removeFromParent()
            return
        }

        node.physicsBody = SKPhysicsBody(edgeChainFrom: paintPath.cgPath)
        node.physicsBody?.friction = 0.7
        node.physicsBody?.restitution = 0.2
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.isDynamic = false
    }

    func detonate() {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.32)

        flashWhite()
        fireball(at: center)
        shockRing(at: center)
        shakeScreen()

        let radius = max(size.width, size.height) * 1.2
        for node in children {
            guard let body = node.physicsBody, body.isDynamic else { continue }
            let dx = node.position.x - center.x
            let dy = node.position.y - center.y
            let distance = sqrt(dx * dx + dy * dy)
            guard distance < radius, distance > 0 else { continue }
            let strength = 950 * (1 - distance / radius)
            let length = max(distance, 1)
            body.applyImpulse(CGVector(dx: dx / length * strength, dy: dy / length * strength + 180))
            body.applyAngularImpulse(CGFloat.random(in: -3...3))
        }
    }

    func clearAll() {
        for child in children where child.name == "drawing" || child.name == "debris" {
            child.removeFromParent()
        }
    }
}
