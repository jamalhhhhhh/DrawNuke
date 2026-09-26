import UIKit
import SpriteKit

enum TextureFactory {
    static func glowCircleTexture(radius: CGFloat, color: UIColor) -> SKTexture {
        let side = max(radius * 2, 4)
        let size = CGSize(width: side, height: side)
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return SKTexture() }

        let colors = [color.cgColor, color.withAlphaComponent(0).cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
            let center = CGPoint(x: side / 2, y: side / 2)
            ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: side / 2, options: [])
        }

        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return SKTexture() }
        return SKTexture(image: image)
    }
}

extension SKScene {
    func flashWhite() {
        let flash = SKSpriteNode(color: .white, size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 40
        flash.alpha = 0.85
        addChild(flash)
        flash.run(.sequence([
            .wait(forDuration: 0.07),
            .fadeAlpha(to: 0, duration: 0.55),
            .removeFromParent()
        ]))
    }

    func fireball(at point: CGPoint) {
        let emitter = SKEmitterNode()
        emitter.particleTexture = TextureFactory.glowCircleTexture(radius: 26, color: UIColor(red: 1.0, green: 0.55, blue: 0.1, alpha: 1.0))
        emitter.particleBirthRate = 900
        emitter.particleLifetime = 1.1
        emitter.particleLifetimeRange = 0.5
        emitter.particleSpeed = 420
        emitter.particleSpeedRange = 260
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 1.3
        emitter.particleScaleRange = 0.8
        emitter.particleScaleSpeed = -0.7
        emitter.particleColor = .orange
        emitter.position = point
        emitter.zPosition = 30
        addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 1.2), .fadeAlpha(to: 0, duration: 0.8), .removeFromParent()]))
    }

    func shockRing(at point: CGPoint) {
        let ring = SKShapeNode(circleOfRadius: 14)
        ring.strokeColor = .orange
        ring.lineWidth = 5
        ring.glowWidth = 8
        ring.position = point
        ring.zPosition = 30
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 26, duration: 0.55), .fadeAlpha(to: 0, duration: 0.55)]),
            .removeFromParent()
        ]))
    }

    func shakeScreen() {
        run(.sequence([
            .moveBy(x: -14, y: 10, duration: 0.045),
            .moveBy(x: 17, y: -12, duration: 0.045),
            .moveBy(x: -12, y: -9, duration: 0.045),
            .moveBy(x: 9, y: 11, duration: 0.045)
        ]))
    }
}
