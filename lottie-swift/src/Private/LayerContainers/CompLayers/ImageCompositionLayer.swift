//
//  ImageCompositionLayer.swift
//  lottie-swift
//
//  Created by Brandon Withrow on 1/25/19.
//

import Foundation
import CoreGraphics
import QuartzCore
import SceneKit

class ImageCompositionLayer: CompositionLayer {
  
    var image: CGImage? = nil {
        didSet {
            DispatchQueue.main.async {
                self.material.diffuse.contents = self.image
            }
        }
    }
  
  let imageReferenceID: String
    let material: SCNMaterial
  
  init(imageLayer: ImageLayerModel, size: CGSize) {
    self.imageReferenceID = imageLayer.referenceID
    material = SCNMaterial()
    material.isDoubleSided = true
    super.init(layer: imageLayer, size: size)
    
    geometry?.materials = [material]
    
//    contentsLayer.masksToBounds = true
//    contentsLayer.contentsGravity = CALayerContentsGravity.resize
  }
  
//  override init(layer: Any) {
//    /// Used for creating shadow model layers. Read More here: https://developer.apple.com/documentation/quartzcore/calayer/1410842-init
//    guard let layer = layer as? ImageCompositionLayer else {
//      fatalError("init(layer:) Wrong Layer Class")
//    }
//    self.imageReferenceID = layer.imageReferenceID
//    self.image = nil
//    super.init(layer: layer)
//  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
