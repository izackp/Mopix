import Foundation

enum TennisLandingJudgment: Equatable { case inBounds, outOfBounds }
struct TennisSurfaceProfile: Equatable { var contactToBounceMilliseconds: UInt64; var responseWindowMilliseconds: UInt64; var bounceHeight: Int; var skidDistance: Int }
struct TennisShotOutcome: Equatable { var landing: TennisPoint; var contactToBounceMilliseconds: UInt64; var responseWindowMilliseconds: UInt64; var bounceHeight: Int; var skidDistance: Int }

struct TennisRules {
    let configuration: TennisGameConfiguration
    init(configuration: TennisGameConfiguration) { self.configuration = configuration }
    func courtBounds() -> TennisRect { TennisRect(minX: 16, minY: 24, maxX: 144, maxY: 120) }
    func movementBounds(for end: TennisCourtEnd) -> TennisRect { end == .near ? TennisRect(minX: 20, minY: 78, maxX: 140, maxY: 120) : TennisRect(minX: 20, minY: 24, maxX: 140, maxY: 66) }
    func preset(for side: TennisSide) -> TennisStatPreset { side == .human ? .balanced : .power }
    func movementDelta(input: TennisPoint, preset: TennisStatPreset, remainderMilliPixels: inout TennisPoint) -> TennisPoint {
        let speed = preset == .power ? 79_200 : 72_000
        let diagonal = input.x != 0 && input.y != 0
        let axis = diagonal ? 707 : 1000
        let perTick = speed * Int(configuration.tickMilliseconds) * axis / 1_000_000
        var x = perTick * input.x + remainderMilliPixels.x
        var y = perTick * input.y + remainderMilliPixels.y
        let dx = x / 1000; let dy = y / 1000
        remainderMilliPixels = TennisPoint(x: x - dx * 1000, y: y - dy * 1000)
        return TennisPoint(x: dx, y: dy)
    }
    func contactQuality(player: TennisPoint, ball: TennisPoint) -> TennisContactQuality? {
        let dx = player.x - ball.x; let dy = player.y - ball.y
        let distanceSquared = dx * dx + dy * dy
        if distanceSquared > 16 * 16 { return nil }
        if distanceSquared <= 4 * 4 { return .perfect }
        if distanceSquared <= 10 * 10 { return .good }
        return .poor
    }
    func isSmashEligible(player: TennisPoint, ball: TennisBallFlight) -> Bool {
        let dx = player.x - ball.shadow.x; let dy = player.y - ball.shadow.y
        return ball.height >= 12 && dx * dx + dy * dy <= 6 * 6
    }
    func surfaceProfile(surface: TennisSurface, shot: TennisShotType, preset: TennisStatPreset, chargedMilliseconds: UInt64) -> TennisSurfaceProfile {
        let ordinary: [TennisSurface: UInt64] = [.hard: 700, .clay: 850, .grass: 580]
        let fast: [TennisSurface: UInt64] = [.hard: 560, .clay: 660, .grass: 480]
        let lob: [TennisSurface: UInt64] = [.hard: 1050, .clay: 1200, .grass: 900]
        let minimumOrdinary: [TennisSurface: UInt64] = [.hard: 560, .clay: 710, .grass: 440]
        let minimumFast: [TennisSurface: UInt64] = [.hard: 420, .clay: 520, .grass: 340]
        let minimumLob: [TennisSurface: UInt64] = [.hard: 910, .clay: 1060, .grass: 760]
        let ordinaryResponse: [TennisSurface: UInt64] = [.hard: 350, .clay: 400, .grass: 290]
        let fastResponse: [TennisSurface: UInt64] = [.hard: 290, .clay: 320, .grass: 270]
        let lobResponse: [TennisSurface: UInt64] = [.hard: 420, .clay: 470, .grass: 340]
        let isLob = shot == .lob; let isFast = shot == .flat || shot == .smash
        let base = isLob ? lob[surface]! : (isFast ? fast[surface]! : ordinary[surface]!)
        let minimum = isLob ? minimumLob[surface]! : (isFast ? minimumFast[surface]! : minimumOrdinary[surface]!)
        let chargeReduction = 100 * min(chargedMilliseconds, 600) / 600
        let powerReduction: UInt64 = preset == .power ? 40 : 0
        let timing = max(minimum, base - (chargeReduction + powerReduction))
        let heights: [TennisShotType: [TennisSurface: Int]] = [
            .topspin: [.hard: 18, .clay: 14, .grass: 12], .slice: [.hard: 8, .clay: 6, .grass: 5],
            .flat: [.hard: 11, .clay: 8, .grass: 7], .lob: [.hard: 20, .clay: 16, .grass: 14],
            .drop: [.hard: 7, .clay: 5, .grass: 4], .smash: [.hard: 12, .clay: 10, .grass: 8],
            .serve: [.hard: 18, .clay: 14, .grass: 12]
        ]
        var height = heights[shot]![surface]!
        if preset == .power && (shot == .topspin || shot == .lob) { height += 1 }
        if preset == .power && (shot == .serve || shot == .flat || shot == .smash) { height += 1 }
        var skid = surface == .hard ? 8 : (surface == .clay ? 4 : 12)
        if shot == .slice { skid += 4 }; if shot == .drop { skid += 2 }
        return TennisSurfaceProfile(contactToBounceMilliseconds: timing, responseWindowMilliseconds: isLob ? lobResponse[surface]! : (isFast ? fastResponse[surface]! : (shot == .serve ? ordinaryResponse[surface]! : ordinaryResponse[surface]!)), bounceHeight: height, skidDistance: skid)
    }
    func shotOutcome(hitter: TennisPlayerState, opponent: TennisPlayerState, surface: TennisSurface, shot: TennisShotType, chargedMilliseconds: UInt64, target: TennisPoint, random: inout TennisSeededRandom) -> TennisShotOutcome {
        let profile = surfaceProfile(surface: surface, shot: shot, preset: hitter.preset, chargedMilliseconds: chargedMilliseconds)
        let spread = hitter.preset == .power ? 4 : 8
        let landing = TennisPoint(x: target.x + random.nextInt(upperBound: 2 * spread + 1) - spread, y: target.y + random.nextInt(upperBound: 2 * spread + 1) - spread)
        return TennisShotOutcome(landing: landing, contactToBounceMilliseconds: profile.contactToBounceMilliseconds, responseWindowMilliseconds: profile.responseWindowMilliseconds, bounceHeight: profile.bounceHeight, skidDistance: profile.skidDistance)
    }
    func clearsNet(_ ball: TennisBallFlight) -> Bool { ball.shadow.x >= 16 && ball.shadow.x <= 144 && ball.height >= 12 }
    func landingJudgment(_ point: TennisPoint) -> TennisLandingJudgment { point.x >= 16 && point.x <= 144 && point.y >= 24 && point.y <= 120 ? .inBounds : .outOfBounds }
    func isLegalServeLanding(_ point: TennisPoint, server: TennisSide) -> Bool { let box = server == .human ? configuration.humanServeBox : configuration.cpuServeBox; return point.x >= box.minX && point.x <= box.maxX && point.y >= box.minY && point.y <= box.maxY }
    func score(after winner: TennisSide, current: TennisScore) -> TennisScore { winner == .human ? TennisScore(human: current.human + 1, cpu: current.cpu) : TennisScore(human: current.human, cpu: current.cpu + 1) }
    func hasMatchWinner(_ score: TennisScore) -> TennisSide? { if score.human >= 11 && score.human - score.cpu >= 2 { return .human }; if score.cpu >= 11 && score.cpu - score.human >= 2 { return .cpu }; return nil }
    func server(totalPointsPlayed: Int) -> TennisSide { ((totalPointsPlayed / 2) % 2 == 0) ? configuration.openingServer : (configuration.openingServer == .human ? .cpu : .human) }
    func classifyError(reason: TennisPointEndReason, quality: TennisContactQuality?) -> TennisErrorClassification { guard reason == .netFault || reason == .outOfBounds else { return .none }; return quality == .perfect || quality == .good ? .unforced : .forced }
}
