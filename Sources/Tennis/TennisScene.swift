import GameEngine
import SDL2Swift

final class TennisScene: IDrawable {
    private enum Layer {
        static let background: UInt64 = 1
        static let court: UInt64 = 2
        static let courtBorder: UInt64 = 3
        static let topServiceLine: UInt64 = 4
        static let bottomServiceLine: UInt64 = 5
        static let centerServiceLine: UInt64 = 6
        static let netBand: UInt64 = 7
        static let netPosts: UInt64 = 8
        static let topCenterMark: UInt64 = 9
        static let bottomCenterMark: UInt64 = 10
        static let lowerPlayer: UInt64 = 11
        static let upperPlayer: UInt64 = 12
        static let ball: UInt64 = 13
    }

    private let viewport = Rect(x: 0, y: 0, width: 160, height: 144)
    private let court = Rect(x: 24, y: 10, width: 112, height: 124)
    private let lineColor = SDLColor(rawValue: 0xFFF2F1D5)
    private let backgroundColor = SDLColor(rawValue: 0xFF1E5334)
    private let courtColor = SDLColor(rawValue: 0xFF3D8AA8)
    private let netColor = SDLColor(rawValue: 0xFF292C33)
    private let lowerPlayerColor = SDLColor(rawValue: 0xFFF46D43)
    private let upperPlayerColor = SDLColor(rawValue: 0xFF46C28B)
    private let ballColor = SDLColor(rawValue: 0xFFF7EE59)

    func draw(_ delta: UInt64, _ renderer: RendererClient) {
        let netY = court.centerY
        let serviceInset = 28
        let serviceLineThickness = 2
        let baselineCenterMarkWidth = 2
        let baselineCenterMarkHeight = 5
        let playerSize = Size(8, 12)
        let ballSize = Size(3, 3)

        fill(renderer, id: Layer.background, rect: viewport, color: backgroundColor, z: 0)
        view(renderer, id: Layer.courtBorder, rect: court, fill: courtColor, border: lineColor, borderWidth: 2, z: 1)

        fill(renderer, id: Layer.topServiceLine, rect: Rect(x: court.x + 2, y: court.y + serviceInset, width: court.width - 4, height: serviceLineThickness), color: lineColor, z: 2)
        fill(renderer, id: Layer.bottomServiceLine, rect: Rect(x: court.x + 2, y: court.bottom - serviceInset - serviceLineThickness, width: court.width - 4, height: serviceLineThickness), color: lineColor, z: 2)
        fill(renderer, id: Layer.centerServiceLine, rect: Rect(x: court.centerX - 1, y: court.y + serviceInset, width: 2, height: court.height - serviceInset * 2), color: lineColor, z: 2)

        fill(renderer, id: Layer.netBand, rect: Rect(x: court.x + 1, y: netY - 1, width: court.width - 2, height: 3), color: netColor, z: 3)
        fill(renderer, id: Layer.netPosts, rect: Rect(x: court.x - 1, y: netY - 4, width: court.width + 2, height: 1), color: lineColor, z: 3)

        fill(renderer, id: Layer.topCenterMark, rect: Rect(x: court.centerX - 1, y: court.y, width: baselineCenterMarkWidth, height: baselineCenterMarkHeight), color: lineColor, z: 2)
        fill(renderer, id: Layer.bottomCenterMark, rect: Rect(x: court.centerX - 1, y: court.bottom - baselineCenterMarkHeight, width: baselineCenterMarkWidth, height: baselineCenterMarkHeight), color: lineColor, z: 2)

        let lowerPlayerRect = Rect(
            x: court.centerX - playerSize.width / 2,
            y: court.bottom - 18,
            width: playerSize.width,
            height: playerSize.height
        )
        let upperPlayerRect = Rect(
            x: court.centerX - playerSize.width / 2,
            y: court.y + 7,
            width: playerSize.width,
            height: playerSize.height
        )
        let ballRect = Rect(
            x: court.centerX + 10,
            y: netY - 2,
            width: ballSize.width,
            height: ballSize.height
        )

        view(renderer, id: Layer.lowerPlayer, rect: lowerPlayerRect, fill: lowerPlayerColor, border: lineColor, borderWidth: 1, z: 4)
        view(renderer, id: Layer.upperPlayer, rect: upperPlayerRect, fill: upperPlayerColor, border: lineColor, borderWidth: 1, z: 4)
        view(renderer, id: Layer.ball, rect: ballRect, fill: ballColor, border: netColor, borderWidth: 1, z: 5)
    }

    private func fill(_ renderer: RendererClient, id: UInt64, rect: Rect<Int>, color: SDLColor, z: Int) {
        renderer.drawCmd(
            DrawCmd(
                animationId: id,
                parentAnimationId: 0,
                dest: rect,
                color: color,
                alpha: 1,
                z: z,
                rotation: 0,
                rotationPoint: .zero,
                clippingRect: .zero,
                flip: [],
                time: renderer.defaultTime,
                type: .fill
            )
        )
    }

    private func view(_ renderer: RendererClient, id: UInt64, rect: Rect<Int>, fill: SDLColor, border: SDLColor, borderWidth: Int, z: Int) {
        renderer.drawCmd(
            DrawCmd(
                animationId: id,
                parentAnimationId: 0,
                dest: rect,
                color: fill,
                alpha: 1,
                z: z,
                rotation: 0,
                rotationPoint: .zero,
                clippingRect: .zero,
                flip: [],
                time: renderer.defaultTime,
                type: .view(borderColor: border, borderWidth: borderWidth)
            )
        )
    }
}
