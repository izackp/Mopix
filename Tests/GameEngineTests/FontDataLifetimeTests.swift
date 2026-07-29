import XCTest
import SDL2
@testable import GameEngine

@MainActor
final class FontDataLifetimeTests: XCTestCase {
    func testTennisFontMetricsAndGlyphsRemainReadableAfterFetchReturns() throws {
        let application = try Application()
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        try application.vd.mountPath(path: root.appendingPathComponent("Sources/Tennis/ExternalFiles"))

        let window = try FullWindow(
            parent: application,
            title: "FontDataLifetimeTest",
            frame: Rect(x: 0, y: 0, width: 32, height: 32),
            windowOptions: [.hidden]
        )
        let fontURL = URL(string: "vd:/Roboto-Medium.ttf")!
        try window.imageManager.addFont(fontURL)
        let descriptor = FontDesc(family: "Roboto", weight: 100, size: 14)
        let font = try XCTUnwrap(try window.imageManager.fetchFont(desc: descriptor))

        for character in [Character("O"), Character("U"), Character("T")] {
            let metrics = try font._font.glyphMetrics(c: character)
            let glyph = try font.glyph(character)
            XCTAssertGreaterThan(metrics.advance, 0, "missing metrics for \(character)")
            XCTAssertGreaterThan(glyph.sourceRect.width, 0, "missing rasterized width for \(character)")
            XCTAssertGreaterThan(glyph.sourceRect.height, 0, "missing rasterized height for \(character)")
            print("glyph \(character): advance=\(metrics.advance), raster=\(glyph.sourceRect.width)x\(glyph.sourceRect.height)")
        }
    }
}
