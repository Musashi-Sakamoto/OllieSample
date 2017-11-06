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
}
