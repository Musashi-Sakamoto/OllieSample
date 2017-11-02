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
  @IBOutlet weak var highlightView: UIView? {
    didSet {
      self.highlightView?.layer.borderColor = UIColor.white.cgColor
      self.highlightView?.layer.borderWidth = 2
    }
  }
  var visionSequenceHandler = VNSequenceRequestHandler()
  var lastObservation: VNDetectedObjectObservation?
  
  @IBOutlet weak var joystick: JoyStickView!
  var pumpkinNode: SCNNode?

  override func viewDidLoad() {
    super.viewDidLoad()
    highlightView?.frame = .zero
    
    sceneView.delegate = self
    sceneView.session.delegate = self
    sceneView.scene = SCNScene()
    
    pumpkinNode = SCNScene(named: "art.scnassets/Halloween_Pumpkin.dae")!.rootNode.childNode(withName: "pumpkin", recursively: true)
    
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
      self.hitNode(at: self.highlightView!.center, name: "pumpkin")
    }
  }
  
  func hitNode(at point: CGPoint, name: String, onSuccess: (() -> Void)? = nil) {
    guard let result = sceneView.hitTest(point).first else { return }
    let node = result.node
    if node.name == name {
      let soundNode = SCNNode()
      let source = SCNAudioSource(named: "hitBug.wav")!
      let action = SCNAction.playAudio(source, waitForCompletion: false)
      soundNode.runAction(action)
      sceneView.scene.rootNode.addChildNode(soundNode)
      let particleSystem = SCNParticleSystem(named: "Explosion", inDirectory: nil)!
      let systemNode = SCNNode()
      systemNode.addParticleSystem(particleSystem)
      systemNode.position = node.position
      sceneView.scene.rootNode.addChildNode(systemNode)
      node.removeFromParentNode()
      onSuccess?()
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
            node?.addChildNode(pumpkin!)
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
