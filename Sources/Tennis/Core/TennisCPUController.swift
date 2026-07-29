import Foundation

struct TennisCPUTacticalContext: Equatable { var cpu: TennisPlayerState; var human: TennisPlayerState; var ball: TennisBallFlight; var contactQuality: TennisContactQuality?; var isLegalReturnOpportunity: Bool }
struct TennisCPUShotPlan: Equatable { var shot: TennisShotType; var target: TennisPoint; var chargeMilliseconds: UInt64 }
enum TennisCPUAction: Equatable { case transactionChanged(TennisShotType, UInt64, Bool); case commit(TennisCPUShotPlan) }
struct TennisCPUOutput: Equatable { var movement: TennisPoint; var actions: [TennisCPUAction] }

struct TennisCPUController {
    private var reactionElapsedMilliseconds: UInt64
    private var chargeElapsedMilliseconds: UInt64
    private var pendingPlan: TennisCPUShotPlan?
    private var rallyContacts: Int
    private var plannedErrorContact: Int

    init() { reactionElapsedMilliseconds = 0; chargeElapsedMilliseconds = 0; pendingPlan = nil; rallyContacts = 0; plannedErrorContact = 7 }

    mutating func resetForPoint(random: inout TennisSeededRandom) {
        reactionElapsedMilliseconds = 0
        chargeElapsedMilliseconds = 0
        pendingPlan = nil
        rallyContacts = 0
        plannedErrorContact = 6 + random.nextInt(upperBound: 3)
    }

    mutating func advance(context: TennisCPUTacticalContext, elapsedMilliseconds: UInt64, rules: TennisRules) -> TennisCPUOutput {
        let dx = context.ball.landing.x - context.cpu.position.x
        let dy = context.ball.landing.y - context.cpu.position.y
        let movement = TennisPoint(x: dx == 0 ? 0 : (dx < 0 ? -1 : 1), y: dy == 0 ? 0 : (dy < 0 ? -1 : 1))
        reactionElapsedMilliseconds += elapsedMilliseconds
        if let plan = pendingPlan {
            chargeElapsedMilliseconds = min(plan.chargeMilliseconds, chargeElapsedMilliseconds + elapsedMilliseconds)
            if chargeElapsedMilliseconds >= plan.chargeMilliseconds {
                pendingPlan = nil
                chargeElapsedMilliseconds = 0
                rallyContacts += 1
                return TennisCPUOutput(movement: movement, actions: [.commit(plan)])
            }
            return TennisCPUOutput(movement: movement, actions: [.transactionChanged(plan.shot, chargeElapsedMilliseconds, chargeElapsedMilliseconds >= 600)])
        }
        guard context.isLegalReturnOpportunity, reactionElapsedMilliseconds >= 350 else { return TennisCPUOutput(movement: movement, actions: []) }
        let horizontal = abs(context.human.position.x - context.cpu.position.x) / 8
        let depth = abs(context.human.position.y - 72) / 8
        let shot: TennisShotType
        let charge: UInt64
        if context.ball.height >= 12 && (context.contactQuality == .perfect || context.contactQuality == .good) { shot = .smash; charge = 600 }
        else if depth <= 3 { shot = .lob; charge = 350 }
        else if depth > 5 { shot = .drop; charge = 250 }
        else if context.contactQuality == .poor || context.ball.height <= 6 { shot = .slice; charge = 150 }
        else if horizontal > 4 && (context.contactQuality == .perfect || context.contactQuality == .good) { shot = .flat; charge = 450 }
        else { shot = .topspin; charge = 200 }
        reactionElapsedMilliseconds = 0
        let target = rallyContacts >= plannedErrorContact
            ? TennisPoint(x: 0, y: context.human.courtEnd == .near ? 96 : 48)
            : TennisPoint(x: context.human.position.x >= 80 ? 24 : 136, y: context.human.courtEnd == .near ? 96 : 48)
        pendingPlan = TennisCPUShotPlan(shot: shot, target: target, chargeMilliseconds: charge)
        return TennisCPUOutput(movement: movement, actions: [.transactionChanged(shot, 0, false)])
    }
}
