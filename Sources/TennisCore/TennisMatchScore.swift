public struct TennisMatchScore: Equatable {
    public let humanPoints: Int
    public let cpuPoints: Int
    public let server: TennisSide
    public let pointsSinceServerRotation: Int
    public let matchWinner: TennisSide?

    public init(
        humanPoints: Int,
        cpuPoints: Int,
        server: TennisSide,
        pointsSinceServerRotation: Int = 0,
        matchWinner: TennisSide? = nil
    ) {
        self.humanPoints = max(0, humanPoints)
        self.cpuPoints = max(0, cpuPoints)
        self.server = server
        self.pointsSinceServerRotation = max(0, pointsSinceServerRotation)
        self.matchWinner = matchWinner
    }
}

public struct TennisMatchResolution: Equatable {
    public let pointWinner: TennisSide
    public let score: TennisMatchScore
    public let matchWinner: TennisSide?

    public init(pointWinner: TennisSide, score: TennisMatchScore, matchWinner: TennisSide?) {
        self.pointWinner = pointWinner
        self.score = score
        self.matchWinner = matchWinner
    }
}

public final class TennisMatchScorekeeper {
    public private(set) var score: TennisMatchScore

    public init(initialServer: TennisSide) {
        score = TennisMatchScore(humanPoints: 0, cpuPoints: 0, server: initialServer)
    }

    public func reset(server: TennisSide) {
        score = TennisMatchScore(humanPoints: 0, cpuPoints: 0, server: server)
    }

    public func recordPoint(winner: TennisSide) -> TennisMatchResolution {
        let nextScore = incrementedScore(for: winner)
        score = nextScore
        return TennisMatchResolution(pointWinner: winner, score: nextScore, matchWinner: nextScore.matchWinner)
    }

    private func incrementedScore(for winner: TennisSide) -> TennisMatchScore {
        let humanPoints = score.humanPoints + (winner == .human ? 1 : 0)
        let cpuPoints = score.cpuPoints + (winner == .cpu ? 1 : 0)
        let completedPoints = score.pointsSinceServerRotation + 1
        let server = completedPoints >= 2 ? (score.server == .human ? .cpu : .human) : score.server
        let rotationCount = completedPoints >= 2 ? 0 : completedPoints
        let provisional = TennisMatchScore(
            humanPoints: humanPoints,
            cpuPoints: cpuPoints,
            server: server,
            pointsSinceServerRotation: rotationCount
        )
        return TennisMatchScore(
            humanPoints: provisional.humanPoints,
            cpuPoints: provisional.cpuPoints,
            server: provisional.server,
            pointsSinceServerRotation: provisional.pointsSinceServerRotation,
            matchWinner: matchWinner(for: provisional)
        )
    }

    private func matchWinner(for score: TennisMatchScore) -> TennisSide? {
        if score.humanPoints >= 11 && score.humanPoints - score.cpuPoints >= 2 { return .human }
        if score.cpuPoints >= 11 && score.cpuPoints - score.humanPoints >= 2 { return .cpu }
        return nil
    }
}
