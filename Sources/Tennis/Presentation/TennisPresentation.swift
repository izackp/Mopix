import Foundation

enum TennisCueKind: Equatable {
    case serveAnticipation, shotDirection, landing, hardBounce, clayBounce, grassBounce
    case smashFlash, smashStarburst, chargeMeter, chargeCap, faultCallout
}

enum TennisPlayerMotionKind: Equatable { case idle, locomotion, serveWindup, shotCharge, followThrough }

struct TennisCue: Equatable {
    var kind: TennisCueKind
    var owner: TennisSide?
    var shot: TennisShotType?
    var position: TennisPoint?
    var callout: TennisFaultCallout?
    var elapsedMilliseconds: UInt64
    var minimumLifetimeMilliseconds: UInt64
    var persistsUntilLanding: Bool
}

struct TennisPlayerPresentation: Equatable {
    var motion: TennisPlayerMotionKind
    var direction: TennisPoint
    var shot: TennisShotType?
    var elapsedMilliseconds: UInt64
    var isChargeCapped: Bool
    var impactElapsedMilliseconds: UInt64?
}

struct TennisBallPresentation: Equatable {
    var contactElapsedMilliseconds: UInt64?
    var bounceElapsedMilliseconds: UInt64?
}

struct TennisPresentationState: Equatable {
    var cues: [TennisCue]
    var players: [TennisSide: TennisPlayerPresentation]
    var ball: TennisBallPresentation?
}

struct TennisPresentationController {
    private(set) var state: TennisPresentationState
    private var previousPlayerPositions: [TennisSide: TennisPoint]

    init() {
        state = TennisPresentationState(cues: [], players: [:], ball: nil)
        previousPlayerPositions = [:]
    }

