import Foundation

public typealias TennisFixed = Int32

public struct TennisPoint: Equatable {
    public var x: TennisFixed
    public var y: TennisFixed
    public init(x: TennisFixed, y: TennisFixed) { self.x = x; self.y = y }
}

public struct TennisVelocity: Equatable {
    public var x: TennisFixed
    public var y: TennisFixed
    public var z: TennisFixed
    public init(x: TennisFixed, y: TennisFixed, z: TennisFixed) { self.x = x; self.y = y; self.z = z }
}

public enum TennisSide: Hashable { case human, cpu }
public enum CourtSurface: Hashable { case hard, clay, grass }
public struct PlayerStats: Equatable {
    public var power: Int; public var speed: Int; public var control: Int; public var spin: Int
    public init(power: Int, speed: Int, control: Int, spin: Int) { self.power = power; self.speed = speed; self.control = control; self.spin = spin }
}
public enum PlayerPreset: Hashable { case balanced, power }
public struct TennisRect: Equatable {
    public let minX: TennisFixed; public let minY: TennisFixed; public let maxX: TennisFixed; public let maxY: TennisFixed
    public init(minX: TennisFixed, minY: TennisFixed, maxX: TennisFixed, maxY: TennisFixed) { self.minX = minX; self.minY = minY; self.maxX = maxX; self.maxY = maxY }
}
public struct TennisServiceBoxes: Equatable {
    public let topLeft: TennisRect; public let topRight: TennisRect; public let bottomLeft: TennisRect; public let bottomRight: TennisRect
    public init(topLeft: TennisRect, topRight: TennisRect, bottomLeft: TennisRect, bottomRight: TennisRect) { self.topLeft = topLeft; self.topRight = topRight; self.bottomLeft = bottomLeft; self.bottomRight = bottomRight }
}
public struct CourtRules: Equatable {
    public let surface: CourtSurface; public let singlesBoundary: TennisRect; public let serviceBoxes: TennisServiceBoxes; public let netY: TennisFixed
    public init(surface: CourtSurface, singlesBoundary: TennisRect, serviceBoxes: TennisServiceBoxes, netY: TennisFixed) { self.surface = surface; self.singlesBoundary = singlesBoundary; self.serviceBoxes = serviceBoxes; self.netY = netY }
}

public enum ShotKind: Hashable { case topspin, slice, flat, lob, drop, smash, serve }
public enum ContactQuality: Hashable { case perfect, good, poor }
public enum TennisSwingSequence: Hashable { case standaloneA, standaloneB, simultaneousAB, aThenB, bThenA }
public enum TennisActionIntent { case none; case move(direction: TennisDirection); case swing(sequence: TennisSwingSequence, charge: Int) }
public struct TennisDirection: Equatable { public let x: Int; public let y: Int; public init(x: Int, y: Int) { self.x = x; self.y = y } }
public struct ShotCommand {
    public let side: TennisSide; public let kind: ShotKind; public let target: TennisPoint; public let charge: Int; public let contactQuality: ContactQuality
    public init(side: TennisSide, kind: ShotKind, target: TennisPoint, charge: Int, contactQuality: ContactQuality) { self.side = side; self.kind = kind; self.target = target; self.charge = charge; self.contactQuality = contactQuality }
}

