//
//  File.swift
//  RocketX
//
//  Created by Willy on 2018/6/2.
//  Copyright © 2018年 NTUMPP. All rights reserved.
//

import Foundation
import CoreMotion

public class MotionControl {
    
    // MARK: Properties
    var motionManager: CMMotionManager!
    var devicePitchOffset: Double = 0
    var roll: Double = 0
    var pitch: Double = 0
    var yaw: Double = 0
    
    // Initialization
    init() {
        print("init MotionControl")
        motionManager = CMMotionManager()
    }
    
    // Calibrate devicemotion
    func setDevicePitchOffset() {
        while true {
            // Update attitude from motionManager
            motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)
            // Set the offset to current pitch
            guard motionManager.deviceMotion?.attitude.pitch != nil else {continue}
            devicePitchOffset = motionManager.deviceMotion!.attitude.pitch
            print(devicePitchOffset)
            break
        }
    }
    
    // Update device motion value
    func updateDeviceMotionData() {
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)
        guard motionManager.deviceMotion?.attitude != nil else {return}
        roll = (motionManager.deviceMotion?.attitude.roll)!
        pitch = (motionManager.deviceMotion?.attitude.pitch)!
        yaw = (motionManager.deviceMotion?.attitude.yaw)!
        //print(motionManager.deviceMotion?.attitude) // in degree
    }
    
    
    
    
}
