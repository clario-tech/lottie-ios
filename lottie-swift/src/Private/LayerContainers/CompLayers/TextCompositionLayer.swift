//
//  TextCompositionLayer.swift
//  lottie-swift
//
//  Created by Brandon Withrow on 1/25/19.
//

import Foundation
import CoreGraphics
import QuartzCore
import CoreText

#if os(macOS)
import Cocoa
import AppKit
#else
import Foundation
import UIKit
#endif

class DisabledTextLayer: CATextLayer {
  override func action(forKey event: String) -> CAAction? {
    return nil
  }
#if os(OSX)
    override func draw(in ctx: CGContext) {
        NSGraphicsContext.saveGraphicsState()
        if #available(OSX 10.10, *) {
            NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
        }
        (string as? NSAttributedString)?.draw(in: bounds)
        NSGraphicsContext.restoreGraphicsState()
    }
#endif
}

extension TextJustification {
  var textAlignment: NSTextAlignment {
    switch self {
    case .left:
      return .left
    case .right:
      return .right
    case .center:
      return .center
    }
  }
  
  var caTextAlignement: CATextLayerAlignmentMode {
    switch self {
    case .left:
      return .left
    case .right:
      return .right
    case .center:
      return .center
    }
  }
  
}

class TextCompositionLayer: CompositionLayer {
  
  let rootNode: TextAnimatorNode?
  let textDocument: KeyframeInterpolator<TextDocument>?
  let interpolatableAnchorPoint: KeyframeInterpolator<Vector3D>?
  let interpolatableScale: KeyframeInterpolator<Vector3D>?
  
  let fonts : FontList?
  let textLayer: CATextLayer
  let textStrokeLayer: CATextLayer
  var textProvider: AnimationTextProvider {
    didSet {
        guard let lastUpdatedFrame = textDocument?.lastUpdatedFrame else { return }
        displayContentsWithFrame(frame: lastUpdatedFrame, forceUpdates: true)
    }
  }
    
    override var renderScale: CGFloat {
        didSet {
            textLayer.contentsScale = self.renderScale
            textStrokeLayer.contentsScale = self.renderScale
        }
    }
  
