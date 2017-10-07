//
//  ViewController.swift
//  OllieOni
//
//  Created by Musashi Sakamoto on 2017/10/07.
//  Copyright © 2017年 Musashi Sakamoto. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  @IBOutlet weak var stateLabel: UILabel!
  var robot: RKConvenienceRobot!
  var ledOn = false

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appWillResignActive(_:)), name: .UIApplicationWillResignActive, object: nil)
    
    RKRobotDiscoveryAgent.shared().addNotificationObserver(self, selector: #selector(ViewController.handleRobotStateChangeNotification(_:)))
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    robot.remove(self)
  }

  func appDidBecomeActive(_ notification: Notification) {
    startDiscovery()
  }
  
  func appWillResignActive(_ notification: Notification) {
    RKRobotDiscoveryAgent.disconnectAll()
    stopDiscovery()
  }
  @IBAction func sleepButtonTapped(_ sender: UIButton) {
    if let robot = self.robot {
      robot.sleep()
    }
  }
  
  func stopDiscovery() {
    RKRobotDiscoveryAgent.stopDiscovery()
  }
  
  func startDiscovery() {
    RKRobotDiscoveryAgent.startDiscovery()
  }
  
  func handleRobotStateChangeNotification(_ notification: RKRobotChangedStateNotification) {
    let noteRobot = notification.robot
    
    switch notification.type {
    case .connecting:
      stateLabel.text = "connecting..."
      break
    case .connected:
      stateLabel.text = "connected..."
      break
    case .online:
      stateLabel.text = "online..."
      let convenienceRobot = RKConvenienceRobot(robot: noteRobot)
      
      if UIApplication.shared.applicationState != .active {
        convenienceRobot?.disconnect()
      } else {
        self.robot = RKConvenienceRobot(robot: noteRobot)
        self.robot.add(self)
        self.robot.enableCollisions(true)
        var mask: RKDataStreamingMask = .accelerometerFilteredAll
        mask = mask.union(.imuAnglesFilteredAll)
        robot.enableSensors(mask, at: .dataStreamingRate10)
        
        toggleLED()
      }
      break
    case .disconnected:
      stateLabel.text = "disconnected"
      startDiscovery()
      robot = nil
      break
    case .failedConnect:
      break
    default:
      print("coudn't connected")
    }
  }
  
  @IBAction func goForward(_ sender: UIButton) {
    robot.drive(withHeading: 0.0, andVelocity: 0.1)
  }
  
  @IBAction func stop(_ sender: UIButton) {
    robot.stop()
  }
  
  @IBAction func goRight(_ sender: UIButton) {
    robot.drive(withHeading: 90, andVelocity: 0.1)
  }
  
  @IBAction func goLeft(_ sender: UIButton) {
    robot.drive(withHeading: 270, andVelocity: 0.1)
  }
  
  @IBAction func goBack(_ sender: UIButton) {
    robot.drive(withHeading: 180, andVelocity: 0.1)
  }

  func toggleLED() {
    if let robot = self.robot {
      if ledOn {
        robot.setLEDWithRed(0.0, green: 0.0, blue: 0.0)
      } else {
        robot.setLEDWithRed(0.0, green: 0.0, blue: 1.0)
      }
      ledOn = !ledOn
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
        self.toggleLED()
      })
    }
  }
}

extension ViewController: RKResponseObserver {
  func handle(_ message: RKAsyncMessage!, forRobot robot: RKRobotBase!) {
    if message is RKCollisionDetectedAsyncData {
      print("collision: \(message)")
    } else if message is RKDeviceSensorsAsyncData {
      let sensorsAsyncData = message as! RKDeviceSensorsAsyncData
      if let sensorsData = sensorsAsyncData.dataFrames.last as? RKDeviceSensorsData {
        print("sensorsData: \(sensorsData)")
      }
    }
  }
}