    mutating func advance(events: [TennisSimulationEvent], snapshot: TennisMatchSnapshot, elapsedMilliseconds: UInt64) {
        for index in state.cues.indices { state.cues[index].elapsedMilliseconds += elapsedMilliseconds }
        for side in [TennisSide.human, .cpu] {
            guard let player = snapshot.players[side] else { continue }
            let old = previousPlayerPositions[side] ?? player.position
            let direction = TennisPoint(x: player.position.x - old.x, y: player.position.y - old.y)
            if var presentation = state.players[side] {
                presentation.direction = direction
                presentation.elapsedMilliseconds += elapsedMilliseconds
                if let contact = presentation.impactElapsedMilliseconds {
                    presentation.impactElapsedMilliseconds = contact + elapsedMilliseconds >= 100 ? nil : contact + elapsedMilliseconds
                }
                if presentation.motion == .followThrough && presentation.elapsedMilliseconds >= 200 {
                    presentation.motion = direction == TennisPoint(x: 0, y: 0) ? .idle : .locomotion
                    presentation.elapsedMilliseconds = 0
                    presentation.shot = nil
                }
                if presentation.motion == .locomotion && direction == TennisPoint(x: 0, y: 0) { presentation.motion = .idle; presentation.elapsedMilliseconds = 0 }
                state.players[side] = presentation
            } else {
                state.players[side] = TennisPlayerPresentation(motion: .idle, direction: direction, shot: nil, elapsedMilliseconds: 0, isChargeCapped: false, impactElapsedMilliseconds: nil)
            }
            if direction != TennisPoint(x: 0, y: 0), state.players[side]?.motion == .idle { state.players[side]?.motion = .locomotion; state.players[side]?.elapsedMilliseconds = 0 }
            previousPlayerPositions[side] = player.position
        }
        if let ball = snapshot.ball {
            var presentation = state.ball ?? TennisBallPresentation(contactElapsedMilliseconds: nil, bounceElapsedMilliseconds: nil)
            if let contact = presentation.contactElapsedMilliseconds { presentation.contactElapsedMilliseconds = contact + elapsedMilliseconds >= 120 ? nil : contact + elapsedMilliseconds }
            if let bounce = presentation.bounceElapsedMilliseconds { presentation.bounceElapsedMilliseconds = bounce + elapsedMilliseconds >= 120 ? nil : bounce + elapsedMilliseconds }
            state.ball = presentation
            _ = ball
        } else { state.ball = nil }

        state.cues.removeAll { !$0.persistsUntilLanding && $0.elapsedMilliseconds >= $0.minimumLifetimeMilliseconds }
        for event in events {
            switch event {
            case let .serveAnticipationStarted(server):
                state.cues.removeAll { $0.kind == .faultCallout }
                let serveDirection = TennisPoint(x: 0, y: snapshot.players[server]?.courtEnd == .near ? -1 : 1)
                state.players[server] = TennisPlayerPresentation(motion: .serveWindup, direction: serveDirection, shot: .serve, elapsedMilliseconds: 0, isChargeCapped: false, impactElapsedMilliseconds: nil)
                state.cues.append(TennisCue(kind: .serveAnticipation, owner: server, shot: .serve, position: snapshot.players[server]?.position, callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 600, persistsUntilLanding: true))
            case let .shotTransactionChanged(owner, elapsed, capped):
                state.players[owner] = TennisPlayerPresentation(motion: .shotCharge, direction: state.players[owner]?.direction ?? TennisPoint(x: 0, y: 0), shot: nil, elapsedMilliseconds: elapsed, isChargeCapped: capped, impactElapsedMilliseconds: nil)
                state.cues.removeAll { $0.kind == .chargeMeter || $0.kind == .chargeCap }
                state.cues.append(TennisCue(kind: capped ? .chargeCap : .chargeMeter, owner: owner, shot: nil, position: snapshot.players[owner]?.position, callout: nil, elapsedMilliseconds: elapsed, minimumLifetimeMilliseconds: 0, persistsUntilLanding: true))
            case let .shotContact(owner, shot, landing, fullyCharged):
                let origin = snapshot.players[owner]?.position ?? landing
                let swingDirection = TennisPoint(x: landing.x - origin.x, y: landing.y - origin.y)
                state.players[owner] = TennisPlayerPresentation(motion: .followThrough, direction: swingDirection, shot: shot, elapsedMilliseconds: 0, isChargeCapped: fullyCharged, impactElapsedMilliseconds: shot == .smash || fullyCharged ? 0 : nil)
                state.cues.removeAll { $0.kind == .chargeMeter || $0.kind == .chargeCap || $0.kind == .serveAnticipation }
                state.cues.append(TennisCue(kind: .shotDirection, owner: owner, shot: shot, position: landing, callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 300, persistsUntilLanding: true))
                state.cues.append(TennisCue(kind: .landing, owner: owner, shot: shot, position: landing, callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 300, persistsUntilLanding: true))
                if shot == .smash {
                    state.cues.append(TennisCue(kind: .smashFlash, owner: owner, shot: shot, position: origin, callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 100, persistsUntilLanding: false))
                    state.cues.append(TennisCue(kind: .smashStarburst, owner: owner, shot: shot, position: origin, callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 100, persistsUntilLanding: false))
                }
                state.ball = TennisBallPresentation(contactElapsedMilliseconds: 0, bounceElapsedMilliseconds: nil)
            case let .bounce(surface, shot, position):
                state.cues.removeAll { $0.persistsUntilLanding }
                let kind: TennisCueKind = surface == .hard ? .hardBounce : (surface == .clay ? .clayBounce : .grassBounce)
                state.cues.append(TennisCue(kind: kind, owner: nil, shot: shot, position: position, callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 300, persistsUntilLanding: false))
                state.ball = TennisBallPresentation(contactElapsedMilliseconds: nil, bounceElapsedMilliseconds: 0)
            case let .fault(callout): state.cues.append(TennisCue(kind: .faultCallout, owner: nil, shot: nil, position: nil, callout: callout, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 1000, persistsUntilLanding: false))
            case .pointEnded, .matchEnded: state.cues.removeAll { $0.kind != .faultCallout }
            }
        }
    }

    mutating func resetForMatch(snapshot: TennisMatchSnapshot) {
        state = TennisPresentationState(cues: [], players: [:], ball: nil)
        previousPlayerPositions = snapshot.players.mapValues(\.position)
    }

}
