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
}


class AsteroidGameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate, ARSCNViewDelegate {

    
    // MARK: Properties
    
    // object of other classes
    var objMotionControl = MotionControl()
    var isIphoneX: Bool = false
    
    var gameScene: SCNScene!
    var cameraNode: SCNNode!
    var shipNode: SCNNode!
    var springNode: SCNNode!
    var faceNode: SCNNode!
    
    var startAsteroidCreation: Bool = false
    var asteroidCreationTiming: Double = 4
    var gameState: GameState = GameState.paused
    
    let horizontalBound: Float = 6 //was 7
    let upperBound: Float = 8 //was 8
    let lowerBound: Float = -8
    let edgeWidth: Float = 3
    
    //Input thresholds and ceilings (change values below, ceilings are chosen in degrees of rotation)
    var inputThresh: Float = 0
    var yPosCeil: Float = 0
    var yNegCeil: Float = 0
    var xPosCeil: Float = 0
    var xNegCeil: Float = 0
    
    
    
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
        
        if UIDevice.modelName == "iPhone X" {
            isIphoneX = true
            inputThresh = 0.2 // Normalized value
            yPosCeil = .pi/180 * 45 // Radians
            yNegCeil = .pi/180 * 45
            xPosCeil = .pi/180 * 45
            xNegCeil = .pi/180 * 45
        }
        else {
            inputThresh = 0.3 // Normalized value
            yPosCeil = .pi/180 * 60 // Radians
            yNegCeil = .pi/180 * 60
            xPosCeil = .pi/180 * 60
            xNegCeil = .pi/180 * 60
        }
        
        gameState = .playing
        
