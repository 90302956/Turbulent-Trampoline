//
//  GameScene.swift
//  Bamboo Breakout
/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import SpriteKit
import GameplayKit

let BallCategoryName = "ball"
let PaddleCategoryName = "paddle"
let BlockCategoryName = "block"
let GameMessageName = "gameMessage"
let EnemyCategoryName = "Enemy"

let BallCategory   : UInt32 = 0x1 << 0
let BottomCategory : UInt32 = 0x1 << 1
let BlockCategory  : UInt32 = 0x1 << 2
let PaddleCategory : UInt32 = 0x1 << 3
let BorderCategory : UInt32 = 0x1 << 4
let EnemyCategory  : UInt32 = 0x1 << 5

var numberOfBlocks = 3
var playerScore = 0
var downVector = -30.0
var rlVectorL1 = 0.0
var rlVectorL2 = 0.0
var rlVectorL3 = 0.0
var levelNum = 1
var gameStarted = false
var timesPlayerHit = 0


class GameScene: SKScene, SKPhysicsContactDelegate {
  
  let background = SKSpriteNode(imageNamed: "background")
  let background2 = SKSpriteNode(imageNamed: "background")
    
  enum CollisionTypes: UInt32 {
        case Circle = 1
        case Ball = 2
        case Enemy = 3
  }
    
    // Screen width.
    public var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    // Screen height.
    public var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
  
  var isFingerOnPaddle = false
    
    
  
  let blipSound = SKAction.playSoundFileNamed("pongblip", waitForCompletion: false)
  let blipPaddleSound = SKAction.playSoundFileNamed("paddleBlip", waitForCompletion: false)
  let bambooBreakSound = SKAction.playSoundFileNamed("BambooBreak", waitForCompletion: false)
  let gameWonSound = SKAction.playSoundFileNamed("game-won", waitForCompletion: false)
  let gameOverSound = SKAction.playSoundFileNamed("game-over", waitForCompletion: false)
    
  var bestScore: SKLabelNode!
  var livesCounterText: SKLabelNode!

  
  // MARK: - Setup
  override func didMove(to view: SKView) {
    
    livesCounterText = SKLabelNode(fontNamed: "Futura-CondensedExtraBold")
    livesCounterText.zPosition = 5
    livesCounterText.position = CGPoint(x:(0.12 * (frame.midX)), y:(0.12 * (frame.midY)))
    livesCounterText.fontSize = 20
    livesCounterText.text = "Lives:"
    livesCounterText.fontColor = SKColor.orange
    self.addChild(livesCounterText)
    
    bestScore = SKLabelNode(fontNamed: "Futura-CondensedExtraBold")
    bestScore.zPosition = 5
    bestScore.position = CGPoint(x: (1.65 * (frame.midX)), y: (1.8 * (frame.midY)))
    bestScore.fontSize = 30
    bestScore.text = "High Score: \(UserDefaults.standard.integer(forKey: "bestScore"))"
    bestScore.fontColor = SKColor.orange
    self.addChild(bestScore)
    
    background.anchorPoint = CGPoint(x: 0, y: 0)
    background.position = CGPoint(x: 0, y: 0)
    background.zPosition = 1
    addChild(background)
    
    background2.anchorPoint = CGPoint(x: 0, y: 0)
    background2.position = CGPoint(x: background2.size.width, y: 0)
    addChild(background2)
    
    super.didMove(to: view)
    // 1.
    let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
    // 2.
    borderBody.friction = 0
    // 3.
    self.physicsBody = borderBody
    self.physicsBody!.affectedByGravity = false
    self.physicsBody!.usesPreciseCollisionDetection = true
    self.physicsBody!.isDynamic = true
    self.physicsBody!.mass = 0
    self.physicsBody!.friction = 0
    self.physicsBody!.linearDamping = 0
    self.physicsBody!.angularDamping = 0
    self.physicsBody!.restitution = 0
    physicsWorld.contactDelegate = self
    
    let ball = childNode(withName: BallCategoryName) as! SKSpriteNode
    ball.name = "Ball"
    
    
    let bottomRect = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 1)
    let bottom = SKNode()
    bottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
    addChild(bottom)
    
    let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
    paddle.name = "Paddle"
    
