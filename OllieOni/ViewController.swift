//
//  ViewController.swift
//  OllieOni
//
//  Created by Musashi Sakamoto on 2017/10/07.
//  Copyright © 2017年 Musashi Sakamoto. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {
  
  private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  @IBOutlet weak var movingStateLabel: UILabel!
  private var recognitionTask: SFSpeechRecognitionTask?
  private let audioEngine = AVAudioEngine()
  @IBOutlet weak var recordButton: UIButton!
  
  @IBOutlet weak var stateLabel: UILabel!
  var robot: RKConvenienceRobot!
  var ledOn = false
  var motionManager = CMMotionManager()

  override func viewDidLoad() {
    super.viewDidLoad()
    recordButton.isEnabled = false
    // Do any additional setup after loading the view, typically from a nib.
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appWillResignActive(_:)), name: .UIApplicationWillResignActive, object: nil)
    
    RKRobotDiscoveryAgent.shared().addNotificationObserver(self, selector: #selector(ViewController.handleRobotStateChangeNotification(_:)))
  }
  
  private func startRecording() throws {
    if let recognitionTask = recognitionTask {
      recognitionTask.cancel()
      self.recognitionTask = nil
    }
    
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(AVAudioSessionCategoryRecord)
    try audioSession.setMode(AVAudioSessionModeMeasurement)
    try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
    
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    
    guard let inputNode = audioEngine.inputNode else { return }
    
    guard let recognitionRequest = recognitionRequest else { return }
    
    recognitionRequest.shouldReportPartialResults = true
    
    recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: {[weak self] (result, error) in
      guard let `self` = self else { return }
      var isFinal = false
      print(result)
      if let result = result {
        let resultString = result.bestTranscription.formattedString
        print("result: \(resultString)")
        self.stateLabel.text = resultString
        self.judgeResultAndDrive(resultString)
        isFinal = result.isFinal
      }
      
      if error != nil || isFinal {
        self.audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        
        self.recognitionRequest = nil
        self.recognitionTask = nil
        self.recordButton.isEnabled = true
      }
    })
    
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, time) in
      self.recognitionRequest?.append(buffer)
    }
    
    
    audioEngine.prepare()
    try audioEngine.start()
  }
  
  func judgeResultAndDrive(_ string: String) {
    switch string {
    case "右":
      robot.drive(withHeading: 90.0, andVelocity: 0.2)
      break
    case "左":
      robot.drive(withHeading: 270.0, andVelocity: 0.2)
      break
    case "前":
      robot.drive(withHeading: 0.0, andVelocity: 0.2)
      break
    case "後":
      robot.drive(withHeading: 180.0, andVelocity: 0.2)
      break
    default:
      print("コマンド失敗")
    }
    toggleLED()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    speechRecognizer.delegate = self
    
    SFSpeechRecognizer.requestAuthorization { authStatus in
      OperationQueue.main.addOperation {
        switch authStatus {
        case .authorized:
          self.recordButton.isEnabled = true
        default:
          self.recordButton.isEnabled = false
        }
      }
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
  
  @IBAction func recordButtonTapped(_ sender: UIButton) {
    if audioEngine.isRunning {
      print("stop")
      movingStateLabel.text = "stopped"
      audioEngine.stop()
      recognitionRequest?.endAudio()
      recordButton.isEnabled = false
    } else {
      robot.stop()
      print("start")
      movingStateLabel.text = "started"
      toggleLED()
      try! startRecording()
    }
  }
  
}

extension ViewController: SFSpeechRecognizerDelegate {
  func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
    if available {
      recordButton.isEnabled = true
    } else {
      recordButton.isEnabled = false
    }
  }
}