public struct TennisPlayerState {
    public let side: TennisSide; public var position: TennisPoint; public var stats: PlayerStats; public var preset: PlayerPreset; public var swingPending: Bool; public var hitstopTicksRemaining: Int
    public init(side: TennisSide, position: TennisPoint, stats: PlayerStats, preset: PlayerPreset, swingPending: Bool = false, hitstopTicksRemaining: Int = 0) { self.side = side; self.position = position; self.stats = stats; self.preset = preset; self.swingPending = swingPending; self.hitstopTicksRemaining = hitstopTicksRemaining }
}
public struct TennisBallState {
    public var position: TennisPoint; public var height: TennisFixed; public var velocity: TennisVelocity; public var shotKind: ShotKind; public var lastHitter: TennisSide?; public var isInFlight: Bool
    public init(position: TennisPoint, height: TennisFixed, velocity: TennisVelocity, shotKind: ShotKind, lastHitter: TennisSide? = nil, isInFlight: Bool = false) { self.position = position; self.height = height; self.velocity = velocity; self.shotKind = shotKind; self.lastHitter = lastHitter; self.isInFlight = isInFlight }
}
public enum PointEndReason: Equatable {
    case secondBounce(side: TennisSide)
    case netFault(hitter: TennisSide)
    case outOfBounds(hitter: TennisSide)
    case serveFault(server: TennisSide, landing: TennisPoint)
}
public struct TennisSimulationState {
    public var tick: UInt64; public var server: TennisSide; public var players: [TennisSide: TennisPlayerState]; public var ball: TennisBallState; public var pointEnd: PointEndReason?; public var hitstopTicksRemaining: Int
    public init(tick: UInt64, server: TennisSide, players: [TennisSide: TennisPlayerState], ball: TennisBallState, pointEnd: PointEndReason? = nil, hitstopTicksRemaining: Int = 0) { self.tick = tick; self.server = server; self.players = players; self.ball = ball; self.pointEnd = pointEnd; self.hitstopTicksRemaining = hitstopTicksRemaining }
}
public struct TennisSimulationEvent { public let tick: UInt64; public let kind: TennisSimulationEventKind; public init(tick: UInt64, kind: TennisSimulationEventKind) { self.tick = tick; self.kind = kind } }
public enum TennisSimulationEventKind: Equatable {
    case serveHit(side: TennisSide)
    case serveFault(server: TennisSide, landing: TennisPoint)
    case shotHit(side: TennisSide, shot: ShotKind, quality: ContactQuality)
    case bounce(surface: CourtSurface)
    case netContact(side: TennisSide)
    case outOfBounds(side: TennisSide)
    case pointEnded(reason: PointEndReason)
}

public protocol TennisRandomSource { func nextInt(upperBound: Int) -> Int }
public protocol TennisRuleBook {
    func playerStats(for preset: PlayerPreset) -> PlayerStats
    func contactQuality(distance: TennisFixed) -> ContactQuality
    func isSmashEligible(ballHeight: TennisFixed, playerDistance: TennisFixed) -> Bool
    func shotKind(for sequence: TennisSwingSequence, smashEligible: Bool) -> ShotKind
    func isLegalServe(landing: TennisPoint, server: TennisSide, court: CourtRules) -> Bool
    func pointWinner(for reason: PointEndReason) -> TennisSide
}
public protocol TennisSimulationDelegate: AnyObject { func simulationDidEmit(_ event: TennisSimulationEvent) }

public final class SeededTennisRandomSource: TennisRandomSource {
    private var state: UInt64
    public init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    public func nextInt(upperBound: Int) -> Int { precondition(upperBound > 0); state ^= state << 7; state ^= state >> 9; state ^= state << 8; return Int(state % UInt64(upperBound)) }
}

public final class DefaultTennisRuleBook: TennisRuleBook {
    public init() {}
    public func playerStats(for preset: PlayerPreset) -> PlayerStats { preset == .balanced ? PlayerStats(power: 100, speed: 100, control: 100, spin: 100) : PlayerStats(power: 115, speed: 95, control: 90, spin: 110) }
    public func contactQuality(distance: TennisFixed) -> ContactQuality { distance <= 300 ? .perfect : distance <= 700 ? .good : .poor }
    public func isSmashEligible(ballHeight: TennisFixed, playerDistance: TennisFixed) -> Bool { ballHeight > 900 && playerDistance <= 450 }
    public func shotKind(for sequence: TennisSwingSequence, smashEligible: Bool) -> ShotKind {
        switch sequence { case .standaloneA: return .topspin; case .standaloneB: return .slice; case .aThenB: return .lob; case .bThenA: return .drop; case .simultaneousAB: return smashEligible ? .smash : .flat }
    }
    public func isLegalServe(landing: TennisPoint, server: TennisSide, court: CourtRules) -> Bool {
        let midpoint = (court.singlesBoundary.minX + court.singlesBoundary.maxX) / 2
        let box: TennisRect
        switch (server, landing.x < midpoint) { case (.human, true): box = court.serviceBoxes.topLeft; case (.human, false): box = court.serviceBoxes.topRight; case (.cpu, true): box = court.serviceBoxes.bottomLeft; case (.cpu, false): box = court.serviceBoxes.bottomRight }
        return landing.x >= box.minX && landing.x <= box.maxX && landing.y >= box.minY && landing.y <= box.maxY
    }
    public func pointWinner(for reason: PointEndReason) -> TennisSide {
        switch reason { case .secondBounce(let side): return opposite(side); case .netFault(let hitter), .outOfBounds(let hitter): return opposite(hitter); case .serveFault(let server, _): return opposite(server) }
    }
    private func opposite(_ side: TennisSide) -> TennisSide { side == .human ? .cpu : .human }
}

