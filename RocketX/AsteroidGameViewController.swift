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
    
    // object of other classes
    var objMotionControl = MotionControl()
    
    var gameScene: SCNScene!
    var cameraNode: SCNNode!
    var shipNode: SCNNode!
    var springNode: SCNNode!
    
    var asteroidCreationTiming: Double = 0
    var gameState: GameState = GameState.paused
    
    let horizontalBound: Float = 4 //was 7
    let upperBound: Float = 6 //was 8
    let lowerBound: Float = -6
    let edgeWidth: Float = 3
    
    
    
    @IBOutlet var gameView: SCNView!
    
    
    
    // MARK:
    override func viewDidLoad() {
        
        
        
        super.viewDidLoad()
        initGameView()
        initScene()
        initCamera()
        initShip()
        
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
        shipNode.physicsBody?.categoryBitMask = CollisionMask.ship.rawValue
        shipNode.physicsBody?.contactTestBitMask = CollisionMask.asteroid.rawValue
        shipNode.name = "ship"
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
    
    
    
    
    
    
    
    
    
    // MARK: SCNSceneRendererDeligate Functions
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        
        
        // following part are controls for the ship, need to able to switch between iphoneX and others
        
        //read device motion (attitude)
        objMotionControl.updateDeviceMotionData()
        
        //set control of the ship
        
        
        var horizontalCentralForce: Float = 0
        var verticalCentralForce: Float = 0
        
        //edge assist
        if shipNode.presentation.position.x > (horizontalBound - edgeWidth) && (shipNode.physicsBody?.velocity.x)! > Float(0) {
            horizontalCentralForce = (shipNode.presentation.position.x - (horizontalBound - edgeWidth)) / edgeWidth * -3
        }
        else if shipNode.presentation.position.x < (-horizontalBound + edgeWidth) && (shipNode.physicsBody?.velocity.x)! < Float(0)  {
            horizontalCentralForce = (shipNode.presentation.position.x - (-horizontalBound + edgeWidth)) / edgeWidth * -3
        }
        else {
            horizontalCentralForce = 0
        }
        if shipNode.presentation.position.y > (upperBound - edgeWidth) && (shipNode.physicsBody?.velocity.y)! > Float(0) {
            verticalCentralForce = (shipNode.presentation.position.y - (upperBound - edgeWidth)) / edgeWidth * -5
        }
        else if shipNode.presentation.position.y < (lowerBound + edgeWidth) && (shipNode.physicsBody?.velocity.y)! < Float(0) {
            verticalCentralForce = (shipNode.presentation.position.y - (lowerBound + edgeWidth)) / edgeWidth * -5
        } else {
            verticalCentralForce = 0
        }
        
        
        
        var shipControlForce = SCNVector3(x: 0, y: 0, z: 0)
        
        // should see if the device is an iPhone X or not
        if UIDevice.modelName == "iPhone X"{
            //face control
            // replace the objMotionControl components (objMotionControl.roll and objMotionControl.pitch) with face orientation in degree, and remove the "objMotionControl.devicePitchOffset"
            shipControlForce = SCNVector3(x: Float(objMotionControl.roll*6.0) + horizontalCentralForce, y: Float(-((objMotionControl.pitch)-objMotionControl.devicePitchOffset)*10.0) + verticalCentralForce, z: 0)
        }
        else {
            //device motion control
            shipControlForce = SCNVector3(x: Float(objMotionControl.roll*6.0) + horizontalCentralForce, y: Float(-((objMotionControl.pitch)-objMotionControl.devicePitchOffset)*10.0) + verticalCentralForce, z: 0)
        }
        
        shipNode.physicsBody?.applyForce(shipControlForce, asImpulse: false)


        //now i just reset the ship after the ship died, should be removed after the interface is set
        if(gameState == GameState.dead) {
            gameState = GameState.playing
            initShip()
        }
        
        //dead if ship is too far away
        
        if abs(shipNode.presentation.position.x) > horizontalBound || shipNode.presentation.position.y > upperBound || shipNode.presentation.position.y < lowerBound {
            shipNode.removeFromParentNode()
            gameState = .dead
        }
    
        
        
        //creating asteroids and cleaning up asteroids
        if time > asteroidCreationTiming {
            createAsteroid()
            asteroidCreationTiming = time + 4
            cleanUp()
        }
    }
    
    
    
    
    // MARK: SCNPhysicsContactDelegate Functions
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        gameScene.rootNode.childNode(withName: "ship", recursively: false)?.removeFromParentNode()
        gameState = GameState.dead
        print(gameState)
    }
    
    
    
    
    
    
    
    // MARK: ViewController Settings
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
