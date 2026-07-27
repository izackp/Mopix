import Foundation

enum TennisCueKind: Equatable { case serveAnticipation, shotDirection, landing, hardBounce, clayBounce, grassBounce, smashFlash, smashStarburst, chargeMeter, chargeCap, faultCallout }
struct TennisCue: Equatable { var kind: TennisCueKind; var owner: TennisSide?; var shot: TennisShotType?; var position: TennisPoint?; var callout: TennisFaultCallout?; var elapsedMilliseconds: UInt64; var minimumLifetimeMilliseconds: UInt64; var persistsUntilLanding: Bool }
struct TennisPresentationState: Equatable { var cues: [TennisCue] }

struct TennisPresentationController {
    private(set) var state: TennisPresentationState
    init() { state = TennisPresentationState(cues: []) }

    mutating func advance(events: [TennisSimulationEvent], snapshot: TennisMatchSnapshot, elapsedMilliseconds: UInt64) {
        for index in state.cues.indices { state.cues[index].elapsedMilliseconds += elapsedMilliseconds }
        state.cues.removeAll { !$0.persistsUntilLanding && $0.elapsedMilliseconds >= $0.minimumLifetimeMilliseconds }
        for event in events {
            switch event {
            case let .serveAnticipationStarted(server): state.cues.append(TennisCue(kind: .serveAnticipation, owner: server, shot: .serve, position: snapshot.players[server]?.position, callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 0, persistsUntilLanding: true))
            case let .shotTransactionChanged(owner, elapsed, capped):
                state.cues.removeAll { $0.kind == .chargeMeter || $0.kind == .chargeCap }
                state.cues.append(TennisCue(kind: capped ? .chargeCap : .chargeMeter, owner: owner, shot: nil, position: snapshot.players[owner]?.position, callout: nil, elapsedMilliseconds: elapsed, minimumLifetimeMilliseconds: 0, persistsUntilLanding: true))
            case let .shotContact(owner, shot, landing, fullyCharged):
                state.cues.removeAll { $0.kind == .chargeMeter || $0.kind == .chargeCap || $0.kind == .serveAnticipation }
                state.cues.append(TennisCue(kind: .shotDirection, owner: owner, shot: shot, position: landing, callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 100, persistsUntilLanding: true))
                state.cues.append(TennisCue(kind: .landing, owner: owner, shot: shot, position: landing, callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 300, persistsUntilLanding: true))
                if fullyCharged { state.cues.append(TennisCue(kind: shot == .smash ? .smashStarburst : .smashFlash, owner: owner, shot: shot, position: landing, callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 100, persistsUntilLanding: false)) }
            case let .bounce(surface, shot, position):
                state.cues.removeAll { $0.persistsUntilLanding }
                let kind: TennisCueKind = surface == .hard ? .hardBounce : (surface == .clay ? .clayBounce : .grassBounce)
                state.cues.append(TennisCue(kind: kind, owner: nil, shot: shot, position: position, callout: nil, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 120, persistsUntilLanding: false))
            case let .fault(callout): state.cues.append(TennisCue(kind: .faultCallout, owner: nil, shot: nil, position: nil, callout: callout, elapsedMilliseconds: 0, minimumLifetimeMilliseconds: 1000, persistsUntilLanding: false))
            case .pointEnded, .matchEnded: state.cues.removeAll()
            }
        }
    }

    mutating func resetForServeWindup() { state.cues.removeAll() }
}
