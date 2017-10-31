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
    
    lazy var joystick: JoyStickView = {
        let joystick = JoyStickView(frame: CGRect(origin: self.view.center, size: CGSize(width: 100, height: 100)))
        self.view.addSubview(joystick)
        joystick.movable = false
        joystick.alpha = 1.0
        joystick.baseAlpha = 0.5
        joystick.handleTintColor = UIColor.darkGray
        return joystick
    }()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appWillResignActive(_:)), name: .UIApplicationWillResignActive, object: nil)
    
    RKRobotDiscoveryAgent.shared().addNotificationObserver(self, selector: #selector(ViewController.handleRobotStateChangeNotification(_:)))
    joystick.monitor = { [weak self] angle, displacement in
        let velocity = displacement * 0.2
        guard let robot = self?.robot else { return }
        robot.drive(withHeading: Float(angle), andVelocity: Float(velocity))
    }
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
  
  @IBAction func stop(_ sender: UIButton) {
    robot.stop()
  }

  func toggleLED() {
    if let robot = self.robot {
      if ledOn {
        robot.setLEDWithRed(0.0, green: 0.0, blue: 0.0)
      } else {
        let red = arc4random_uniform(255)
        let green = arc4random_uniform(255)
        let blue = arc4random_uniform(255)
        robot.setLEDWithRed(Float(red) / 255.0, green: Float(green) / 255.0, blue: Float(blue) / 255.0)
      }
      ledOn = !ledOn
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
        self.toggleLED()
      })
    }
  }
}