  init(textLayer: TextLayerModel, textProvider: AnimationTextProvider, fonts: FontList?) {
    var rootNode: TextAnimatorNode?
    for animator in textLayer.animators {
      rootNode = TextAnimatorNode(parentNode: rootNode, textAnimator: animator)
    }
    self.rootNode = rootNode
    self.textDocument = KeyframeInterpolator(keyframes: textLayer.text.keyframes)
    
    self.textProvider = textProvider
    
    // TODO: this has to be somewhere that can be interpolated
    // TODO: look for inspiration from other composite layer
    self.interpolatableAnchorPoint = KeyframeInterpolator(keyframes: textLayer.transform.anchorPoint.keyframes)
    self.interpolatableScale = KeyframeInterpolator(keyframes: textLayer.transform.scale.keyframes)
    
    self.fonts = fonts
    if (textLayer.effects?.first { $0.name == "Evolution_(%)_In" }) != nil {
        self.textLayer = WordAnimatedTextLayer(textLayer.parent != nil, basedOn: textLayer.animators.first?.selector?.basedOn)
        self.textStrokeLayer = WordAnimatedTextLayer(textLayer.parent != nil, basedOn: textLayer.animators.first?.selector?.basedOn)
    } else {
        self.textLayer = DisabledTextLayer()
        self.textStrokeLayer = DisabledTextLayer()
    }
    
    super.init(layer: textLayer, size: .zero)
    
    contentsLayer.addSublayer(self.textLayer)
    contentsLayer.addSublayer(self.textStrokeLayer)
    self.textLayer.masksToBounds = false
    self.textStrokeLayer.masksToBounds = false
    self.textLayer.isWrapped = true
    self.textStrokeLayer.isWrapped = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override init(layer: Any) {
    /// Used for creating shadow model layers. Read More here: https://developer.apple.com/documentation/quartzcore/calayer/1410842-init
    guard let layer = layer as? TextCompositionLayer else {
      fatalError("init(layer:) Wrong Layer Class")
    }
    self.rootNode = nil
    self.textDocument = nil
    
    self.textProvider = DefaultTextProvider()
    
    self.interpolatableAnchorPoint = nil
    self.interpolatableScale = nil
    
    self.textLayer = DisabledTextLayer()
    self.textStrokeLayer = DisabledTextLayer()
    
	self.fonts = nil
    super.init(layer: layer)
  }
  
  override func displayContentsWithFrame(frame: CGFloat, forceUpdates: Bool) {
    guard let textDocument = textDocument else { return }
    
    textLayer.contentsScale = self.renderScale
    textStrokeLayer.contentsScale = self.renderScale
    
    let documentUpdate = textDocument.hasUpdate(frame: frame)
    let animatorUpdate = rootNode?.updateContents(frame, forceLocalUpdate: forceUpdates) ?? false
    guard documentUpdate == true || animatorUpdate == true else { return }
    
    let text = textDocument.value(frame: frame) as! TextDocument
    let anchorPoint = interpolatableAnchorPoint?.value(frame: frame) as! Vector3D
    let scale = interpolatableScale?.value(frame: frame) as! Vector3D
    rootNode?.rebuildOutputs(frame: frame)
    
    let fillColor = rootNode?.textOutputNode.fillColor ?? text.fillColorData.cgColorValue
    let strokeColor = rootNode?.textOutputNode.strokeColor ?? text.strokeColorData?.cgColorValue
#if os(OSX)
    let nsFillColor = NSColor(cgColor: fillColor)
    var nsStrokeColor: NSColor? = nil
    if let strokeColor = strokeColor {
        nsStrokeColor = NSColor(cgColor: strokeColor)
    }
#endif
    
    let strokeWidth = rootNode?.textOutputNode.strokeWidth ?? CGFloat(text.strokeWidth ?? 0)
    let tracking = (CGFloat(text.fontSize) * (rootNode?.textOutputNode.tracking ?? CGFloat(text.tracking))) / 1000.0
//    TODO: Investigate what is wrong with transform matrix
//    let matrix = rootNode?.textOutputNode.xform ?? CATransform3DIdentity
    let ctFont = CTFontCreateWithName(text.fontFamily as CFString, CGFloat(text.fontSize), nil)
    
    let textString = textProvider.textFor(keypathName: self.keypathName, sourceText: text.text)

#if os(macOS)
	var nsFont : NSFont?
	fonts?.fonts.forEach({ (font) in
		if (font.name == text.fontFamily) {
			if (font.style == "UltraLight") {
				nsFont = NSFont().systemUIFontUltraLight(size: CGFloat(text.fontSize))
			}
			else if (font.style == "Thin") {
				nsFont = NSFont().systemUIFontThin(size: CGFloat(text.fontSize))
			}
			else if (font.style == "Light") {
				nsFont = NSFont().systemUIFontLight(size: CGFloat(text.fontSize))
			}
			else if (font.style == "Regular") {
				nsFont = NSFont().systemUIFontRegular(size: CGFloat(text.fontSize))
			}
			else if (font.style == "Medium") {
				nsFont = NSFont().systemUIFontMedium(size: CGFloat(text.fontSize))
			}
 		}
	})
    
    let resultFont = nsFont ?? CTFontCreateWithName(text.fontFamily as CFString, CGFloat(text.fontSize), nil) as NSFont
#else
    var uiFont : UIFont?
    fonts?.fonts.forEach({ (font) in
        if (font.name == text.fontFamily) {
            if (font.style == "UltraLight") {
                uiFont = UIFont.systemFont(ofSize: CGFloat(text.fontSize), weight: .ultraLight)
            }
            else if (font.style == "Thin") {
                uiFont = UIFont.systemFont(ofSize: CGFloat(text.fontSize), weight: .thin)
            }
            else if (font.style == "Light") {
                uiFont = UIFont.systemFont(ofSize: CGFloat(text.fontSize), weight: .light)
            }
            else if (font.style == "Regular") {
                uiFont = UIFont.systemFont(ofSize: CGFloat(text.fontSize), weight: .regular)
            }
            else if (font.style == "Medium") {
                uiFont = UIFont.systemFont(ofSize: CGFloat(text.fontSize), weight: .medium)
            }
        }
    })
    
    let resultFont = uiFont ?? CTFontCreateWithName(text.fontFamily as CFString, CGFloat(text.fontSize), nil) as UIFont
#endif
	
	var attributes: [NSAttributedString.Key : Any] = [
      .font: resultFont,
      .kern: tracking,
    ]
    
#if os(OSX)
    attributes[.foregroundColor] = nsFillColor
#else
    attributes[.foregroundColor] = fillColor
#endif
    
    let baselinePosition = CTFontGetAscent(ctFont)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = CGFloat(text.fontSize / text.lineHeight) * 6
    paragraphStyle.alignment = text.justification?.textAlignment ?? NSTextAlignment.left
    attributes[.paragraphStyle] = paragraphStyle
    
    let baseAttributedString = NSAttributedString(string: textString, attributes: attributes)
    
    if let strokeColor = strokeColor {
      textStrokeLayer.isHidden = false
#if os(OSX)
      attributes[.strokeColor] = nsStrokeColor
#else
      attributes[.strokeColor] = strokeColor
#endif
      attributes[.strokeWidth] = strokeWidth
    } else {
      textStrokeLayer.isHidden = true
    }
    
    let strokeAttributedString: NSAttributedString = NSAttributedString(string: textString, attributes: attributes)
    let size: CGSize
    
    if let frameSize = text.textFrameSize {
      size = CGSize(width: frameSize.x, height: frameSize.y)
    } else {
      let framesetter = CTFramesetterCreateWithAttributedString(baseAttributedString)
      
      size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,
                                                          CFRange(location: 0,length: 0),
                                                          nil,
                                                          CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                                 height: CGFloat.greatestFiniteMagnitude),
                                                          nil)
    }
    
