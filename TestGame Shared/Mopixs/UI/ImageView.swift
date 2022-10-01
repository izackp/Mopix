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
    
    public var image:Image? = nil
    private var _imageSrc:String? = nil //Temporary.. We're going to need to tie image to a file anyways for hotreloading
    public var tint:SmartColor = SmartColor.idk
    public var contentMode:ContentMode = ContentMode.aspectFit
    public var isOpaque:Bool = false //Treats all images as opaque if on
    
    required public override init() {
        super.init()
    }
    
    public init(image:Image?) {
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
        
        self.tint = try container.decodeDynamicItemIfPresent(SmartColor.self, forKey: .tint) ?? SmartColor.idk
        self.isOpaque = try container.decodeIfPresent(Bool.self, forKey: .isOpaque) ?? false
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let imageSrc = _imageSrc {
            try container.encode(imageSrc, forKey: .image)
        }
        if (tint !== SmartColor.idk) {
            try container.encode(tint, forKey: .tint)
        }
        if (isOpaque != false) {
            try container.encode(isOpaque, forKey: .isOpaque)
        }
    }
    
    open override func draw(_ context:UIRenderContext) throws {
        try context.drawSquare(frame, backgroundColor)
        let clip = clipBounds
        
        var lastClipRect:Frame<DValue>? = nil
        if (clip) {
            lastClipRect = context.currentClipRect
            try context.setClipRectRelative(frame)
        }
        
        if let image = image {
            let destFrame:Frame<DValue>
            switch contentMode {
                case .stretch:
                    destFrame = frame
                case .aspectFit:
                    //TODO: We need more info on the image
                    let imgSize = image.texture.sourceRect.size
                    let imgSize16 = Size<DValue>(Int16(imgSize.width), Int16(imgSize.height))
                    let newSize = imgSize16.aspectFitInto(frame.size)
                    var newFrame = Frame(origin: Point.zero, size: newSize)
                    newFrame.center = frame.center
                    destFrame = newFrame
                case .aspectFill:
                    let imgSize = image.texture.sourceRect.size
                    let imgSize16 = Size<DValue>(Int16(imgSize.width), Int16(imgSize.height))
                    let newSize = imgSize16.aspectFillInto(frame.size)
                    var newFrame = Frame(origin: Point.zero, size: newSize)
                    newFrame.center = frame.center
                    destFrame = newFrame
                case .center:
                    destFrame = frame
                case .top:
                    destFrame = frame
                case .right:
                    destFrame = frame
                case .bottom:
                    destFrame = frame
                case .left:
                    destFrame = frame
                case .topRight:
                    destFrame = frame
                case .topLeft:
                    destFrame = frame
                case .bottomRight:
                    destFrame = frame
                case .bottomLeft:
                    destFrame = frame
            }
            do {
                try context.drawSquare(destFrame, SmartColor.blue)
                try context.drawImage(destFrame, tint, image: image)
            } catch {
                print("Error drawing text: \(error.localizedDescription)")
            }
        }
        
        context.pushOffset(frame.origin)
        
        for eachChild in children {
            try eachChild.draw(context)
        }
        context.popOffset(frame.origin)
        if (clip) {
            try context.setClipRect(lastClipRect)
        }
    }
}
