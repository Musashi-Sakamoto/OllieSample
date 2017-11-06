//
//  VirtualObject.swift
//  OllieOni
//
//  Created by 坂元 武佐志 on 2017/11/06.
//  Copyright © 2017年 Musashi Sakamoto. All rights reserved.
//

import UIKit
import ARKit

class VirtualObject: SCNNode {
    
    var objectName: String!
    var isPlaced: Bool = false
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(name objectName: String) {
        super.init()
        self.objectName = objectName
    }
    
    func loadModel() {
        guard let virtualObject = SCNScene(named: objectName, inDirectory: "art.scnassets", options: nil) else { return }
        let wrapperNode = SCNNode()
        for child in virtualObject.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .phong
            wrapperNode.addChildNode(child)
        }
        self.addChildNode(wrapperNode)
        isPlaced = true
    }
}
