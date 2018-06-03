//
//  GameViewController.swift
//  Asteroid_Test
//
//  Created by Willy on 2018/5/16.
//  Copyright © 2018年 Willy. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion

// setting the collision mask
enum CollisionMask: Int {
    case ship = 1
    case asteroid = 2
}

enum GameState: Int {
    case playing
    case dead
    case paused
}


class AsteroidGameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {

    
    // MARK: Properties
    //var gameView: SCNView!
    var gameScene: SCNScene!
    var cameraNode: SCNNode!
    var shipNode: SCNNode!
    var asteroidCreationTiming: Double = 0
    var gameState: GameState!
    var gameOverView: UIView!
    var pauseView: UIView!
    var score: Int = 0
    var scoreLabel: UILabel!
    
    var lastShipVelocity: SCNVector3!
    var lastShipAngularVelocity: SCNVector4!
    
    @IBOutlet var gameView: SCNView!
    
    
    
    // MARK:
    override func viewDidLoad() {
        super.viewDidLoad()
        initGameView()
        initScene()
        initCamera()
        initShip()
        initScore()
        initPauseView()
        initGameOverView()
        gameState = GameState.playing
        accumulateScore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: functions
    
    func initGameView() {
        //gameView = self.view as! SCNView
        gameView.allowsCameraControl = true
        gameView.autoenablesDefaultLighting = true
        gameView.delegate = self
    }
    
    func initScene() {
        gameScene = SCNScene()
        gameView.scene = gameScene
        gameView.scene?.physicsWorld.gravity = SCNVector3(x: 0, y: 0, z: 0)
        gameView.scene?.physicsWorld.speed = 1
        gameScene.background.contents = UIColor.darkGray
        gameScene.physicsWorld.contactDelegate = self
    }
    
    func initCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10   )
        gameScene.rootNode.addChildNode(cameraNode)
    }
    
    func initShip() {
        let shipScene = SCNScene(named: "art.scnassets/retrorockett4k1t.dae")
        shipNode = shipScene?.rootNode.childNodes.first
        shipNode.position = SCNVector3(x: 0, y: 0, z: 0)
        shipNode.scale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
        shipNode.eulerAngles = SCNVector3(x: -(Float.pi/2), y: 0, z: 0)
        // setting the physicsbody of the ship
        shipNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        shipNode.physicsBody?.damping = 0.5
        shipNode.physicsBody?.categoryBitMask = CollisionMask.ship.rawValue
        shipNode.physicsBody?.contactTestBitMask = CollisionMask.asteroid.rawValue
        shipNode.name = "ship"
        gameScene.rootNode.addChildNode(shipNode)
        
    }
    
    func initScore() {
        scoreLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
        scoreLabel.center = CGPoint(x: gameView.bounds.minX+20, y: gameView.bounds.minY+15)
        scoreLabel.text = "\(self.score)"
        scoreLabel.font = UIFont.boldSystemFont(ofSize: 26)
        scoreLabel.textAlignment = .center
        scoreLabel.textColor = UIColor.lightGray
        gameView.addSubview(scoreLabel)
    }
    
    func initPauseView() {
        // the background rectangle
        pauseView = UIView(frame: CGRect(x: 0, y: 0, width: gameView.bounds.width*0.8, height: gameView.bounds.height*0.5))
        pauseView.backgroundColor = UIColor.black
        pauseView.layer.cornerRadius = pauseView.frame.width/4.0
        pauseView.clipsToBounds = true
        pauseView.center = CGPoint(x: gameView.bounds.midX, y: gameView.bounds.midY)
        pauseView.alpha = 0
        gameView.addSubview(pauseView)
        
        let pauseLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        pauseLabel.center = CGPoint(x: pauseView.bounds.midX, y: pauseView.bounds.midY-100)
        pauseLabel.text = "PAUSED"
        pauseLabel.font = UIFont.boldSystemFont(ofSize: 26)
        pauseLabel.textAlignment = .center
        pauseLabel.textColor = UIColor.lightGray
        pauseView.addSubview(pauseLabel)
        
        let returnButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        returnButton.center = CGPoint(x: pauseView.bounds.midX, y: pauseView.bounds.midY-20)
        returnButton.setTitle("Return", for: [])
        returnButton.setTitleColor(UIColor.lightGray, for: [])
        returnButton.setTitleColor(UIColor.white, for: [.highlighted])
        returnButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 26)
        returnButton.isEnabled = true
        returnButton.addTarget(self, action: #selector(AsteroidGameViewController.returnGame), for: .touchUpInside)
        pauseView.addSubview(returnButton)
        
        let replayButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        replayButton.center = CGPoint(x: pauseView.bounds.midX, y: pauseView.bounds.midY+20)
        replayButton.setTitle("Replay", for: [])
        replayButton.setTitleColor(UIColor.lightGray, for: [])
        replayButton.setTitleColor(UIColor.white, for: [.highlighted])
        replayButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 26)
        replayButton.isEnabled = true
        replayButton.addTarget(self, action: #selector(AsteroidGameViewController.restartGame), for: .touchUpInside)
        pauseView.addSubview(replayButton)
        
        let backMenuButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        backMenuButton.center = CGPoint(x: pauseView.bounds.midX, y: pauseView.bounds.midY+60)
        backMenuButton.setTitle("Main Menu", for: [])
        backMenuButton.setTitleColor(UIColor.lightGray, for: [])
        backMenuButton.setTitleColor(UIColor.white, for: [.highlighted])
        backMenuButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 26)
        backMenuButton.isEnabled = true
        backMenuButton.addTarget(self, action: #selector(AsteroidGameViewController.backMenu), for: .touchUpInside)
        pauseView.addSubview(backMenuButton)
    }
    
    func initGameOverView() {
        // the background rectangle
        gameOverView = UIView(frame: CGRect(x: 0, y: 0, width: gameView.bounds.width*0.8, height: gameView.bounds.height*0.5))
        gameOverView.backgroundColor = UIColor.black
        gameOverView.layer.cornerRadius = gameOverView.frame.width/4.0
        gameOverView.clipsToBounds = true
        gameOverView.center = CGPoint(x: gameView.bounds.midX, y: gameView.bounds.midY)
        gameOverView.alpha = 0
        gameView.addSubview(gameOverView)
        
        let gameOverLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        gameOverLabel.center = CGPoint(x: gameOverView.bounds.midX, y: gameOverView.bounds.midY-100)
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.font = UIFont.boldSystemFont(ofSize: 26)
        gameOverLabel.textAlignment = .center
        gameOverLabel.textColor = UIColor.lightGray
        gameOverView.addSubview(gameOverLabel)
        
        let finalScoreLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        finalScoreLabel.center = CGPoint(x: gameOverView.bounds.midX, y: gameOverView.bounds.midY-60)
        finalScoreLabel.text = "Score:"
        finalScoreLabel.font = UIFont.boldSystemFont(ofSize: 26)
        finalScoreLabel.textAlignment = .center
        finalScoreLabel.textColor = UIColor.lightGray
        finalScoreLabel.restorationIdentifier = "finalScoreLabel"
        gameOverView.addSubview(finalScoreLabel)
        
        let replayButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        replayButton.center = CGPoint(x: gameOverView.bounds.midX, y: gameOverView.bounds.midY+20)
        replayButton.setTitle("Replay", for: [])
        replayButton.setTitleColor(UIColor.lightGray, for: [])
        replayButton.setTitleColor(UIColor.white, for: [.highlighted])
        replayButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 26)
        replayButton.isEnabled = true
        replayButton.addTarget(self, action: #selector(AsteroidGameViewController.restartGame), for: .touchUpInside)
        gameOverView.addSubview(replayButton)
        
        let backMenuButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        backMenuButton.center = CGPoint(x: gameOverView.bounds.midX, y: gameOverView.bounds.midY+60)
        backMenuButton.setTitle("Main Menu", for: [])
        backMenuButton.setTitleColor(UIColor.lightGray, for: [])
        backMenuButton.setTitleColor(UIColor.white, for: [.highlighted])
        backMenuButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 26)
        backMenuButton.isEnabled = true
        backMenuButton.addTarget(self, action: #selector(AsteroidGameViewController.backMenu), for: .touchUpInside)
        gameOverView.addSubview(backMenuButton)
    }
    
    @objc func restartGame() {
        for node in gameScene.rootNode.childNodes {
            if node.name == "ship" || node.name == "asteroid" {
                node.removeFromParentNode()
            }
        }
        pauseView.alpha = 0
        gameOverView.alpha = 0
        score = 0
        accumulateScore()
        initShip()
        gameState = GameState.playing
    }
    
    @objc func returnGame() {
        pauseView.alpha = 0
        shipNode.physicsBody?.velocity = lastShipVelocity
        shipNode.physicsBody?.angularVelocity = lastShipAngularVelocity
        for node in gameScene.rootNode.childNodes {
            if node.name == "asteroid" {
                node.physicsBody?.applyForce(SCNVector3(0, 0, 10), asImpulse: true)
            }
        }
        accumulateScore()
        gameState = GameState.playing
    }
    
    @objc func backMenu() {
        self.navigationController?.popViewController(animated: false)
    }
    
    func accumulateScore() {
        // score + 1 every 1 second
        let delay = SCNAction.wait(duration: 1.0)
        let addScore = SCNAction.run ({_ in
            DispatchQueue.main.async {
                self.score = self.score + 1
                self.scoreLabel.text = "\(self.score)"
            }
        })
        gameScene.rootNode.runAction(SCNAction.repeatForever(SCNAction.sequence([delay, addScore])))
    }
    
    func createAsteroid() {
        // create the SCNGeometry
        let asteroidGeometry = SCNCapsule(capRadius: 3, height: 7)
        // create the SCNNode with SCNGeometry
        let asteroidNode = SCNNode(geometry: asteroidGeometry)
        
        //setting the asteroid spawn position
        let randomAsteroidPositionX = Float((drand48()-0.5)*6)
        let randomAsteroidPositionY = Float((drand48()-0.5)*6)
        asteroidNode.position = SCNVector3(x: randomAsteroidPositionX, y: randomAsteroidPositionY, z: -50)
        
        // put the asteroid into the rootNode
        gameScene.rootNode.addChildNode(asteroidNode)
        
        asteroidNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        asteroidNode.physicsBody?.categoryBitMask = CollisionMask.asteroid.rawValue
        asteroidNode.physicsBody?.damping = 0
        asteroidNode.name = "asteroid"
        //apllying forces and torques
        let asteroidInitialForce = SCNVector3(x: 0, y: 0, z: 10)
        asteroidNode.physicsBody?.applyForce(asteroidInitialForce, asImpulse: true)
        let randomAsteroidTorqueX = Float(drand48()-0.5)
        let randomAsteroidTorqueY = Float(drand48()-0.5)
        let randomAsteroidTorqueZ = Float(drand48()-0.5)
        asteroidNode.physicsBody?.applyTorque(SCNVector4(x: randomAsteroidTorqueX, y: randomAsteroidTorqueY, z: randomAsteroidTorqueZ, w: 5), asImpulse: true)
    }
    
    
    // remove the unseeable asteroid behind the camera
    func cleanUp() {
        for node in gameScene.rootNode.childNodes {
            if node.presentation.position.z > 50 {
                node.removeFromParentNode()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == GameState.playing {
            pauseGame()
        }
    }
    
    func pauseGame() {
        gameState = GameState.paused
        gameScene.rootNode.removeAllActions()
        for node in gameScene.rootNode.childNodes {
            if node.name == "asteroid" {
                node.physicsBody?.velocity = SCNVector3(0, 0, 0)
                node.physicsBody?.angularVelocity = SCNVector4(0, 0, 0, 0)
            }
        }
        // stop the ship and asteroids
        lastShipVelocity = shipNode.physicsBody?.velocity
        shipNode.physicsBody?.velocity = SCNVector3(0, 0, 0)
        lastShipAngularVelocity = shipNode.physicsBody?.angularVelocity
        shipNode.physicsBody?.angularVelocity = SCNVector4(0, 0, 0, 0)
        
        UIView.animate(withDuration: 2, animations: {
            self.pauseView.alpha = 0.5
        }, completion: { (complete: Bool) in
            print("complete pause")
        })
    }
    
    func gameOver() {
        gameScene.rootNode.removeAllActions()
        // stop the ship and asteroids
        for node in gameScene.rootNode.childNodes {
            if node.name == "ship" || node.name == "asteroid" {
                node.physicsBody?.velocity = SCNVector3(0, 0, 0)
                node.physicsBody?.angularVelocity = SCNVector4(0, 0, 0, 0)
            }
        }
        DispatchQueue.main.async {
            for subView in self.gameOverView.subviews {
                if subView.restorationIdentifier == "finalScoreLabel" {
                    (subView as! UILabel).text = "SCORE: \(self.score)"
                }
            }
            UIView.animate(withDuration: 2, animations: {
                self.gameOverView.alpha = 0.5
            }, completion: { (complete: Bool) in
                print("complete")
            })
        }
    }
    
    // MARK: SCNSceneRendererDeligate functions
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if time > asteroidCreationTiming && gameState == GameState.playing {
            createAsteroid()
            asteroidCreationTiming = time + 3
            cleanUp()
        }
        if gameState == GameState.dead {
            gameOver()
        }
    }
    
    // MARK: SCNPhysicsContactDelegate functions
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if gameState == GameState.playing {
            gameState = GameState.dead
            print("game over")
        }
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
