import Foundation
import GameEngine
import SDL2

enum TennisShotButton: Hashable { case a, b }
enum TennisButtonEdge: Equatable { case pressed, released }
struct TennisShotButtonEvent: Equatable { var button: TennisShotButton; var edge: TennisButtonEdge }
struct TennisInputFrame: Equatable { var movement: TennisPoint; var pressedShotButtons: Set<TennisShotButton>; var shotEvents: [TennisShotButtonEvent]; var menuLeftPressed: Bool; var menuRightPressed: Bool; var menuAcceptPressed: Bool; var servePressed: Bool }
struct TennisShotTransaction: Equatable { var initiatingButton: TennisShotButton; var involvedButtons: Set<TennisShotButton>; var selectedShot: TennisShotType?; var elapsedSelectionMilliseconds: UInt64; var heldChargeMilliseconds: UInt64; var isChargeCapped: Bool }
struct TennisShotCommit: Equatable { var shot: TennisShotType; var chargedMilliseconds: UInt64; var fullyCharged: Bool }

final class TennisInputController: IEventListener {
    private var queuedShotEvents: [TennisShotButtonEvent] = []
    private var pressedButtons: Set<TennisShotButton> = []
    private var directionalState = TennisPoint(x: 0, y: 0)
    private var queuedMenuLeft = false; private var queuedMenuRight = false; private var queuedMenuAccept = false; private var queuedServe = false
    init() {}
    func onEvents(_ events: [SDL_Event]) {
        for event in events {
            let keyDown = UInt32(SDL_KEYDOWN.rawValue)
            let keyUp = UInt32(SDL_KEYUP.rawValue)
            let controllerAxisMotion: UInt32 = 0x650
            let controllerButtonDown: UInt32 = 0x651
            let controllerButtonUp: UInt32 = 0x652
            if event.type == controllerAxisMotion {
                if event.caxis.axis == 0 { directionalState.x = event.caxis.value < -8192 ? -1 : (event.caxis.value > 8192 ? 1 : 0) }
                if event.caxis.axis == 1 { directionalState.y = event.caxis.value < -8192 ? -1 : (event.caxis.value > 8192 ? 1 : 0) }
                continue
            }
            if event.type == controllerButtonDown || event.type == controllerButtonUp {
                let down = event.type == controllerButtonDown
                let button = event.cbutton.button
                if button == 11 || button == 12 || button == 13 || button == 14 {
                    if button == 11 { directionalState.y = down ? -1 : 0 }
                    if button == 12 { directionalState.y = down ? 1 : 0 }
                    if button == 13 { directionalState.x = down ? -1 : 0 }
                    if button == 14 { directionalState.x = down ? 1 : 0 }
                } else if button == 0 || button == 1 {
                    let shotButton: TennisShotButton = button == 0 ? .a : .b
                    if down {
                        if !pressedButtons.contains(shotButton) {
                            pressedButtons.insert(shotButton)
                            queuedShotEvents.append(TennisShotButtonEvent(button: shotButton, edge: .pressed))
                            queuedServe = true
                        }
                    } else if pressedButtons.remove(shotButton) != nil {
                        queuedShotEvents.append(TennisShotButtonEvent(button: shotButton, edge: .released))
                    }
                }
                continue
            }
            guard event.type == keyDown || event.type == keyUp else { continue }
            let down = event.type == keyDown
            let key = SDL_KeyCode(rawValue: SDL_KeyCode.RawValue(event.key.keysym.sym))
            if key == SDLK_j || key == SDLK_k {
                let button: TennisShotButton = key == SDLK_j ? .a : .b
                if down {
                    if !pressedButtons.contains(button) {
                        pressedButtons.insert(button)
                        queuedShotEvents.append(TennisShotButtonEvent(button: button, edge: .pressed))
                        queuedServe = true
                    }
                } else if pressedButtons.remove(button) != nil {
                    queuedShotEvents.append(TennisShotButtonEvent(button: button, edge: .released))
                }
            } else if down {
                switch key {
                case SDLK_w, SDLK_UP: directionalState.y = -1
                case SDLK_s, SDLK_DOWN: directionalState.y = 1
                case SDLK_a, SDLK_LEFT: directionalState.x = -1
                case SDLK_d, SDLK_RIGHT: directionalState.x = 1
                default: break
                }
            } else {
                switch key {
                case SDLK_w, SDLK_s, SDLK_UP, SDLK_DOWN: directionalState.y = 0
                case SDLK_a, SDLK_d, SDLK_LEFT, SDLK_RIGHT: directionalState.x = 0
                default: break
                }
            }
            if down && key == SDLK_LEFT { queuedMenuLeft = true }
            if down && key == SDLK_RIGHT { queuedMenuRight = true }
            if down && key == SDLK_RETURN { queuedMenuAccept = true }
        }
    }
    func consumeTick() -> TennisInputFrame { defer { queuedShotEvents.removeAll(); queuedMenuLeft = false; queuedMenuRight = false; queuedMenuAccept = false; queuedServe = false }; return TennisInputFrame(movement: directionalState, pressedShotButtons: pressedButtons, shotEvents: queuedShotEvents, menuLeftPressed: queuedMenuLeft, menuRightPressed: queuedMenuRight, menuAcceptPressed: queuedMenuAccept, servePressed: queuedServe) }
    func clearGameplayInput() { pressedButtons.removeAll(); queuedShotEvents.removeAll(); queuedServe = false }
}

