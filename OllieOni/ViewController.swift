//
//  ViewController.swift
//  OllieOni
//
//  Created by Musashi Sakamoto on 2017/10/07.
//  Copyright © 2017年 Musashi Sakamoto. All rights reserved.
//

import UIKit
import ARKit
import Vision

class ViewController: UIViewController {
    
  @IBOutlet weak var stateLabel: UILabel!
  var robot: RKConvenienceRobot!
  var ledOn = false
  @IBOutlet weak var sceneView: ARSCNView!
  @IBOutlet weak var highlightView: UIView?
  var visionSequenceHandler = VNSequenceRequestHandler()
  var lastObservation: VNDetectedObjectObservation?
  var charizardPosition: SCNVector3?
  
  @IBOutlet weak var joystick: JoyStickView!
  var pumpkinNode: VirtualObject?
  var charizardNode: VirtualObject?

  override func viewDidLoad() {
    super.viewDidLoad()
    highlightView?.frame = .zero
    
    sceneView.delegate = self
    sceneView.session.delegate = self
    sceneView.scene = SCNScene()
    
    pumpkinNode = VirtualObject(name: "Halloween_Pumpkin.dae")
    pumpkinNode?.loadModel()
    charizardNode = VirtualObject(name: "Charizard.dae")
    charizardNode?.loadModel()
    print("charizard: \(charizardNode?.isPlaced)")
    
    setUpJoyStick()
    sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.userTapped(with:))))
    
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appWillResignActive(_:)), name: .UIApplicationWillResignActive, object: nil)
    
    RKRobotDiscoveryAgent.shared().addNotificationObserver(self, selector: #selector(ViewController.handleRobotStateChangeNotification(_:)))
  }
  
  @objc func userTapped(with gestureRecognizer: UITapGestureRecognizer) {
    highlightView?.frame.size = CGSize(width: 100, height: 100)
    highlightView?.center = gestureRecognizer.location(in: self.view)
    
    let originalRect = self.highlightView?.frame ?? .zero
    
    let t = CGAffineTransform(scaleX: 1.0 / self.view.frame.size.width, y: 1.0 / self.view.frame.size.height)
    let normalizedHighlightImageBoundingBox = originalRect.applying(t)
    
    guard let fromViewToCameraImageTransform = self.sceneView.session.currentFrame?.displayTransform(for: .portrait, viewportSize: self.sceneView.frame.size).inverted() else { return }
    var trackImageBoundingBoxInImage = normalizedHighlightImageBoundingBox.applying(fromViewToCameraImageTransform)
    trackImageBoundingBoxInImage.origin.y = 1 - trackImageBoundingBoxInImage.origin.y
    let newObservation = VNDetectedObjectObservation(boundingBox: trackImageBoundingBoxInImage)
    self.lastObservation = newObservation
  }
  
  func handleVisionRequestUpdate(_ request: VNRequest, error: Error?) {
    DispatchQueue.main.async {
      guard let newObservation = request.results?.first as? VNDetectedObjectObservation else {
        self.visionSequenceHandler = VNSequenceRequestHandler()
        return
      }
      
      self.lastObservation = newObservation
      guard newObservation.confidence >= 0.3 else {
        self.highlightView?.frame = .zero
        return
      }
      
      var transformedRect = newObservation.boundingBox
      transformedRect.origin.y = 1 - transformedRect.origin.y
      
      guard let fromCameraImageToViewTransform = self.sceneView.session.currentFrame?.displayTransform(for: .portrait, viewportSize: self.sceneView.frame.size) else { return }
      let normalizedHighlightImageBoundingBox = transformedRect.applying(fromCameraImageToViewTransform)
      let t = CGAffineTransform(scaleX: self.view.frame.size.width, y: self.view.frame.size.height)
      let unnormalizedTrackImageBoundingBox = normalizedHighlightImageBoundingBox.applying(t)
      
      self.highlightView?.frame = unnormalizedTrackImageBoundingBox
      self.hitNode(at: self.highlightView!.center, name: "pumpkin") {
        let charizard = self.charizardNode?.clone()
        guard let result = self.sceneView.hitTest(self.highlightView!.center, types: [.estimatedHorizontalPlane]).first else { return }
        charizard?.position = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
        self.sceneView.scene.rootNode.addChildNode(charizard!)
        Utility.playSound(scene: self.sceneView, name: "BR_Charizard.wav")
        Utility.showParticle(scene: self.sceneView, name: "Fire", position: charizard!.position)
      }
    }
  }
  
  func hitNode(at point: CGPoint, name: String, onSuccess: () -> Void) {
    guard let result = sceneView.hitTest(point).first else { return }
    let node = result.node
    if node.name == name {
      Utility.playSound(scene: sceneView, name: "hitBug.wav")
      Utility.showParticle(scene: sceneView, name: "Explosion", position: node.position)
      node.removeFromParentNode()
      onSuccess()
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    sceneView.session.run(configuration)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sceneView.session.pause()
  }
  
  func setUpJoyStick() {
    joystick.movable = false
    joystick.alpha = 1.0
    joystick.baseAlpha = 0.5
    joystick.handleTintColor = UIColor.darkGray
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
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        var node: SCNNode?
        if let planeAnchor = anchor as? ARPlaneAnchor {
            node = SCNNode()
            let pumpkin = pumpkinNode?.clone()
            pumpkin?.position = SCNVector3Make(planeAnchor.center.x, 0.1, planeAnchor.center.z)
            charizardPosition = pumpkin?.position
            node?.addChildNode(pumpkin!)
            let move1 = SCNAction.moveBy(x: 0.5, y: 0, z: 0, duration: 1)
            let scale1 = SCNAction.scale(by: 3.0, duration: 1)
            let group1 = SCNAction.group([move1, scale1])
            let move2 = SCNAction.moveBy(x: -0.5, y: 0, z: 0, duration: 1)
            let scale2 = SCNAction.scale(by: 1.0 / 3.0, duration: 1)
            let group2 = SCNAction.group([move2, scale2])
            let move3 = SCNAction.moveBy(x: 0, y: 0, z: 0.5, duration: 1)
            let scale3 = SCNAction.scale(by: 3.0, duration: 1)
            let group3 = SCNAction.group([move3, scale3])
            let move4 = SCNAction.moveBy(x: 0, y: 0, z: -0.5, duration: 1)
            let scale4 = SCNAction.scale(by: 1.0 / 3.0, duration: 1)
            let group4 = SCNAction.group([move4, scale4])
            let sequence = SCNAction.sequence([group1, group2, group3, group4])
            Utility.repeatAction(node: node!, action: sequence)
        } else {
            print("not plane anchor \(anchor)")
        }
        return node
    }
}

extension ViewController: ARSessionDelegate {
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    guard let pixelBuffer: CVPixelBuffer = session.currentFrame?.capturedImage,
    let lastObservation = lastObservation else {
      self.visionSequenceHandler = VNSequenceRequestHandler()
      return
    }
    
    let request = VNTrackObjectRequest(detectedObjectObservation: lastObservation, completionHandler: self.handleVisionRequestUpdate)
    request.trackingLevel = .fast
    
    do {
      try self.visionSequenceHandler.perform([request], on: pixelBuffer)
    } catch {
      print("Throws: \(error)")
    }
  }
}