public struct TennisTickInput { public let human: TennisActionIntent; public let cpu: TennisActionIntent; public init(human: TennisActionIntent, cpu: TennisActionIntent) { self.human = human; self.cpu = cpu } }

public final class TennisSimulation {
    public let rules: CourtRules; public let ruleBook: TennisRuleBook; public let random: TennisRandomSource; public weak var delegate: TennisSimulationDelegate?; public private(set) var state: TennisSimulationState
    private var bounceCount = 0
    private let netHeight: TennisFixed = 500
    private let gravity: TennisFixed = 90
    public init(rules: CourtRules, ruleBook: TennisRuleBook, random: TennisRandomSource, state: TennisSimulationState) { self.rules = rules; self.ruleBook = ruleBook; self.random = random; self.state = state }
    public func snapshot() -> TennisSimulationState { state }
    public func resetPoint(server: TennisSide) { state.server = server; state.pointEnd = nil; state.ball.isInFlight = false; state.ball.velocity = TennisVelocity(x: 0, y: 0, z: 0); state.ball.height = 0; state.tick &+= 1; bounceCount = 0; state.hitstopTicksRemaining = 0; for side in [TennisSide.human, .cpu] { state.players[side]?.swingPending = false; state.players[side]?.hitstopTicksRemaining = 0 } }
    public func step(tickInput: TennisTickInput) {
        state.tick &+= 1
        guard state.pointEnd == nil else { return }
        if state.hitstopTicksRemaining > 0 { state.hitstopTicksRemaining -= 1; for side in [TennisSide.human, .cpu] { state.players[side]?.hitstopTicksRemaining = state.hitstopTicksRemaining }; return }
        if state.ball.isInFlight { move(.human, intent: tickInput.human); move(.cpu, intent: tickInput.cpu) }
        let intents: [(TennisSide, TennisActionIntent)] = [(.human, tickInput.human), (.cpu, tickInput.cpu)]
        for (side, intent) in intents { guard case .swing(let sequence, let charge) = intent else { continue }; state.players[side]?.swingPending = true; if canContact(side) && (side == .human || !canContact(.human)) { hit(side: side, sequence: sequence, charge: charge) } }
        if state.ball.isInFlight { advanceBall() }
    }
    private func move(_ side: TennisSide, intent: TennisActionIntent) { guard case .move(let direction) = intent, var player = state.players[side] else { return }; player.position.x += TennisFixed(max(-1, min(1, direction.x)) * player.stats.speed / 20); player.position.y += TennisFixed(max(-1, min(1, direction.y)) * player.stats.speed / 20); state.players[side] = player }
    private func distance(_ a: TennisPoint, _ b: TennisPoint) -> TennisFixed { let x = Int64(a.x - b.x), y = Int64(a.y - b.y), squared = x * x + y * y; var root: Int64 = 0; while (root + 1) * (root + 1) <= squared { root += 1 }; return TennisFixed(min(Int64(Int32.max), root)) }
    private func canContact(_ side: TennisSide) -> Bool { guard let player = state.players[side] else { return false }; return !state.ball.isInFlight ? side == state.server : distance(player.position, state.ball.position) <= 1200 }
    private func hit(side: TennisSide, sequence: TennisSwingSequence, charge: Int) {
        guard let player = state.players[side] else { return }
        let quality = ruleBook.contactQuality(distance: distance(player.position, state.ball.position))
        let cappedCharge = max(0, min(100, charge))
        var target: TennisPoint
        if !state.ball.isInFlight {
            let landing = serveLanding(server: side, player: player, charge: cappedCharge)
            guard ruleBook.isLegalServe(landing: landing, server: side, court: rules) else { emit(.serveFault(server: side, landing: landing)); end(.serveFault(server: side, landing: landing)); return }
            emit(.serveHit(side: side))
            state.ball.shotKind = .serve
            target = landing
        } else {
            let eligible = ruleBook.isSmashEligible(ballHeight: state.ball.height, playerDistance: distance(player.position, state.ball.position))
            state.ball.shotKind = ruleBook.shotKind(for: sequence, smashEligible: eligible)
            target = targetPoint(for: side, shot: state.ball.shotKind, player: player)
        }
        let shot = state.ball.shotKind
        let speed = surfaceSpeed() + TennisFixed(player.stats.power / 4) + TennisFixed(cappedCharge / 4)
        let arc: TennisFixed = shot == .lob ? 360 : shot == .drop ? 80 : shot == .smash ? 460 : shot == .slice ? 120 : shot == .topspin ? 280 : 240
        state.ball.velocity = TennisVelocity(x: (target.x - state.ball.position.x) * speed / 1000, y: (target.y - state.ball.position.y) * speed / 1000, z: arc + TennisFixed(player.stats.spin - 100))
        state.ball.lastHitter = side; state.ball.isInFlight = true; bounceCount = 0
        emit(.shotHit(side: side, shot: shot, quality: quality))
        if shot == .smash || cappedCharge == 100 { state.hitstopTicksRemaining = 2; state.players[side]?.hitstopTicksRemaining = 2 }
    }
    private func serveLanding(server: TennisSide, player: TennisPlayerState, charge: Int) -> TennisPoint {
        let midpoint = (rules.singlesBoundary.minX + rules.singlesBoundary.maxX) / 2
        let left = (random.nextInt(upperBound: 2) == 0)
        let box = server == .human ? (left ? rules.serviceBoxes.topLeft : rules.serviceBoxes.topRight) : (left ? rules.serviceBoxes.bottomLeft : rules.serviceBoxes.bottomRight)
        let center = (box.minX + box.maxX) / 2
        let aimError = max(0, 100 - player.stats.control) * 10 + charge / 5
        let error = TennisFixed(random.nextInt(upperBound: aimError * 2 + 1)) - TennisFixed(aimError)
        let x = center + error + (player.position.x < midpoint ? -100 : 100)
        return TennisPoint(x: x, y: (box.minY + box.maxY) / 2)
    }
    private func targetPoint(for side: TennisSide, shot: ShotKind, player: TennisPlayerState) -> TennisPoint {
        let center = (rules.singlesBoundary.minX + rules.singlesBoundary.maxX) / 2
        let deep = shot == .lob || shot == .topspin || shot == .smash
        let aimSpread = max(0, 100 - player.stats.control)
        let randomAim = random.nextInt(upperBound: 2001) - 1000
        let aimOffset = randomAim * aimSpread / 100
        let baseX = center + TennisFixed(aimOffset)
        let y = side == .human ? (deep ? rules.singlesBoundary.minY + 1500 : rules.netY - 800) : (deep ? rules.singlesBoundary.maxY - 1500 : rules.netY + 800)
        return TennisPoint(x: TennisFixed(baseX), y: y)
    }
    private func surfaceSpeed() -> TennisFixed { rules.surface == .clay ? 85 : rules.surface == .grass ? 125 : 100 }
    private func advanceBall() { let beforeY = state.ball.position.y; state.ball.position.x += state.ball.velocity.x; state.ball.position.y += state.ball.velocity.y; state.ball.height += state.ball.velocity.z; state.ball.velocity.z -= gravity
        if (beforeY < rules.netY && state.ball.position.y >= rules.netY) || (beforeY > rules.netY && state.ball.position.y <= rules.netY), state.ball.height < netHeight { let hitter = state.ball.lastHitter ?? state.server; emit(.netContact(side: hitter)); end(.netFault(hitter: hitter)); return }
        guard state.ball.height <= 0 else { return }; state.ball.height = 0
        if !inside(rules.singlesBoundary, state.ball.position) { let hitter = state.ball.lastHitter ?? state.server; emit(.outOfBounds(side: hitter)); end(.outOfBounds(hitter: hitter)); return }
        bounceCount += 1; emit(.bounce(surface: rules.surface)); if bounceCount >= 2 { end(.secondBounce(side: receivingSide(at: state.ball.position))); return }
        let spin = state.players[state.ball.lastHitter ?? state.server]?.stats.spin ?? 100
        let multiplier: TennisFixed = rules.surface == .hard ? 75 : rules.surface == .clay ? 60 : 50
        state.ball.velocity.z = -state.ball.velocity.z * (multiplier + TennisFixed(spin - 100) / 2) / 100
    }
    private func receivingSide(at point: TennisPoint) -> TennisSide { point.y < rules.netY ? .cpu : .human }
    private func inside(_ rect: TennisRect, _ point: TennisPoint) -> Bool { point.x >= rect.minX && point.x <= rect.maxX && point.y >= rect.minY && point.y <= rect.maxY }
    private func end(_ reason: PointEndReason) { guard state.pointEnd == nil else { return }; state.pointEnd = reason; state.ball.isInFlight = false; emit(.pointEnded(reason: reason)) }
    private func emit(_ kind: TennisSimulationEventKind) { delegate?.simulationDidEmit(TennisSimulationEvent(tick: state.tick, kind: kind)) }
}