    bottom.physicsBody!.categoryBitMask = BottomCategory
    bottom.name = "Bottom"
    ball.physicsBody!.categoryBitMask = BallCategory
    paddle.physicsBody!.categoryBitMask = PaddleCategory
    borderBody.categoryBitMask = BorderCategory
    ball.physicsBody!.affectedByGravity = true
    ball.physicsBody!.restitution = 0.0
    ball.physicsBody!.linearDamping = 0
    ball.physicsBody!.friction = 0.0
    ball.physicsBody?.isDynamic = true
    ball.physicsBody!.mass = 0.5
    ball.physicsBody!.allowsRotation = false
    ball.physicsBody!.categoryBitMask = CollisionTypes.Ball.rawValue
    ball.physicsBody!.contactTestBitMask = BottomCategory | BlockCategory | BorderCategory | PaddleCategory
    
    // 1.
    let blockWidth = SKSpriteNode(imageNamed: "block").size.width
    let totalBlocksWidth = blockWidth * CGFloat(numberOfBlocks)
    // 2.
    let xOffset = (frame.width - totalBlocksWidth) / 2
    // 3.
    for i in 0..<numberOfBlocks {
      let block = SKSpriteNode(imageNamed: "block.png")
      block.position = CGPoint(x: xOffset + CGFloat(CGFloat(i) + 0.5) * blockWidth,
                               y: frame.height * 0.6)
      
      block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
      block.physicsBody!.allowsRotation = false
      block.physicsBody!.friction = 0.0
      block.physicsBody!.affectedByGravity = false
      block.physicsBody!.isDynamic = false
      block.name = "Block"
      block.physicsBody!.categoryBitMask = BlockCategory
      block.zPosition = 2
      addChild(block)
    }
    for i in 0..<timesPlayerHit {
        let theHealth = SKSpriteNode(imageNamed: "\(timesPlayerHit)" + "lives")
        theHealth.position = CGPoint(x:(50 + (0.12 * (frame.midX))), y:(8 + (0.12 * (frame.midY))))
        theHealth.zPosition = 5
        timeLeft.fontColor = UIColor.orange
        timeLeft.fontSize = 30
        timeLeft.fontName = "Futura-CondensedExtraBold"
        addChild(theHealth)
    }
    
    let gameMessage = SKSpriteNode(imageNamed: "tapStart")
    gameMessage.name = GameMessageName
    gameMessage.position = CGPoint(x: frame.midX, y: frame.midY)
    gameMessage.zPosition = 4
    gameMessage.setScale(0.0)
    addChild(gameMessage)
    
    levelLabel.position = CGPoint(x: (0.2 * (frame.midX)), y: (1.8 * (frame.midY)))
    levelLabel.zPosition = 4
    levelLabel.fontName = "Futura-CondensedExtraBold"
    levelLabel.text = "Level: " + "\(levelNum)"
    levelLabel.fontColor = UIColor.orange
    levelLabel.fontSize = 30
    addChild(levelLabel)
    
    let trailNode = SKNode()
    trailNode.zPosition = 1
    addChild(trailNode)
    let trail = SKEmitterNode(fileNamed: "BallTrail")!
    trail.targetNode = trailNode
    ball.addChild(trail)
    
