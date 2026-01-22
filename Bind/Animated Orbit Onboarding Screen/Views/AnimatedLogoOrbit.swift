//
//  AnimatedLogoOrbit.swift
//  Apple iCloud Setup Animation
//
//  Created by Alex Walters on 08/01/2026.
//

import SwiftUI
import SpriteKit
import UIKit

struct AnimatedLogoOrbit: View {
    let images: [String]
    
    @State private var scene: AnimatedLogoOrbitScene?
    
    var body: some View {
        ZStack {
            if let scene {
                SpriteView(
                    scene: scene,
                    options: [.allowsTransparency]
                )
            }
        }
        .onAppear {
            setupScene()
        }
    }
    
    private func setupScene() {
        let newScene = AnimatedLogoOrbitScene()
        newScene.images = images
        newScene.scaleMode = .resizeFill
        scene = newScene
    }
}

class AnimatedLogoOrbitScene: SKScene {
    var images: [String] = []
    
    let dotsPerCircle = 23
    let numCircles = 4
    
    var outerCircleDots: [SKShapeNode] = []
    var nextIconIndex = 0
    var originalPositions: [CGPoint] = []
    
    let container = SKNode()
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        physicsWorld.gravity = .zero
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        addChild(container)
        buildCircles()
        startRotation()
        animateNextIcon()
    }
    
    private func iconTexture(for name: String) -> (SKTexture, CGSize) {
        // Using .medium weight to prevent the "fat" look of .bold symbols
        let configuration = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        let image = UIImage(systemName: name, withConfiguration: configuration)?
            .withTintColor(.black, renderingMode: .alwaysOriginal)
        
        let texture = image != nil ? SKTexture(image: image!) : SKTexture()
        return (texture, image?.size ?? .zero)
    }
    
    private func buildCircles() {
        let circles = generateCircles()
        var angleOffset: CGFloat = 0
        
        for (circleIndex, circle) in circles.enumerated() {
            for dotIndex in 0..<dotsPerCircle {
                var angle = (2 * .pi / CGFloat(dotsPerCircle) * CGFloat(dotIndex)) + angleOffset
                if angle > 2 * .pi { angle -= 2 * .pi }
                
                let position = CGPoint(x: circle.radius * cos(angle), y: circle.radius * sin(angle))
                
                let dot = SKShapeNode(circleOfRadius: circle.size)
                dot.position = position
                dot.fillColor = .black
                dot.strokeColor = .clear
                dot.name = "dot-\(circleIndex)"
                dot.physicsBody = SKPhysicsBody(circleOfRadius: circle.size + 3)
                dot.physicsBody?.isDynamic = true
                dot.physicsBody?.affectedByGravity = false
                
                if circleIndex == 0 {
                    let step = max(1, Int(round(Double(dotsPerCircle) / Double(max(images.count, 1)))))
                    if dotIndex % step == 0 {
                        // Add icon to the popping dots
                        let imgIndex = outerCircleDots.count % images.count
                        let iconName = images[imgIndex]
                        let (texture, originalSize) = iconTexture(for: iconName)
                        let icon = SKSpriteNode(texture: texture)
                        icon.name = "icon"
                        
                        // Calculate size maintaining aspect ratio
                        let aspectRatio = originalSize.width / originalSize.height
                        
                        var targetDimension: CGFloat = 8.0
                        
                        if aspectRatio > 1 {
                            icon.size = CGSize(width: targetDimension, height: targetDimension / aspectRatio)
                        } else {
                            icon.size = CGSize(width: targetDimension * aspectRatio, height: targetDimension)
                        }
                        
                        icon.alpha = 0
                        dot.addChild(icon)
                        
                        outerCircleDots.append(dot)
                    }
                }
                
                container.addChild(dot)
                originalPositions.append(position)
            }
            
            angleOffset += 0.4
        }
        
        // icons should animate clockwise
        outerCircleDots.reverse()
    }
    
    private func startRotation() {
        let rotate = SKAction.rotate(byAngle: .pi * -2, duration: 10)
        container.run(.repeatForever(rotate))
    }
    
    private func animateNextIcon() {
        let dot = outerCircleDots[nextIconIndex]
        let icon = dot.childNode(withName: "icon")
        
        dot.physicsBody? = SKPhysicsBody(circleOfRadius: 10)
        dot.physicsBody?.density = 110
        dot.physicsBody?.isDynamic = false
        
        let scaleIcon = SKAction.run {
            let a1 = SKAction.scale(to: 4.0 * 1.1, duration: 0.1)
            let a2 = SKAction.scale(to: 4.0, duration: 0.1)
            
            dot.run(.sequence([a1, a2]))
            icon?.run(.fadeIn(withDuration: 0.15))
        }
        
        let wait = SKAction.wait(forDuration: 1)
        
        let shrinkIcon = SKAction.run {
            let scale = SKAction.scale(to: 1.0, duration: 0.6)
            scale.timingFunction = SpriteKitTimingFunctions.easeInQuad
            dot.run(scale)
            icon?.run(.fadeOut(withDuration: 0.4))
        }
        
        // move dots back to their original position
        let moveDots = SKAction.run {
            for (i, surroundingDot) in self.container.children.enumerated()
            where !surroundingDot.position.isApproximatelyEqual(to: self.originalPositions[i])
            {
                let moveAction = SKAction.move(to: self.originalPositions[i], duration: 0.6)
                moveAction.timingFunction = SpriteKitTimingFunctions.easeInQuad
                surroundingDot.run(moveAction)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.nextIconIndex = (self.nextIconIndex + 1) % self.outerCircleDots.count
                self.animateNextIcon()
            }
        }

        dot.run(.sequence([scaleIcon, wait, moveDots, shrinkIcon])) {
            dot.physicsBody?.isDynamic = true
        }
    }
    
    private func generateCircles() -> [(radius: CGFloat, size: CGFloat)] {
        let radiusStep = 15
        let initialRadius = 75
        var dotSize = 4
        
        var circles: [(CGFloat, CGFloat)] = []
        
        for circleIndex in 0..<numCircles {
            let radius = CGFloat(initialRadius + (circleIndex * radiusStep))
            circles.append((CGFloat(radius), CGFloat(dotSize)))
            
            if circleIndex == 0 {
                dotSize += 2
            } else if circleIndex % 2 == 0 {
                dotSize += 3
            } else {
                dotSize -= 1
            }
        }
        
        return Array(circles.reversed())
    }
    
    override func update(_ currentTime: TimeInterval) {
        for case let dot as SKShapeNode in container.children {
            dot.fillColor = .white
        }
        
        // Keep all outer circle dots (and their icons) upright relative to the screen
        for dot in outerCircleDots {
            dot.zRotation = -container.zRotation
        }
    }
    
}

#Preview {
    AnimatedLogoOrbit(
        images: ["messages", "app-store", "find-my", "music", "cloud", "files", "wallet", "photos"]
    )
}

