//
//  ImageView.swift
//  TestGame
//
//  Created by Isaac Paul on 9/28/22.
//

import Foundation
import SDL2

public enum ContentMode : Int, Codable {
    case stretch
    case aspectFit
    case aspectFill
    case center
    case top
    case right
    case bottom
    case left
    case topRight
    case topLeft
    case bottomRight
    case bottomLeft
}
public class ImageView : View {
    
    public var image:AtlasImage? = nil
    private var _imageSrc:String? = nil //Temporary.. We're going to need to tie image to a file anyways for hotreloading
    public var tint:LabeledColor = LabeledColor.white
    public var contentMode:ContentMode = ContentMode.right
    public var isOpaque:Bool = false //Treats all images as opaque if on
    
    required public override init() {
        super.init()
    }
    
    public init(image:AtlasImage?) {
        self.image = image
        super.init()
    }
    
    private enum CodingKeys: String, CodingKey {
        case image
        case tint
        case contentMode
        case isOpaque
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder, clipBoundsDefault: true)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if
            let imageManager = decoder.userInfo[CodingUserInfoKey(rawValue: "imageManager")!] as? SimpleImageManager,
            let imageName = try container.decodeIfPresent(String.self, forKey: .image) {
            self._imageSrc = imageName
            if let url = URL(string: imageName) {
                self.image = imageManager.image(url)
            } else {
                //TODO: Test; we can have vd:/path or /path or imageName.jpeg or imageName
                self.image = imageManager.image(named: imageName)
            }
        }
        
        self.tint = try container.decodeDynamicItemIfPresent(LabeledColor.self, forKey: .tint) ?? LabeledColor.idk
        self.isOpaque = try container.decodeIfPresent(Bool.self, forKey: .isOpaque) ?? false
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let imageSrc = _imageSrc {
            try container.encode(imageSrc, forKey: .image)
        }
        if (tint !== LabeledColor.idk) {
            try container.encode(tint, forKey: .tint)
        }
        if (isOpaque != false) {
            try container.encode(isOpaque, forKey: .isOpaque)
        }
    }
    
    open override func drawContent(_ context: UIRenderContext, _ rect: Rect<DValue>) throws {
        
        if let image = image {
            let destFrame:Rect<DValue>
            switch contentMode {
                case .stretch:
                    destFrame = rect
                case .aspectFit:
                    let imgSize = image.subTextureIndex.sourceRect.size
                    let imgSize16 = Size<DValue>(Int16(imgSize.width), Int16(imgSize.height))
                    let newSize = imgSize16.aspectFitInto(frame.size)
                    var newFrame = Rect(origin: Point.zero, size: newSize)
                    newFrame.center = rect.center
                    destFrame = newFrame
                case .aspectFill:
                    let imgSize = image.subTextureIndex.sourceRect.size
                    let imgSize16 = Size<DValue>(Int16(imgSize.width), Int16(imgSize.height))
                    let newSize = imgSize16.aspectFillInto(frame.size)
                    var newFrame = Rect(origin: Point.zero, size: newSize)
                    newFrame.center = rect.center
                    destFrame = newFrame
                case .center:
                    var nativeFrame = image.subTextureIndex.sourceRect.to(DValue.self)
                    nativeFrame.center = rect.center
                    destFrame = nativeFrame
                    //Added these because they're in UIKit, but I don't think anyone uses them?
                case .top:
                    var nativeFrame = image.subTextureIndex.sourceRect.to(DValue.self)
                    nativeFrame.centerX = rect.centerX
                    nativeFrame.y = rect.y
                    destFrame = nativeFrame
                case .right:
                    var nativeFrame = image.subTextureIndex.sourceRect.to(DValue.self)
                    nativeFrame.centerY = rect.centerY
                    nativeFrame.rightFixed = rect.right
                    destFrame = nativeFrame
                case .bottom:
                    var nativeFrame = image.subTextureIndex.sourceRect.to(DValue.self)
                    nativeFrame.centerX = rect.centerX
                    nativeFrame.bottomFixed = rect.bottom
                    destFrame = nativeFrame
                case .left:
                    var nativeFrame = image.subTextureIndex.sourceRect.to(DValue.self)
                    nativeFrame.centerY = rect.centerY
                    nativeFrame.x = rect.x
                    destFrame = nativeFrame
                case .topRight:
                    var nativeFrame = image.subTextureIndex.sourceRect.to(DValue.self)
                    nativeFrame.y = rect.y
                    nativeFrame.rightFixed = rect.right
                    destFrame = nativeFrame
                case .topLeft:
                    var nativeFrame = image.subTextureIndex.sourceRect.to(DValue.self)
                    nativeFrame.origin = rect.origin
                    destFrame = nativeFrame
                case .bottomRight:
                    var nativeFrame = image.subTextureIndex.sourceRect.to(DValue.self)
                    nativeFrame.bottomFixed = rect.bottom
                    nativeFrame.rightFixed = rect.right
                    destFrame = nativeFrame
                case .bottomLeft:
                    var nativeFrame = image.subTextureIndex.sourceRect.to(DValue.self)
                    nativeFrame.bottomFixed = rect.bottom
                    nativeFrame.x = rect.x
                    destFrame = nativeFrame
            }
            do {
                //try context.drawSquare(frame, LabeledColor.blue)
                try context.drawImage(image, destFrame, tint.sdlColor())
            } catch {
                print("Error drawing image: \(error.localizedDescription)")
            }
        }
    }
}
