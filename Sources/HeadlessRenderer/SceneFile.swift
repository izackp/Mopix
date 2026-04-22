import Foundation

struct SceneFile: Decodable {
    var logicalWidth: Int
    var logicalHeight: Int
    var scale: Float
    var packName: String?
    var viewPath: String?

    enum CodingKeys: String, CodingKey {
        case logicalWidth, logicalHeight, scale, packName, viewPath
    }

    static func load(from url: URL) throws -> SceneFile {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        return try decoder.decode(SceneFile.self, from: data)
    }
}
