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
import ARKit

// setting the collision mask
enum CollisionMask: Int {
    case ship = 1
    case asteroid = 2
}

enum GameState: Int {
    case playing
    case dead
    case paused
    case blocked
}


class AsteroidGameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate, ARSCNViewDelegate {

    
    // MARK: Properties
    
    var objMotionControl = MotionControl()
    
    var backgroundMusic: AVAudioPlayer!
    
    var isIphoneX: Bool = false
    
    var gameScene: SCNScene!
    var cameraNode: SCNNode!
    var shipNode: SCNNode!
    var springNode: SCNNode!
    var faceNode: SCNNode!
    var gameOverView: UIView!
    var pauseView: UIView!
    
    var score: Int = 0
    var scoreLabel: UILabel!
    
    var startAsteroidCreation: Bool = false
    var asteroidCreationTiming: Double = 0
    
    // Used for increasing the difficulty as the score arises
    let asteroidCreationTimeSpace = [4.0, 3.0, 2.0, 1.0]
    
    // Used for skip the gameOver animate after flash animate
    var isCollision: Bool = false
    
    let horizontalBound: Float = 5
    let upperBound: Float = 7
    let lowerBound: Float = -8
    let edgeWidth: Float = 3
    
    // Used for returning to game
    var lastShipVelocity: SCNVector3!
    var lastShipAngularVelocity: SCNVector4!
    
    // Input thresholds and ceilings (change values below, ceilings are chosen in degrees of rotation)
    var inputThresh: Float = 0
    var yPosCeil: Float = 0
    var yNegCeil: Float = 0
    var xPosCeil: Float = 0
    var xNegCeil: Float = 0
    
    var gameState: GameState = GameState.paused
    
    @IBOutlet var gameView: SCNView!
    @IBOutlet weak var arView: ARSCNView!
    
    // MARK:
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        initGameView()
        initARView()
        initScene()
        initCamera()
        initShip()
        initScore()
        initPauseView()
        initGameOverView()
        initMusicPlayer()
        
        if UIDevice.modelName == "iPhone X" {
            isIphoneX = true
            inputThresh = 0.1 // Normalized value
            yPosCeil = .pi/180 * 20 // Radians
            yNegCeil = .pi/180 * -20 //Around y axis (yaw)
            xPosCeil = .pi/180 * 20 //Around x axis (pitch)
            xNegCeil = .pi/180 * -15
        }
        else {
            inputThresh = 0.3 // Normalized value
            yPosCeil = .pi/180 * 60 // Radians
            yNegCeil = .pi/180 * -60 //Around y axis (yaw)
            xPosCeil = .pi/180 * 60 //Around x axis (pitch)
            xNegCeil = .pi/180 * -60
        }
        
        gameState = .playing
        
        objMotionControl.setDevicePitchOffset()
        accumulateScore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        guard ARFaceTrackingConfiguration.isSupported else { return }
        
        let configuration = ARFaceTrackingConfiguration()
        
        configuration.isLightEstimationEnabled = true
        configuration.worldAlignment = .camera
        
        // Run the view's session
        arView.session.run(configuration)
        gameScene.isPaused = false
        
