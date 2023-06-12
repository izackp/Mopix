//
//  Edge.swift
//  
//
//  Created by Isaac Paul on 6/12/23.
//


public enum Edge: String, Codable, ExpressibleByString {
    public init(_ value: String) throws {
        self.init(rawValue:value)! //throw GenericError("String not convertible to edge: \(value)")
    }
    
    case Left
    case Top
    case Right
    case Bottom
    case Start
    case End
    /*
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try cont
        var allKeys = ArraySlice(container.allKeys)
        guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
            throw DecodingError.typeMismatch(Edge.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
        }
        switch onlyKey {
        case .Left:
            let nestedContainer = try container.nestedContainer(keyedBy: Edge.LeftCodingKeys.self, forKey: .Left)
            self = Edge.Left
        case .Top:
            let nestedContainer = try container.nestedContainer(keyedBy: Edge.TopCodingKeys.self, forKey: .Top)
            self = Edge.Top
        case .Right:
            let nestedContainer = try container.nestedContainer(keyedBy: Edge.RightCodingKeys.self, forKey: .Right)
            self = Edge.Right
        case .Bottom:
            let nestedContainer = try container.nestedContainer(keyedBy: Edge.BottomCodingKeys.self, forKey: .Bottom)
            self = Edge.Bottom
        case .Start:
            let nestedContainer = try container.nestedContainer(keyedBy: Edge.StartCodingKeys.self, forKey: .Start)
            self = Edge.Start
        case .End:
            let nestedContainer = try container.nestedContainer(keyedBy: Edge.EndCodingKeys.self, forKey: .End)
            self = Edge.End
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case Left
        case Top
        case Right
        case Bottom
        case Start
        case End
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .Left:
            var nestedContainer = container.nestedContainer(keyedBy: Edge.LeftCodingKeys.self, forKey: .Left)
        case .Top:
            var nestedContainer = container.nestedContainer(keyedBy: Edge.TopCodingKeys.self, forKey: .Top)
        case .Right:
            var nestedContainer = container.nestedContainer(keyedBy: Edge.RightCodingKeys.self, forKey: .Right)
        case .Bottom:
            var nestedContainer = container.nestedContainer(keyedBy: Edge.BottomCodingKeys.self, forKey: .Bottom)
        case .Start:
            var nestedContainer = container.nestedContainer(keyedBy: Edge.StartCodingKeys.self, forKey: .Start)
        case .End:
            var nestedContainer = container.nestedContainer(keyedBy: Edge.EndCodingKeys.self, forKey: .End)
        }
    }*/
}
