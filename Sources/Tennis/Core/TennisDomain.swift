import Foundation

enum TennisSide: Hashable { case human, cpu }
enum TennisCourtEnd: Equatable { case near, far }
enum TennisSurface: CaseIterable, Equatable { case hard, clay, grass }
enum TennisShotType: Equatable { case serve, topspin, slice, flat, lob, drop, smash }
enum TennisContactQuality: Equatable { case perfect, good, poor }
enum TennisStatPreset: Equatable { case balanced, power }
enum TennisScreen: Equatable { case title, surfaceSelect, match, result }
enum TennisPointPhase: Equatable { case serveAnticipation, awaitingServeInput, rally, hitstop, ended }
enum TennisLiveBallPhase: Equatable { case serveFlight, rally, pointEnding }
enum TennisPointEndReason: Equatable { case secondBounce, netFault, outOfBounds, illegalServe }
enum TennisErrorClassification: Equatable { case none, forced, unforced }
enum TennisFaultCallout: Equatable { case fault, net, out }

struct TennisPoint: Equatable { var x: Int; var y: Int }
struct TennisRect: Equatable { var minX: Int; var minY: Int; var maxX: Int; var maxY: Int }

struct TennisGameConfiguration: Equatable {
    var tickMilliseconds: UInt64
    var openingServer: TennisSide
    var humanCourtEnd: TennisCourtEnd
    var humanServeBox: TennisRect
    var cpuServeBox: TennisRect
    var seed: UInt64

    static var approvedMVP: TennisGameConfiguration {
        TennisGameConfiguration(
            tickMilliseconds: 16,
            openingServer: .human,
            humanCourtEnd: .near,
            humanServeBox: TennisRect(minX: 16, minY: 40, maxX: 80, maxY: 56),
            cpuServeBox: TennisRect(minX: 80, minY: 88, maxX: 144, maxY: 104),
            seed: 1
        )
    }
}

struct TennisPlayerState: Equatable { var side: TennisSide; var courtEnd: TennisCourtEnd; var position: TennisPoint; var preset: TennisStatPreset }
struct TennisBallFlight: Equatable {
    var hitter: TennisSide; var receiver: TennisSide; var shot: TennisShotType; var contactQuality: TennisContactQuality
    var origin: TennisPoint; var landing: TennisPoint; var position: TennisPoint; var shadow: TennisPoint; var height: Int
    var elapsedMilliseconds: UInt64; var contactToBounceMilliseconds: UInt64; var responseWindowMilliseconds: UInt64
    var bounceHeight: Int; var skidDistance: Int; var hasCrossedNetPlane: Bool; var consecutiveGroundContacts: Int
}
struct TennisScore: Equatable { var human: Int; var cpu: Int }
struct TennisMatchSnapshot: Equatable {
    var surface: TennisSurface; var players: [TennisSide: TennisPlayerState]; var ball: TennisBallFlight?
    var score: TennisScore; var server: TennisSide; var phase: TennisPointPhase; var liveBallPhase: TennisLiveBallPhase?; var matchWinner: TennisSide?
}
enum TennisSimulationEvent: Equatable {
    case serveAnticipationStarted(TennisSide)
    case shotTransactionChanged(TennisSide, UInt64, Bool)
    case shotContact(TennisSide, TennisShotType, TennisPoint, Bool)
    case bounce(TennisSurface, TennisShotType, TennisPoint)
    case fault(TennisFaultCallout)
    case pointEnded(TennisSide, TennisPointEndReason)
    case matchEnded(TennisSide)
}
struct TennisTickResult: Equatable { var snapshot: TennisMatchSnapshot; var events: [TennisSimulationEvent] }

struct TennisSeededRandom {
    private(set) var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        state ^= state << 7; state ^= state >> 9; state ^= state << 8
        return Int(state % UInt64(upperBound))
    }
}
