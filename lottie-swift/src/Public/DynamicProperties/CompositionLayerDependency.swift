//
//  CompositionLayerDependecy.swift
//  Lottie_iOS
//
//  Created by Volodimir Moskaliuk on 10/23/19.
//  Copyright © 2019 YurtvilleProds. All rights reserved.
//

import SceneKit

public protocol CompositionLayerDependency {
  func layerUpdated(layer: SCNNode)
  func layerAnimationRemoved(layer: SCNNode)
}
