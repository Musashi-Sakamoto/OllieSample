//
//  Utility.swift
//  OllieOni
//
//  Created by Musashi Sakamoto on 2017/11/05.
//  Copyright © 2017年 Musashi Sakamoto. All rights reserved.
//

import Foundation
import ARKit

class Utility {
  
  static func repeatAction(node: SCNNode, action: SCNAction) {
    let loopAction = SCNAction.repeatForever(action)
    node.runAction(loopAction)
  }
  
  static func playSound(scene: SCNView, name: String) {
    let soundNode = SCNNode()
    let source = SCNAudioSource(named: name)!
    let action = SCNAction.playAudio(source, waitForCompletion: false)
    soundNode.runAction(action)
    scene.scene?.rootNode.addChildNode(soundNode)
  }
  
  static func showParticle(scene: SCNView, name: String, position: SCNVector3) {
    let particleSystem = SCNParticleSystem(named: name, inDirectory: nil)!
    let systemNode = SCNNode()
    systemNode.addParticleSystem(particleSystem)
    systemNode.position = position
    scene.scene?.rootNode.addChildNode(systemNode)
  }
}
