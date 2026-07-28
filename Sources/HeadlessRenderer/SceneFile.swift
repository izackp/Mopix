import Foundation

enum HeadlessSceneID: String, Decodable {
    case tennis
}

struct SceneFile: Decodable {
    let scene: HeadlessSceneID
    let logicalWidth: Int
    let logicalHeight: Int
    let scale: Float
    let expectedResult: String

    static func load(from url: URL) throws -> SceneFile {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        return try decoder.decode(SceneFile.self, from: data)
    }
}