    generateEnemies()
  }
  let levelLabel = SKLabelNode()
  let timeLeft = SKLabelNode()
  func createScore() {
        timeLeft.position = CGPoint(x: frame.midX, y: (1.8 * (frame.midY)))
        timeLeft.zPosition = 4
        timeLeft.fontName = "Futura-CondensedExtraBold"
        timeLeft.text = "Score: " + "\(playerScore)"
        timeLeft.fontColor = UIColor.orange
        timeLeft.fontSize = 30
        addChild(timeLeft)
  }
  // MARK: Events
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      let touch = touches.first
      let touchLocation = touch!.location(in: self)
      numberOfBlocks = 2
      
      if let body = physicsWorld.body(at: touchLocation) {
        if body.node!.name == "Paddle" {
          isFingerOnPaddle = true
        }
      }
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    // 1.
    if isFingerOnPaddle {
      // 2.
      let touch = touches.first
      let touchLocation = touch!.location(in: self)
      let previousLocation = touch!.previousLocation(in: self)
      // 3.
      let paddle = childNode(withName: "Paddle") as! SKSpriteNode
      // 4.
      var paddleX = paddle.position.x + (touchLocation.x - previousLocation.x)
      // 5.
      paddleX = max(paddleX, paddle.size.width/2)
      paddleX = min(paddleX, size.width - paddle.size.width/2)
      // 6.
      paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
    }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    isFingerOnPaddle = false
  }
  
  override func update(_ currentTime: TimeInterval) {
    
    background.position = CGPoint(x: background.position.x - 1, y: background.position.y)
    background2.position = CGPoint(x: background2.position.x - 1, y: background2.position.y)
    
    if(background.position.x < -background.size.width){
        background.position = CGPoint(x: background2.position.x + background2.size.width, y: background.position.y)
    }
    if(background2.position.x < -background2.size.width){
        background2.position = CGPoint(x:background.position.x + background.size.width, y: background2.position.y)
    }
    
    timeLeft.removeFromParent()
    createScore()
    var numberOfBricks = 0
    self.enumerateChildNodes(withName: BlockCategoryName) {
        node, stop in
        numberOfBricks = numberOfBricks + 1
        
    }
    randomDirection()
    if (playerScore >= 10) {
        levelNum = 2
    } else if (playerScore >= 20) {
        levelNum = 3
    }
    levelLabel.text = "Level: " + "\(levelNum)"
    print(playerScore)
    if numberOfBricks == 0 {
        let blockWidth = SKSpriteNode(imageNamed: "block").size.width
        let totalBricksWidth = blockWidth * CGFloat(numberOfBricks)
        // 2.
        let xOffset = (frame.width - totalBricksWidth) / 2
        // 3.
        for i in 0..<numberOfBricks {
            let block = SKSpriteNode(imageNamed: "block.png")
            block.position = CGPoint(x: xOffset + CGFloat(CGFloat(i) + 0.5) * blockWidth,
                                     y: frame.height * 1.0)
            
            block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
            block.physicsBody!.allowsRotation = false
            block.physicsBody!.friction = 0.0
            block.physicsBody!.affectedByGravity = false
            block.physicsBody!.isDynamic = false
            block.name = BlockCategoryName
            block.physicsBody!.categoryBitMask = BlockCategory
            block.zPosition = 2
            addChild(block)
        }
    }
  }
  
  // MARK: - SKPhysicsContactDelegate
  func didBegin(_ contact: SKPhysicsContact) {
    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody
    
    if contact.bodyA.node?.name == "Paddle" {
        firstBody = contact.bodyA
        secondBody = contact.bodyB
        
    } else {
        firstBody = contact.bodyB
        secondBody = contact.bodyA
    }
    if firstBody.node?.name == "Paddle" && secondBody.node?.name == "Ball" {
        if(levelNum == 1){
            let ball = self.childNode(withName: "Ball") as! SKSpriteNode
            print("Contact Detected!")
            playerScore += 1
            ball.physicsBody!.applyImpulse(CGVector(dx: rlVectorL1, dy: 0.0))
        }else if (levelNum == 2){
            let ball = self.childNode(withName: "Ball") as! SKSpriteNode
            print("Contact Detected!")
            playerScore += 1
            ball.physicsBody!.applyImpulse(CGVector(dx: rlVectorL2, dy: 0.0))
        }else if (levelNum == 3){
            let ball = self.childNode(withName: "Ball") as! SKSpriteNode
            print("Contact Detected!")
            playerScore += 1
            ball.physicsBody!.applyImpulse(CGVector(dx: rlVectorL3, dy: 0.0))
        }
    }
    if firstBody.node?.name == "Ball" && secondBody.node?.name == "Bottom" {
        timesPlayerHit += 1
        loseLife()

        if (timesPlayerHit >= 3) {
            gameOverScreen()
            displayGameOver()
        }
        updateScore()
    }
    if firstBody.node?.name == "Ball" && secondBody.node?.name == "Block" {
        breakBlock(secondBody.node!)
    }
    if firstBody.node?.name == "Enemy" && secondBody.node?.name == "Bottom" {
        firstBody.node?.removeFromParent()
        print("Hi")
    }
    if (firstBody.node?.name == "Paddle" && secondBody.node?.name == "Enemy") {
        displayGameOver()
        updateScore()
    }
    if firstBody.node?.name == "Enemy" && secondBody.node?.name == "Block" {
        secondBody.node?.removeFromParent()
    }
  }

  
  // MARK: - Helpers
  func breakBlock(_ node: SKNode) {
    run(bambooBreakSound)
    let particles = SKEmitterNode(fileNamed: "BrokenPlatform")!
    particles.position = node.position
    particles.zPosition = 3
    addChild(particles)
    particles.run(SKAction.sequence([SKAction.wait(forDuration: 1.0), SKAction.removeFromParent()]))
    node.removeFromParent()
    playerScore += 1
  }
  
  func randomFloat(from:CGFloat, to:CGFloat) -> CGFloat {
    let rand:CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    return (rand) * (to - from) + from
  }
    
  func randomDirection() {
    let goRL = Bool.random()
      if (goRL == true) {
        rlVectorL1 = Double.random(in: 0 ..< 20)
        rlVectorL2 = Double.random(in: 10 ..< 35)
        rlVectorL3 = Double.random(in: 50 ..< 100)
      }
      if (goRL == false) {
        rlVectorL1 = Double.random(in: -20 ..< 0)
        rlVectorL2 = Double.random(in: -60 ..< -15)
        rlVectorL3 = Double.random(in: -100 ..< -40)
      }
  }
  
  func isGameWon() -> Bool {
    var numberOfBricks = 0
    self.enumerateChildNodes(withName: BlockCategoryName) {
      node, stop in
      numberOfBricks = numberOfBricks + 1
        
    }
    print(playerScore)
    print(screenHeight)
    print(screenWidth)
    return numberOfBricks == 0
  }
    func displayGameOver() {
        let newScene = GameScene(fileNamed:"GameScene")
        newScene!.scaleMode = .aspectFit
        let reveal = SKTransition.flipHorizontal(withDuration: 3)
        self.view?.presentScene(newScene!, transition: reveal)
        playerScore = 0
        levelNum = 1
        timesPlayerHit = 0
    }
    func loseLife () {
        let newScene = GameScene(fileNamed:"GameScene")
        newScene!.scaleMode = .aspectFit
        let fade = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(newScene!, transition: fade)
    }
    func generateEnemies(){
        
        if(self.action(forKey: "spawning") != nil){return}
        let timer = SKAction.wait(forDuration: 1)
        //let timer = SKAction.waitForDuration(10, withRange: 3)//you can use withRange to randomize duration
        
        let spawnNode = SKAction.run {
            
            let enemy = SKSpriteNode(imageNamed: "enemySprite")
            enemy.name = "Enemy" // name it, so you can access all enemies at once.
            //spawn enemies inside view's bounds
            let spawnLocation = CGPoint(x:Int(arc4random() % UInt32(self.scene!.frame.size.width - enemy.size.width/2)), y:Int(self.scene!.frame.size.height))
            
            enemy.position = spawnLocation
            enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.frame.size)
            enemy.physicsBody!.affectedByGravity = true
            enemy.physicsBody!.restitution = 0.0
            enemy.physicsBody!.linearDamping = 0
            enemy.physicsBody!.friction = 0.0
            enemy.physicsBody?.isDynamic = true
            enemy.physicsBody!.mass = 0.5
            enemy.physicsBody!.allowsRotation = false
            enemy.physicsBody?.categoryBitMask = EnemyCategory
            enemy.physicsBody?.contactTestBitMask = EnemyCategory
            enemy.physicsBody?.collisionBitMask = 0
            enemy.zPosition = 1
            let physicsBody = SKPhysicsBody(circleOfRadius: 12)
            physicsBody.contactTestBitMask = 0x00000006
            physicsBody.allowsRotation = false
            physicsBody.affectedByGravity = true
            physicsBody.restitution = 0.0
            physicsBody.linearDamping = 0
            physicsBody.friction = 0.0
            physicsBody.isDynamic = true
            physicsBody.mass = 0.5
            enemy.physicsBody = physicsBody
            
            self.addChild(enemy)
            print(self.screenHeight)
            print(self.screenWidth)
        }
        let sequence = SKAction.sequence([timer, spawnNode])
        self.run(SKAction.repeatForever(sequence) , withKey: "spawning") // run action with key so you can remove it later
    }
    //1
    func updateScore() {
        if playerScore >= UserDefaults.standard.integer(forKey: "bestScore") {
            UserDefaults.standard.set(playerScore, forKey: "bestScore")
        }
        self.bestScore.text = "High Score: \(UserDefaults.standard.integer(forKey: "bestScore"))"
    }
    func gameOverScreen() {
        let gameOverMsg = SKLabelNode()
        gameOverMsg.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOverMsg.fontColor = SKColor.black
        gameOverMsg.zPosition = 6
        gameOverMsg.fontName = "Copperplate"
        gameOverMsg.text = "Game Over"
        addChild(gameOverMsg)
    }
}