    var textAnchor: CGPoint
    switch text.justification {
    case .left, .none:
      textAnchor = CGPoint(x: 0, y: baselinePosition)
    case .right:
      textAnchor = CGPoint(x: size.width, y: baselinePosition)
    case .center:
      textAnchor = CGPoint(x: size.width * 0.5, y: baselinePosition)
    }
    textAnchor.y += CGFloat(text.baseline ?? 0.0)
    let anchor = textAnchor + anchorPoint.pointValue
    let normalizedAnchor = CGPoint(x: anchor.x.remap(fromLow: 0, fromHigh: size.width, toLow: 0, toHigh: 1),
                                   y: anchor.y.remap(fromLow: 0, fromHigh: size.height, toLow: 0, toHigh: 1))
    
    func setupLayer(layer: CATextLayer) {
        layer.anchorPoint = normalizedAnchor
        layer.opacity = Float(rootNode?.textOutputNode.opacity ?? 1)
        layer.transform = CATransform3DIdentity
        layer.fontSize = CGFloat(text.fontSize)
        layer.font = resultFont
        layer.foregroundColor = fillColor
        if let position = text.textFramePosition?.pointValue {
            layer.frame = CGRect(origin: position, size: size)
            layer.position.y -= CGFloat(text.fontSize * 0.2)
        } else {
            layer.frame = CGRect(origin: CGPoint(x: -textAnchor.x, y: -CGFloat(text.fontSize)), size: size)
        }
        if let wordLayer = layer as? WordAnimatedTextLayer {
            if wordLayer.shifted {
                wordLayer.frame.origin.y += wordLayer.fontSize
                wordLayer.frame.size.height += wordLayer.fontSize
            } else {
                wordLayer.frame.origin.y += wordLayer.fontSize / 5.0
            }
            
        }
        
        //    TODO: Investigate what is wrong with transform matrix
        //    textLayer.transform = matrix
        
        layer.alignmentMode = text.justification?.caTextAlignement ?? CATextLayerAlignmentMode.left
    }
    