        objMotionControl.setDevicePitchOffset()
        
    }
    
    
    
    
    // MARK: functions
    
    func initGameView() {
        //gameView = self.view as! SCNView
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
        gameScene.background.contents = UIColor.darkGray
        gameScene.physicsWorld.contactDelegate = self
        
    }
    
    func initCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        let cameraAngle: Float = 20
        let cameraDistance: Float = 10
        cameraNode.eulerAngles = SCNVector3(x: -.pi*cameraAngle/180, y: 0, z: 0)
        cameraNode.position = SCNVector3(x: 0, y: tan(.pi*cameraAngle/180)*cameraDistance + 1, z: cameraDistance)
        //cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        gameScene.rootNode.addChildNode(cameraNode)
    }
    
    func initShip() {
        //set the ship
        let shipScene = SCNScene(named: "art.scnassets/retrorockett4k1t.dae")
        shipNode = shipScene?.rootNode
        shipNode.position = SCNVector3(x: 0, y: 0, z: 0)
        shipNode.scale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
        shipNode.eulerAngles = SCNVector3(x: -(Float.pi/2), y: 0, z: 0)
        // setting the physicsbody of the ship
        shipNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        shipNode.physicsBody?.damping = 0.05
        shipNode.physicsBody?.angularDamping = 0.9
        shipNode.physicsBody?.categoryBitMask = CollisionMask.ship.rawValue
        shipNode.physicsBody?.contactTestBitMask = CollisionMask.asteroid.rawValue
        shipNode.name = "rocket"
        gameScene.rootNode.addChildNode(shipNode)
        
        
        
        //for debugging below
        print(gameState)
    }
    
    
    
    
    func createAsteroid() {
        // create the SCNGeometry
        let asteroidGeometry = SCNCapsule(capRadius: 2.5, height: 6)
        // create the SCNNode with SCNGeometry
        let asteroidNode = SCNNode(geometry: asteroidGeometry)
        
        //setting the asteroid spawn position
        let asteroidSpawnRange = 10.0
        let randomAsteroidPositionX = Float((drand48()-0.5)*asteroidSpawnRange)
        let randomAsteroidPositionY = Float((drand48()-0.5)*asteroidSpawnRange)
        asteroidNode.position = SCNVector3(x: randomAsteroidPositionX, y: randomAsteroidPositionY, z: -50)
        
        // put the asteroid into the rootNode
        asteroidNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        asteroidNode.physicsBody?.categoryBitMask = CollisionMask.asteroid.rawValue
        asteroidNode.physicsBody?.damping = 0
        gameScene.rootNode.addChildNode(asteroidNode)
        
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
    
    // MARK: SCNPhysicsContactDelegate Functions
    //Function that handles collision between rocket and asteroids
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        gameState = GameState.dead
        print(gameState)
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        arView.session.pause()
        gameScene.isPaused = true
    }
    
    //Input standardizer: This function takes the pitch (y) and yaw (x), applies threshold and ceiling, and normalizes it.
    func inputNormalizer (pitch: Float, yaw: Float) -> (pitchNorm: Float, yawNorm: Float) {
        var tempPitch = pitch
        var tempYaw = yaw
        //Apply the ceiling
        if pitch > yPosCeil { tempPitch = yPosCeil
        } else if pitch < yNegCeil { tempPitch = yNegCeil
        } else { tempPitch = pitch
        }
        if yaw > xPosCeil { tempYaw = xPosCeil
        } else if yaw < xNegCeil { tempYaw = xNegCeil
        } else { tempYaw = yaw
        }
        //Convert to range 0 to 1
        let yOldRange:Float = ( yPosCeil - yNegCeil)
        let yNewRange:Float = (1 - -1)
        tempPitch = (((tempPitch - yNegCeil) * yNewRange) / yOldRange) + -1
        let xOldRange:Float = ( xPosCeil - xNegCeil)
        let xNewRange:Float = (1 - -1)
        tempYaw = (((tempYaw - xNegCeil) * xNewRange) / xOldRange) + -1
        //Apply threshold
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
        //Get input from face for rocket
        faceNode = node
        //gameView.scene?.rootNode.childNode(withName: "rocket", recursively: true)?.transform = node.transform

    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // following part are controls for the ship, need to able to switch between iphoneX and others
        
        //set control of the ship
        var horizontalCentralForce: Float = 0
        var verticalCentralForce: Float = 0
        
        //edge assist
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
        
        
        //Calculate the force that currently should affect the rocket
        var shipControlForce = SCNVector3(x: 0, y: 0, z: 0)
        
//        print("the facenode is \(faceNode)")

        
        // should see if the device is an iPhone X or not
        if isIphoneX == true {
            //face control
            if faceNode != nil {
                let (yTemp, xTemp) = inputNormalizer(pitch: faceNode.eulerAngles.y, yaw: faceNode.eulerAngles.x)
                shipControlForce = SCNVector3(
                //eulerAngles contains three elements: pitch, yaw and roll, in radians
                x: Float(yTemp*60) + horizontalCentralForce,
                y: Float(xTemp*100) + verticalCentralForce,
                z: 0)
            } else {
            shipControlForce = SCNVector3(x: Float(0), y:Float(0), z: Float(0))
            }
        }else {
            //read device motion (attitude)
            objMotionControl.updateDeviceMotionData()
            //device motion control
            shipControlForce = SCNVector3(
                x: Float(objMotionControl.roll*6.0) + horizontalCentralForce,
                y: Float(((objMotionControl.pitch)-objMotionControl.devicePitchOffset)*10.0) + verticalCentralForce,
                z: 0)
//            print(objMotionControl.devicePitchOffset)
        }
        
        //Apply the force to the rocket itself
//        shipNode.physicsBody?.applyForce(shipControlForce, asImpulse: false)
       
        shipNode.physicsBody?.applyForce(shipControlForce, at: SCNVector3(x: 0, y: 0, z: -1.5), asImpulse: false)
        let shipBow = shipNode.presentation.convertVector(SCNVector3(x: 0, y: 5, z: 0), to: nil)
        let shipStern = shipNode.presentation.convertVector(SCNVector3(x: 0, y: -5, z: 0), to: nil)
        shipNode.physicsBody?.applyForce(SCNVector3(x: 0, y: 0, z: -18), at: shipBow, asImpulse: false)
        shipNode.physicsBody?.applyForce(SCNVector3(x: 0, y: 0, z: 18), at: shipStern, asImpulse: false)
//        print(shipNode.presentation.rotation)


        //reset the ship after the ship died, should be removed after the interface is set
        if(gameState == GameState.dead) {
            for node in gameScene.rootNode.childNodes {
                node.removeFromParentNode()
                startAsteroidCreation = false
            }
            initShip()
            gameState = GameState.playing
        }
        
        //dead if ship is too far away
        if abs(shipNode.presentation.position.x) > horizontalBound || shipNode.presentation.position.y > upperBound || shipNode.presentation.position.y < lowerBound {
            gameState = .dead
        }
    
        //creating asteroids and cleaning up asteroids
        if time > asteroidCreationTiming {
            if startAsteroidCreation == true {
                createAsteroid()
                asteroidCreationTiming = time + 4
                cleanUp()
            } else {
                asteroidCreationTiming = time + 3
                startAsteroidCreation = true
            }
        }
    }
    
    
    
    
//    // MARK: SCNPhysicsContactDelegate Functions
//    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
////        gameScene.rootNode.childNode(withName: "ship", recursively: false)?.removeFromParentNode()
//        gameState = GameState.dead
//        print(gameState)
//    }
    
    
    
    
    
    
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
