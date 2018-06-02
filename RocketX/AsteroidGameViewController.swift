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
    
    var asteroidCreationTiming: Double = 0
    var gameState: GameState!
    
    
    
    
    
    @IBOutlet var gameView: SCNView!
    
    
    
    // MARK:
    override func viewDidLoad() {
        
        
        
        super.viewDidLoad()
        initGameView()
        initScene()
        initCamera()
        initShip()
        
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
        cameraNode.eulerAngles = SCNVector3(x: -.pi*cameraAngle/180, y: 0, z: 0)
        cameraNode.position = SCNVector3(x: 0, y: tan(.pi*cameraAngle/180)*10, z: 10)
        //cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        gameScene.rootNode.addChildNode(cameraNode)
    }
    
    func initShip() {
        let shipScene = SCNScene(named: "art.scnassets/retrorockett4k1t.dae")
        shipNode = shipScene?.rootNode
        shipNode.position = SCNVector3(x: 0, y: 0, z: 0)
        shipNode.scale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
        shipNode.eulerAngles = SCNVector3(x: -(Float.pi/2), y: 0, z: 0)
        // setting the physicsbody of the ship
        shipNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        shipNode.physicsBody?.damping = 0.2
        shipNode.physicsBody?.categoryBitMask = CollisionMask.ship.rawValue
        shipNode.physicsBody?.contactTestBitMask = CollisionMask.asteroid.rawValue
        shipNode.name = "ship"
        gameScene.rootNode.addChildNode(shipNode)
        gameState = GameState.playing
        
        //for debugging below
        print(gameState)
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
    
    
    
    
    
    
    
    
    
    // MARK: SCNSceneRendererDeligate functions
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        //
        devicePitchOffset = objMotionControl.devicePitchOffset
        
        //read device motion (attitude)
        objMotionControl.updateDeviceMotionData()
        
        //set control of the ship
        shipNode.physicsBody?.applyForce(SCNVector3(x: Float(objMotionControl.roll*3.0), y: Float(-((objMotionControl.pitch)-objMotionControl.devicePitchOffset)*3.0), z: 0), asImpulse: false)


        if(gameState == GameState.dead) {
            gameState = GameState.playing
            initShip()
        }
        
        //creating asteroids and cleaning up asteroids
        if time > asteroidCreationTiming {
            createAsteroid()
            asteroidCreationTiming = time + 4
            cleanUp()
        }
    }
    
    
    // MARK: SCNPhysicsContactDelegate functions
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        gameScene.rootNode.childNode(withName: "ship", recursively: false)?.removeFromParentNode()
        gameState = GameState.dead
        print(gameState)
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