    if textStrokeLayer.isHidden == false {
      if text.strokeOverFill ?? false {
        textStrokeLayer.removeFromSuperlayer()
        contentsLayer.addSublayer(textStrokeLayer)
      } else {
        textLayer.removeFromSuperlayer()
        contentsLayer.addSublayer(textLayer)
      }
      setupLayer(layer: textStrokeLayer)
      textStrokeLayer.string = strokeAttributedString
    }
    
    setupLayer(layer: textLayer)
    textLayer.string = baseAttributedString
  }
}


#if os(macOS)

extension NSFont {
	
	func systemUIFontUltraLight(size: CGFloat) -> NSFont {
		var resultFont : NSFont
		if #available(OSX 10.11, *) {
			resultFont = NSFont.systemFont(ofSize: size, weight: NSFont.Weight.ultraLight)
		}
		else if (floor(NSFoundationVersionNumber) <= floor(NSFoundationVersionNumber10_10)) {
			resultFont = CTFontCreateWithName("HelveticaNeue-UltraLight" as CFString, size, nil)
		}
		else {
			resultFont = systemUIFont(size: size, weightDelta: -3)
		}
		return resultFont
	}
	
	func systemUIFontThin(size: CGFloat) -> NSFont {
		var resultFont : NSFont
		if #available(OSX 10.11, *) {
			resultFont = NSFont.systemFont(ofSize: size, weight: NSFont.Weight.thin)
		}
		else if (floor(NSFoundationVersionNumber) <= floor(NSFoundationVersionNumber10_10)) {
			resultFont = CTFontCreateWithName("HelveticaNeue-Thin" as CFString, size, nil)
		}
		else {
			resultFont = systemUIFont(size: size, weightDelta: -2)
		}
		return resultFont
	}
	
	func systemUIFontLight(size: CGFloat) -> NSFont {
		var resultFont : NSFont
		if #available(OSX 10.11, *) {
			resultFont = NSFont.systemFont(ofSize: size, weight: NSFont.Weight.light)
		}
		else if (floor(NSFoundationVersionNumber) <= floor(NSFoundationVersionNumber10_10)) {
			resultFont = CTFontCreateWithName("HelveticaNeue-Light" as CFString, size, nil)
		}
		else {
			resultFont = systemUIFont(size: size, weightDelta: -1)
		}
		return resultFont
	}
	
	func systemUIFontRegular(size: CGFloat) -> NSFont {
		var resultFont : NSFont
		if #available(OSX 10.11, *) {
			resultFont = NSFont.systemFont(ofSize: size, weight: NSFont.Weight.regular)
		}
		else if (floor(NSFoundationVersionNumber) <= floor(NSFoundationVersionNumber10_10)) {
			resultFont = CTFontCreateWithName("HelveticaNeue" as CFString, size, nil)
		}
		else {
			resultFont = systemUIFont(size: size, weightDelta: 0)
		}
		return resultFont
	}
	
	func systemUIFontMedium(size: CGFloat) -> NSFont {
		var resultFont : NSFont
		if #available(OSX 10.11, *) {
			resultFont = NSFont.systemFont(ofSize: size, weight: NSFont.Weight.medium)
		}
		else if (floor(NSFoundationVersionNumber) <= floor(NSFoundationVersionNumber10_10)) {
			resultFont = CTFontCreateWithName("HelveticaNeue-Medium" as CFString, size, nil)
		}
		else {
			resultFont = systemUIFont(size: size, weightDelta: 1)
		}
		return resultFont
	}
	
	func systemUIFont(size: CGFloat, weightDelta: Int) -> NSFont {
		var result = NSFont.systemFont(ofSize: size)
		let sharedFontManager = NSFontManager.shared
		var delta = weightDelta
		while (delta < 0) {
			delta += 1
			result = sharedFontManager.convertWeight(false, of: result)
		}
		while (delta > 0)
		{
			delta -= 1;
			result = sharedFontManager.convertWeight(true, of: result)
		}
		return result
	}
}

#endif
