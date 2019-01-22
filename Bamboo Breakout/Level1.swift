//
//  Playing.swift
//  BreakoutSpriteKitTutorial
//
//  Created by Michael Briscoe on 1/16/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import SpriteKit
import GameplayKit

class Level1: GKState {
  unowned let scene: GameScene
  
  init(scene: SKScene) {
    self.scene = scene as! GameScene
    super.init()
  }
  
  override func didEnter(from previousState: GKState?) {
    if previousState is WaitingForTap {
        let ball = scene.childNode(withName: "Ball") as! SKSpriteNode
        ball.physicsBody!.applyImpulse(CGVector(dx: 0.0, dy: 0.0))
    }
  }
  
  override func update(deltaTime seconds: TimeInterval) {
    let ball = scene.childNode(withName: "Ball") as! SKSpriteNode
    gameStarted = true
    let maxSpeed: CGFloat = 400.0
    
    let xSpeed = (sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx)) - 100
    let ySpeed = (sqrt(ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)) - 100
    
    let speed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx + ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
    
    if speed > maxSpeed {
      ball.physicsBody!.linearDamping = 0.4
    }
    else {
      ball.physicsBody!.linearDamping = 0.0
    }
  }
    
  override func isValidNextState(_ stateClass: AnyClass) -> Bool {
    return true
  }
}