        self.arView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        
        backgroundMusic.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        arView.session.pause()
        gameScene.isPaused = true
        backgroundMusic.stop()
    }
    
    
    // MARK: functions
    
    func initGameView() {
        gameView.allowsCameraControl = false
        gameView.autoenablesDefaultLighting = true
        gameView.delegate = self
    }
    
    func initARView() {
        arView.delegate = self
    }
    
    func initScene() {
        gameScene = SCNScene()
        gameView.scene = gameScene
        gameView.scene?.physicsWorld.gravity = SCNVector3(x: 0, y: 0, z: 0)
        gameView.scene?.physicsWorld.speed = 1
        gameScene.background.contents = UIImage(named: "background.jpg")
        gameScene.physicsWorld.contactDelegate = self
        
    }
    
    func initCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        let cameraAngle: Float = 20
        let cameraDistance: Float = 10
        cameraNode.eulerAngles = SCNVector3(x: -.pi*cameraAngle/180, y: 0, z: 0)
        cameraNode.position = SCNVector3(x: 0, y: tan(.pi*cameraAngle/180)*cameraDistance + 1, z: cameraDistance)
        gameScene.rootNode.addChildNode(cameraNode)
    }
    
    
    func initShip() {
        // Set the ship
        let shipScene = SCNScene(named: "art.scnassets/retrorockett4k1t.dae")
        shipNode = shipScene?.rootNode.childNodes.first
        shipNode.position = SCNVector3(x: 0, y: 0, z: 0)
        shipNode.scale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
        shipNode.eulerAngles = SCNVector3(x: -(Float.pi/2), y: 0, z: 0)
        
        // Setting the physicsbody of the ship
        shipNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        shipNode.physicsBody?.damping = 0.4
        shipNode.physicsBody?.angularDamping = 0.9
        shipNode.physicsBody?.categoryBitMask = CollisionMask.ship.rawValue
        shipNode.physicsBody?.contactTestBitMask = CollisionMask.asteroid.rawValue
        shipNode.name = "rocket"
        
        let jet = SCNParticleSystem(named: "Jet", inDirectory: nil)
        let jetNode = SCNNode()
        jetNode.position = SCNVector3(x: 0, y: -4, z: 0)
        jetNode.addParticleSystem(jet!)
        shipNode.addChildNode(jetNode)

//        shipNode.addParticleSystem(jet!)
        
        gameScene.rootNode.addChildNode(shipNode)
        
        // print("init ship")
    }
    
    func initScore() {
        scoreLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
        scoreLabel.center = CGPoint(x: self.view.bounds.minX+40, y: self.view.bounds.minY+40)
        scoreLabel.text = "\(self.score)"
        scoreLabel.font = UIFont.boldSystemFont(ofSize: 26)
        scoreLabel.textAlignment = .center
        scoreLabel.textColor = UIColor.lightGray
        self.view.addSubview(scoreLabel)
    }
    
    func initPauseView() {
        // the background rectangle
        pauseView = UIView(frame: CGRect(x: 0, y: 0, width: gameView.bounds.width*2, height: gameView.bounds.height*2))
        pauseView.backgroundColor = UIColor.black
        pauseView.clipsToBounds = true
        pauseView.center = CGPoint(x: gameView.bounds.midX, y: gameView.bounds.midY)
        pauseView.alpha = 0
        gameView.addSubview(pauseView)
        
        // Add transparent gradient
        /*
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0.0)
        gradient.endPoint = CGPoint(x: 0, y:0.17)
        let whiteColor = UIColor.white
        gradient.colors = [whiteColor.withAlphaComponent(0.0).cgColor, whiteColor.withAlphaComponent(1.0), whiteColor.withAlphaComponent(1.0).cgColor]
        gradient.locations = [NSNumber(value: 0.0), NSNumber(value: 0.5), NSNumber(value: 1.0)]
        gradient.frame = pauseView.bounds
        pauseView.layer.mask = gradient
        */
        
        let pauseLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        pauseLabel.center = CGPoint(x: pauseView.bounds.midX, y: pauseView.bounds.midY-100)
        pauseLabel.text = "PAUSED"
        pauseLabel.font = UIFont.boldSystemFont(ofSize: 26)
        pauseLabel.textAlignment = .center
        
        // Same as the title in the entry view
        pauseLabel.textColor = UIColor(red: 93/255, green: 188/255, blue: 210/255, alpha: 1)
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
        // The background rectangle
        gameOverView = UIView(frame: CGRect(x: 0, y: 0, width: gameView.bounds.width*2, height: gameView.bounds.height*2))
        gameOverView.backgroundColor = UIColor.black
        gameOverView.clipsToBounds = true
        gameOverView.center = CGPoint(x: gameView.bounds.midX, y: gameView.bounds.midY)
        gameOverView.alpha = 0
        gameView.addSubview(gameOverView)
        
        let gameOverLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        gameOverLabel.center = CGPoint(x: gameOverView.bounds.midX, y: gameOverView.bounds.midY-100)
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.font = UIFont.boldSystemFont(ofSize: 26)
        gameOverLabel.textAlignment = .center
        
        // Same as the title in the entry view
        gameOverLabel.textColor = UIColor(red: 93/255, green: 188/255, blue: 210/255, alpha: 1)
        gameOverView.addSubview(gameOverLabel)
        
        let finalScoreLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        finalScoreLabel.center = CGPoint(x: gameOverView.bounds.midX, y: gameOverView.bounds.midY-60)
        finalScoreLabel.text = "Score:"
        finalScoreLabel.font = UIFont.boldSystemFont(ofSize: 26)
        finalScoreLabel.textAlignment = .center
        
        // Same as the title in the entry view
        finalScoreLabel.textColor = UIColor(red: 93/255, green: 188/255, blue: 210/255, alpha: 1)
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
    
    func initMusicPlayer() {
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "game", ofType: "mp3")! )
        do {
            backgroundMusic = try AVAudioPlayer(contentsOf: url)
            backgroundMusic.numberOfLoops = -1
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    @objc func restartGame() {
        for node in gameScene.rootNode.childNodes {
            if node.name == "rocket" || node.name == "asteroid" {
                node.removeFromParentNode()
            }
        }
        pauseView.alpha = 0
        gameOverView.alpha = 0
        score = 0
        accumulateScore()
        startAsteroidCreation = false
        initShip()
        self.gameView.play(self)
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
        self.gameView.play(self)
        gameState = GameState.playing
    }
    
    @objc func backMenu() {
        self.dismiss(animated: false, completion: nil)
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
    
    func flashAnimate() {
        // Simple animate after collision
        let circleRadius = gameView.bounds.width * 0.05 / 2.0
        let flashView = UIView(frame: CGRect(x: 0, y: 0, width: circleRadius * 2, height: circleRadius * 2))
        flashView.backgroundColor = UIColor.white
        flashView.alpha = 1
        flashView.layer.cornerRadius = circleRadius
        let positionOnScreen = gameView.projectPoint(shipNode.presentation.position)
        flashView.center = CGPoint(x: Double(positionOnScreen.x), y: Double(positionOnScreen.y))
        self.view.addSubview(flashView)
        UIView.animate(withDuration: 0.6, animations: {
            flashView.alpha = 0.2
            flashView.transform = CGAffineTransform(scaleX: 70.0, y: 70.0)
            flashView.center = CGPoint(x: Double(positionOnScreen.x), y: Double(positionOnScreen.y))
        }, completion: { (complete: Bool) in
            flashView.removeFromSuperview()
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == GameState.playing {
            gameState = GameState.paused
            pauseGame()
        }
    }
    
    func pauseGame() {
        // Prevent from keep calling this func in touchesBegan()
        gameState = GameState.blocked
        gameScene.rootNode.removeAllActions()
        for node in gameScene.rootNode.childNodes {
            if node.name == "asteroid" {
                node.physicsBody?.velocity = SCNVector3(0, 0, 0)
                node.physicsBody?.angularVelocity = SCNVector4(0, 0, 0, 0)
            }
        }
        // Stop the ship and asteroids
        lastShipVelocity = shipNode.physicsBody?.velocity
        shipNode.physicsBody?.velocity = SCNVector3(0, 0, 0)
        lastShipAngularVelocity = shipNode.physicsBody?.angularVelocity
        shipNode.physicsBody?.angularVelocity = SCNVector4(0, 0, 0, 0)
        
        // Show the pause view
        UIView.animate(withDuration: 1.2, animations: {
            self.pauseView.alpha = 0.8
        }, completion: { (complete: Bool) in
            self.gameView.pause(self)
            print("complete pause")
        })
    }
    
    func gameOver() {
        // Prevent from keep calling this func in render()
        gameState = GameState.blocked
        
        // Stop accumulate score
        gameScene.rootNode.removeAllActions()
        
        // Stop the ship and asteroids
        for node in gameScene.rootNode.childNodes {
            if node.name == "rocket" || node.name == "asteroid" {
                node.physicsBody?.velocity = SCNVector3(0, 0, 0)
                node.physicsBody?.angularVelocity = SCNVector4(0, 0, 0, 0)
            }
        }
        
        var scoreArray = UserDefaults.standard.object(forKey: "scoreArray") as? [Int] ?? [Int]()
        
        if scoreArray.count < 20 { scoreArray.append(score) }
        else if (scoreArray.min()!) < score {
            scoreArray.append(score)
            scoreArray.sort{ $0 > $1 }
            scoreArray.removeLast()
        }
        UserDefaults.standard.set(scoreArray, forKey: "scoreArray")
        
        // Show the game over view
        DispatchQueue.main.async {
            for subView in self.gameOverView.subviews {
                if subView.restorationIdentifier == "finalScoreLabel" {
                    (subView as! UILabel).text = "Score: \(self.score)"
                }
            }
            if self.isCollision == true {
                self.gameOverView.alpha = 0.8
                self.gameView.pause(self)
                print("complete game over view")
            } else {
                UIView.animate(withDuration: 1.2, animations: {
                    self.gameOverView.alpha = 0.8
                }, completion: { (complete: Bool) in
                    self.gameView.pause(self)
                    print("complete game over view")
                })
            }
        }
    }
    
    func createAsteroid() {
        // Create the SCNGeometry
        let asteroidGeometry = SCNCapsule(capRadius: 2.5, height: 6)
        // Create the SCNNode with SCNGeometry
        let asteroidNode = SCNNode(geometry: asteroidGeometry)
        asteroidNode.opacity = 0.0;
        
        // Setting the asteroid spawn position
        let asteroidSpawnRange = 10.0
        let randomAsteroidPositionX = Float((drand48()-0.5)*asteroidSpawnRange)
        let randomAsteroidPositionY = Float((drand48()-0.5)*asteroidSpawnRange)
        asteroidNode.position = SCNVector3(x: randomAsteroidPositionX, y: randomAsteroidPositionY, z: -50)
        
        asteroidNode.geometry?.firstMaterial?.diffuse.contents  = UIImage(named: "asteroid")
        
        // Set the physicbody and put the asteroid into the rootNode
        asteroidNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        asteroidNode.physicsBody?.categoryBitMask = CollisionMask.asteroid.rawValue
        asteroidNode.physicsBody?.damping = 0
        asteroidNode.name = "asteroid"
        gameScene.rootNode.addChildNode(asteroidNode)
        
        // Apllying forces and torques
        let asteroidInitialForce = SCNVector3(x: 0, y: 0, z: 10)
        asteroidNode.physicsBody?.applyForce(asteroidInitialForce, asImpulse: true)
        let randomAsteroidTorqueX = Float(drand48()-0.5)
        let randomAsteroidTorqueY = Float(drand48()-0.5)
        let randomAsteroidTorqueZ = Float(drand48()-0.5)
        asteroidNode.physicsBody?.applyTorque(SCNVector4(x: randomAsteroidTorqueX, y: randomAsteroidTorqueY, z: randomAsteroidTorqueZ, w: 5), asImpulse: true)

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.5
        asteroidNode.opacity = 1.0
        SCNTransaction.commit()

    }
    
    
    // Remove the unseeable asteroid behind the camera
    func cleanUpAsteroids() {
        for node in gameScene.rootNode.childNodes {
            if node.presentation.position.z > 10 && node.name == "asteroid"{
                node.removeFromParentNode()
            }
            // Reduce opacity of asteroids that have been dodged and are obstructing the view
            if node.presentation.position.z > 0 && node.name == "asteroid" {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1
                node.opacity = 0.0
                SCNTransaction.commit()
            }
        }
    }
    
    // MARK: SCNPhysicsContactDelegate Functions
    // Function that handles collision between rocket and asteroids
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if gameState == GameState.playing {
            DispatchQueue.main.async {
                self.isCollision = true
                self.flashAnimate()
                self.gameState = GameState.dead
                self.isCollision = false
                print("collision")
            }
        }
    }
    
    //Input standardizer: This function takes the pitch (euler x) and yaw (euler y), applies threshold and ceiling, and normalizes it.
    func inputNormalizer (pitch: Float, yaw: Float) -> (pitchNorm: Float, yawNorm: Float) {
        var tempPitch = pitch
        var tempYaw = -yaw

        // Apply the ceiling
        if tempPitch > xPosCeil { tempPitch = xPosCeil
        } else if tempPitch < xNegCeil { tempPitch = xNegCeil
        } else {
        }
        if tempYaw > yPosCeil { tempYaw = yPosCeil
        } else if tempYaw < yNegCeil { tempYaw = yNegCeil
        } else {
        }
        
        // Convert to range 0 to 1
        let yOldRange:Float = ( yPosCeil - yNegCeil)
        let yNewRange:Float = (1 - -1)
        tempPitch = (((tempPitch - yNegCeil) * yNewRange) / yOldRange) + -1
        let xOldRange:Float = ( xPosCeil - xNegCeil)
        let xNewRange:Float = (1 - -1)
        tempYaw = (((tempYaw - xNegCeil) * xNewRange) / xOldRange) + -1
        //print("Pitch, yaw is \(tempPitch) and \(tempYaw)")
        
        // Apply threshold
        if abs(tempPitch) < inputThresh {
            tempPitch = 0
        }
        if abs(tempYaw) < inputThresh {
            tempYaw = 0
        }

        return (tempPitch, tempYaw)
    }
    
    // MARK: SCNSceneRendererDeligate functions
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        // Get input from face for rocket
        faceNode = node
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        if gameState == GameState.blocked {
            return
        }
        
        // Dead if ship is too far away
        if abs(shipNode.presentation.position.x) > horizontalBound || shipNode.presentation.position.y > upperBound || shipNode.presentation.position.y < lowerBound {
            gameState = .dead
        }
        
        if gameState == GameState.dead {
            gameOver()
        }
        
        // Cleaning up asteroids
        cleanUpAsteroids()

        // Creating asteroids
        if time > asteroidCreationTiming && gameState == GameState.playing {
            if startAsteroidCreation == true {
                createAsteroid()
                let timeSpaceIndex = score < 80 ? score/20 : 3
                asteroidCreationTiming = time + asteroidCreationTimeSpace[timeSpaceIndex]
            } else {
                asteroidCreationTiming = time + 3
                startAsteroidCreation = true
            }
        }
        
        // Set control of the ship
        var horizontalCentralForce: Float = 0
        var verticalCentralForce: Float = 0
        
        // Edge assist
        if shipNode.presentation.position.x > (horizontalBound - edgeWidth) && (shipNode.physicsBody?.velocity.x)! > Float(0) {
            horizontalCentralForce = (shipNode.presentation.position.x - (horizontalBound - edgeWidth)) / edgeWidth * -6
        }
        else if shipNode.presentation.position.x < (-horizontalBound + edgeWidth) && (shipNode.physicsBody?.velocity.x)! < Float(0)  {
            horizontalCentralForce = (shipNode.presentation.position.x - (-horizontalBound + edgeWidth)) / edgeWidth * -6
        }
        else {
            horizontalCentralForce = 0
        }
        if shipNode.presentation.position.y > (upperBound - edgeWidth) && (shipNode.physicsBody?.velocity.y)! > Float(0) {
            verticalCentralForce = (shipNode.presentation.position.y - (upperBound - edgeWidth)) / edgeWidth * -10
        }
        else if shipNode.presentation.position.y < (lowerBound + edgeWidth) && (shipNode.physicsBody?.velocity.y)! < Float(0) {
            verticalCentralForce = (shipNode.presentation.position.y - (lowerBound + edgeWidth)) / edgeWidth * -10
        } else {
            verticalCentralForce = 0
        }
        
        
        // Calculate the force that currently should affect the rocket
        var shipControlForce = SCNVector3(x: 0, y: 0, z: 0)
        
//        print("the facenode is \(faceNode)")
        // Control by face if the device is an iPhone X or control by device motion
        if isIphoneX == true {
            // Face control
            if faceNode != nil {
                let (yTemp, xTemp) = inputNormalizer(pitch: faceNode.eulerAngles.y, yaw: faceNode.eulerAngles.x)
                shipControlForce = SCNVector3(
                    // EulerAngles contains three elements: pitch, yaw and roll, in radians
                    x: Float(yTemp*3), //+ horizontalCentralForce,
                    y: Float(xTemp*3), //+ verticalCentralForce,
                    z: 0)
            } else {
                shipControlForce = SCNVector3(x: Float(0), y:Float(0), z: Float(0))
            }
        } else {
            // Read device motion (attitude)
            objMotionControl.updateDeviceMotionData()
            // Device motion control
            shipControlForce = SCNVector3(
                x: Float(objMotionControl.roll*6.0) + horizontalCentralForce,
                y: Float(-((objMotionControl.pitch)-objMotionControl.devicePitchOffset)*10.0) + verticalCentralForce,
                z: 0)
//            print(objMotionControl.devicePitchOffset)
        }
        
        // Apply the force to the rocket itself
        shipNode.physicsBody?.applyForce(shipControlForce, at: SCNVector3(x: 0, y: 0, z: -1.5), asImpulse: false)
        let shipBow = shipNode.presentation.convertVector(SCNVector3(x: 0, y: 5, z: 0), to: nil)
        let shipStern = shipNode.presentation.convertVector(SCNVector3(x: 0, y: -5, z: 0), to: nil)
        shipNode.physicsBody?.applyForce(SCNVector3(x: 0, y: 0, z: -18), at: shipBow, asImpulse: false)
        shipNode.physicsBody?.applyForce(SCNVector3(x: 0, y: 0, z: 18), at: shipStern, asImpulse: false)
//        print(shipNode.presentation.rotation)
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
