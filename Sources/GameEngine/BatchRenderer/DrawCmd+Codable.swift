import SDL2Swift

extension SDLColor: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.init(rawValue: try c.decode(UInt32.self))
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }
}

extension BitMaskOptionSet: Codable where RawValue: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.init(rawValue: try c.decode(RawValue.self))
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }
}

extension DrawCmdType: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, resourceId, fontHandle, content, size, align, borderColor, borderWidth, to, thickness, radius, filled
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "image":
            self = .image(resourceId: try c.decode(UInt64.self, forKey: .resourceId))
        case "fill":
            self = .fill
        case "view":
            self = .view(
                borderColor: try c.decode(SDLColor.self, forKey: .borderColor),
                borderWidth: try c.decode(Int.self, forKey: .borderWidth)
            )
        case "text":
            self = .text(
                fontHandle: try c.decode(UInt64.self, forKey: .fontHandle),
                content: try c.decode(String.self, forKey: .content),
                size: try c.decode(Float.self, forKey: .size),
                align: try c.decode(TextAlignment.self, forKey: .align)
            )
        case "line":
            self = .line(
                to: try c.decode(Point<Int>.self, forKey: .to),
                thickness: try c.decode(Int.self, forKey: .thickness)
            )
        case "circle":
            self = .circle(
                radius: try c.decode(Int.self, forKey: .radius),
                filled: try c.decode(Bool.self, forKey: .filled)
            )
        case "rect":
            self = .rect(filled: try c.decode(Bool.self, forKey: .filled))
        case "rtt":
            self = .rtt
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: c, debugDescription: "Unknown DrawCmdType: \(type)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .image(let resourceId):
            try c.encode("image", forKey: .type)
            try c.encode(resourceId, forKey: .resourceId)
        case .fill:
            try c.encode("fill", forKey: .type)
        case .view(let borderColor, let borderWidth):
            try c.encode("view", forKey: .type)
            try c.encode(borderColor, forKey: .borderColor)
            try c.encode(borderWidth, forKey: .borderWidth)
        case .text(let fontHandle, let content, let size, let align):
            try c.encode("text", forKey: .type)
            try c.encode(fontHandle, forKey: .fontHandle)
            try c.encode(content, forKey: .content)
            try c.encode(size, forKey: .size)
            try c.encode(align, forKey: .align)
        case .line(let to, let thickness):
            try c.encode("line", forKey: .type)
            try c.encode(to, forKey: .to)
            try c.encode(thickness, forKey: .thickness)
        case .circle(let radius, let filled):
            try c.encode("circle", forKey: .type)
            try c.encode(radius, forKey: .radius)
            try c.encode(filled, forKey: .filled)
        case .rect(let filled):
            try c.encode("rect", forKey: .type)
            try c.encode(filled, forKey: .filled)
        case .rtt:
            try c.encode("rtt", forKey: .type)
        }
    }
}

extension DrawCmd: Codable {
    private enum CodingKeys: String, CodingKey {
        case target, animationId, parentAnimationId, dest, color, alpha, z
        case rotation, rotationPoint, clippingRect, flip, time, type
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        target = try c.decode(UInt64.self, forKey: .target)
        animationId = try c.decode(UInt64.self, forKey: .animationId)
        parentAnimationId = try c.decode(UInt64.self, forKey: .parentAnimationId)
        dest = try c.decode(Rect<Int>.self, forKey: .dest)
        color = try c.decode(SDLColor.self, forKey: .color)
        alpha = try c.decode(Float.self, forKey: .alpha)
        z = try c.decode(Int.self, forKey: .z)
        rotation = try c.decode(Float.self, forKey: .rotation)
        rotationPoint = try c.decode(Point<Int>.self, forKey: .rotationPoint)
        clippingRect = try c.decode(Rect<Int>.self, forKey: .clippingRect)
        flip = try c.decode(BitMaskOptionSet<Renderer.RendererFlip>.self, forKey: .flip)
        time = try c.decode(UInt64.self, forKey: .time)
        type = try c.decode(DrawCmdType.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(target, forKey: .target)
        try c.encode(animationId, forKey: .animationId)
        try c.encode(parentAnimationId, forKey: .parentAnimationId)
        try c.encode(dest, forKey: .dest)
        try c.encode(color, forKey: .color)
        try c.encode(alpha, forKey: .alpha)
        try c.encode(z, forKey: .z)
        try c.encode(rotation, forKey: .rotation)
        try c.encode(rotationPoint, forKey: .rotationPoint)
        try c.encode(clippingRect, forKey: .clippingRect)
        try c.encode(flip, forKey: .flip)
        try c.encode(time, forKey: .time)
        try c.encode(type, forKey: .type)
    }
}