struct TennisShotInputMachine {
    private(set) var transaction: TennisShotTransaction?
    private var buttonsAwaitingRelease: Set<TennisShotButton> = []
    mutating func advance(input: TennisInputFrame, elapsedMilliseconds: UInt64, contactOpportunity: Bool, smashEligible: Bool) -> TennisShotCommit? {
        for event in input.shotEvents where event.edge == .released { buttonsAwaitingRelease.remove(event.button) }
        if var current = transaction {
            current.elapsedSelectionMilliseconds += elapsedMilliseconds
            if current.selectedShot == nil {
                let secondPress = input.shotEvents.first {
                    $0.edge == .pressed && $0.button != current.initiatingButton
                }?.button
                if let secondPress {
                    current.involvedButtons.insert(secondPress)
                    if input.pressedShotButtons.contains(current.initiatingButton) {
                        current.selectedShot = smashEligible ? .smash : .flat
                    } else {
                        current.selectedShot = current.initiatingButton == .a ? .lob : .drop
                    }
                } else if input.shotEvents.contains(where: {
                    $0.edge == .released && $0.button == current.initiatingButton
                }) {
                    current.selectedShot = current.initiatingButton == .a ? .topspin : .slice
                    transaction = nil
                    buttonsAwaitingRelease = current.involvedButtons
                    return TennisShotCommit(shot: current.selectedShot!, chargedMilliseconds: 0, fullyCharged: false)
                } else if current.elapsedSelectionMilliseconds >= 350 {
                    current.selectedShot = current.initiatingButton == .a ? .topspin : .slice
                    if !input.pressedShotButtons.contains(current.initiatingButton) {
                        transaction = nil
                        buttonsAwaitingRelease = current.involvedButtons
                        return TennisShotCommit(shot: current.selectedShot!, chargedMilliseconds: 0, fullyCharged: false)
                    }
                }
            }
            if let shot = current.selectedShot {
                let isHoldingInvolvedButton = !current.involvedButtons.isDisjoint(with: input.pressedShotButtons)
                current.heldChargeMilliseconds = min(600, current.heldChargeMilliseconds + (isHoldingInvolvedButton ? elapsedMilliseconds : 0))
                current.isChargeCapped = current.heldChargeMilliseconds >= 600
                let released = input.shotEvents.contains { $0.edge == .released && current.involvedButtons.contains($0.button) }
                if released || contactOpportunity { transaction = nil; buttonsAwaitingRelease = current.involvedButtons; return TennisShotCommit(shot: shot, chargedMilliseconds: current.heldChargeMilliseconds, fullyCharged: current.isChargeCapped) }
            }
            transaction = current; return nil
        }
        guard buttonsAwaitingRelease.isEmpty else { return nil }
        guard !input.pressedShotButtons.isEmpty else { return nil }
        let both = input.pressedShotButtons.contains(.a) && input.pressedShotButtons.contains(.b)
        let button = input.pressedShotButtons.contains(.a) ? TennisShotButton.a : .b
        var new = TennisShotTransaction(initiatingButton: button, involvedButtons: both ? [.a, .b] : [button], selectedShot: both ? (smashEligible ? .smash : .flat) : nil, elapsedSelectionMilliseconds: 0, heldChargeMilliseconds: 0, isChargeCapped: false)
        if new.selectedShot == nil && contactOpportunity { return nil }
        transaction = new; return nil
    }
    mutating func cancelAndRequireRelease(_ pressedButtons: Set<TennisShotButton>) { transaction = nil; buttonsAwaitingRelease = pressedButtons }
    mutating func reset() { transaction = nil; buttonsAwaitingRelease.removeAll() }
}
