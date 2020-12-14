//
//  TransformNodeOutput.swift
//  lottie-swift
//
//  Created by Brandon Withrow on 1/30/19.
//

import Foundation
import CoreGraphics
import QuartzCore
import SceneKit

class GroupOutputNode: NodeOutput {
  
  init(parent: NodeOutput?, rootNode: NodeOutput?) {
    self.parent = parent
    self.rootNode = rootNode
  }
  
  let parent: NodeOutput?
  let rootNode: NodeOutput?
  var isEnabled: Bool = true
  
  private(set) var outputPath: NSBezierPath? = nil
  private(set) var transform: CATransform3D = CATransform3DIdentity
  
  func setTransform(_ xform: CATransform3D, forFrame: CGFloat) {
    transform = xform
    outputPath = nil
  }

  func hasOutputUpdates(_ forFrame: CGFloat) -> Bool {
    guard isEnabled else {
      let upstreamUpdates = parent?.hasOutputUpdates(forFrame) ?? false
      outputPath = parent?.outputPath
      return upstreamUpdates
    }
    
    let upstreamUpdates = parent?.hasOutputUpdates(forFrame) ?? false
    if upstreamUpdates {
      outputPath = nil
    }
    let rootUpdates = rootNode?.hasOutputUpdates(forFrame) ?? false
    if rootUpdates {
      outputPath = nil
    }
    
    var localUpdates: Bool = false
    if outputPath == nil {
      localUpdates = true
      
        let newPath = NSBezierPath()
      if let parentNode = parent, let parentPath = parentNode.outputPath {
        /// First add parent path.
        newPath.append(parentPath)
//        newPath.addPath(parentPath)
      }
      var xform = CATransform3DGetAffineTransform(transform)
      if let rootNode = rootNode,
        let rootPath = rootNode.outputPath {
//        ,
//        let xformedPath = rootPath.copy(using: &xform)
        let affine = AffineTransform(m11: xform.a, m12: xform.b, m21: xform.c, m22: xform.d, tX: xform.tx, tY: xform.ty)
        rootPath.transform(using: affine)
        /// Now add root path. Note root path is transformed.
        newPath.append(rootPath)
//        newPath.addPath(rootPath)
      }
      
      outputPath = newPath
    }
    
    return upstreamUpdates || localUpdates
  }
  
}
