//
//  RenderLayer.swift
//  lottie-swift
//
//  Created by Brandon Withrow on 1/18/19.
//

import Foundation
import QuartzCore
import SceneKit

/**
 The layer responsible for rendering shape objects
 */
class ShapeRenderLayer: ShapeContainerLayer {
  
  fileprivate(set) var renderer: Renderable & NodeOutput
  
  let shapeLayer: SCNShape = SCNShape()
  
  override var renderScale: CGFloat {
    didSet {
      renderLayers.forEach( { $0.renderScale = renderScale } )
//      self.contentsScale = renderScale
    }
  }
  
  init(renderer: Renderable & NodeOutput) {
    self.renderer = renderer
    super.init()
//    self.anchorPoint = .zero
//    self.actions = [
//      "position" : NSNull(),
//      "bounds" : NSNull(),
//      "anchorPoint" : NSNull(),
//      "path" : NSNull(),
//      "transform" : NSNull(),
//      "opacity" : NSNull(),
//      "hidden" : NSNull(),
//    ]
//    shapeLayer.actions = [
//      "position" : NSNull(),
//      "bounds" : NSNull(),
//      "anchorPoint" : NSNull(),
//      "path" : NSNull(),
//      "fillColor" : NSNull(),
//      "strokeColor" : NSNull(),
//      "lineWidth" : NSNull(),
//      "miterLimit" : NSNull(),
//      "lineDashPhase" : NSNull(),
//      "hidden" : NSNull(),
//    ]
//    shapeLayer.contro
//    shapeLayer.extrusionDepth = 1
    geometry = shapeLayer
    
//    let newNode = SCNNode()
//    let geometry = SCNPlane(width: 100, height: 100)
//    let material = SCNMaterial()
//    material.diffuse.contents = NSColor.red
//    geometry.materials = [material]
//    newNode.geometry = geometry
//    addChildNode(newNode)
//    addChildNode(shapeLayer)
//    addSublayer(shapeLayer)
  }
  
//  override init(layer: Any) {
//    guard let layer = layer as? ShapeRenderLayer else {
//      fatalError("init(layer:) wrong class.")
//    }
//    self.renderer = layer.renderer
//    super.init(layer: layer)
//  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func hasRenderUpdate(forFrame: CGFloat) -> Bool {
    self.isHidden = !renderer.isEnabled
    guard self.isHidden == false else { return false }
    return renderer.hasRenderUpdates(forFrame)
  }
  
  override func rebuildContents(forFrame: CGFloat) {
    
//    if renderer.shouldRenderInContext {
//      if let newPath = renderer.outputPath {
//        self.bounds = renderer.renderBoundsFor(newPath.boundingBox)
//      } else {
//        self.bounds = .zero
//      }
//      self.position = bounds.origin
//      self.setNeedsDisplay()
//    } else {
      shapeLayer.path = renderer.outputPath
      renderer.updateShapeLayer(layer: shapeLayer)
//    }
  }
  
//  override func draw(in ctx: CGContext) {
//    if let path = renderer.outputPath {
//      if !path.isEmpty {
//        ctx.addPath(path)
//      }
//    }
//    renderer.render(ctx)
//  }
  
}
