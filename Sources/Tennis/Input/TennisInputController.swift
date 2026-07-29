import Foundation
import GameEngine
import SDL2

enum TennisShotButton: Hashable { case a, b }
enum TennisButtonEdge: Equatable { case pressed, released }
struct TennisShotButtonEvent: Equatable { var button: TennisShotButton; var edge: TennisButtonEdge }
struct TennisInputFrame: Equatable {
    var movement: TennisPoint
    var pressedShotButtons: Set<TennisShotButton>
    var shotEvents: [TennisShotButtonEvent]
    var menuLeftPressed: Bool
    var menuRightPressed: Bool
    var menuAcceptPressed: Bool
    var servePressed: Bool
    var windowActive: Bool = true
    var keyboardFocused: Bool = true
    var keyboardFocusLost: Bool = false
}
struct TennisShotTransaction: Equatable { var initiatingButton: TennisShotButton; var involvedButtons: Set<TennisShotButton>; var selectedShot: TennisShotType?; var elapsedSelectionMilliseconds: UInt64; var heldChargeMilliseconds: UInt64; var isChargeCapped: Bool }
struct TennisShotCommit: Equatable { var shot: TennisShotType; var chargedMilliseconds: UInt64; var fullyCharged: Bool }

/// Movement, menu, and shot-button state derive from `VirtualController.state` versus
/// `statePrevious` each tick, so held-vs-fresh-press logic lives in one place (`Commands.swift`)
/// instead of a second hand-rolled pressed-set here.
final class TennisInputController: IEventListener {
    private let virtualController: VirtualController
    private var queuedShotEvents: [TennisShotButtonEvent] = []
    private var windowActive: Bool
    private var keyboardFocused: Bool
    private var queuedKeyboardFocusLost: Bool = false
    private var pendingCommands: [InputCommand] = []

    init(windowActive: Bool, keyboardFocused: Bool) {
        self.windowActive = windowActive
        self.keyboardFocused = keyboardFocused
        virtualController = VirtualController(clientId: 0, deviceId: 0, state: .blank, statePrevious: .blank)
    }

    func onEvents(_ events: [SDL_Event]) {
        for event in events {
            if event.type == SDL_WINDOWEVENT.rawValue {
                switch SDL_WindowEventID(rawValue: SDL_WindowEventID.RawValue(event.window.event)) {
                case SDL_WINDOWEVENT_FOCUS_GAINED:
                    windowActive = true
                case SDL_WINDOWEVENT_FOCUS_LOST:
                    windowActive = false
                    if keyboardFocused { queuedKeyboardFocusLost = true }
                    keyboardFocused = false
                    virtualController.reset()
                    pendingCommands.removeAll()
                default: break
                }
                continue
            }
            if event.type == SDL_MOUSEBUTTONDOWN.rawValue {
                // Pointer activation grants surface focus; it is never itself a tennis press.
                windowActive = true
                keyboardFocused = true
                continue
            }
            guard windowActive && keyboardFocused else { continue }
            if let command = inputCommand(for: event) { pendingCommands.append(command) }
        }
    }

    func consumeTick() -> TennisInputFrame {
        virtualController.pushCommandList(InputCommandList(clientId: 0, deviceId: 0, commands: pendingCommands))
        pendingCommands.removeAll()

        let current = virtualController.state.buttons
        let previous = virtualController.statePrevious.buttons

        for (shotButton, pressedButton): (TennisShotButton, PressedControllerButtons) in [(.a, .action), (.b, .action2)] {
            let isDown = current.contains(pressedButton)
            let wasDown = previous.contains(pressedButton)
            if isDown && !wasDown { queuedShotEvents.append(TennisShotButtonEvent(button: shotButton, edge: .pressed)) }
            if !isDown && wasDown { queuedShotEvents.append(TennisShotButtonEvent(button: shotButton, edge: .released)) }
        }
        let servePressed = (current.contains(.action) && !previous.contains(.action)) || (current.contains(.action2) && !previous.contains(.action2))
        let menuLeftPressed = current.contains(.dpadLeft) && !previous.contains(.dpadLeft)
        let menuRightPressed = current.contains(.dpadRight) && !previous.contains(.dpadRight)
        let menuAcceptPressed = current.contains(.start) && !previous.contains(.start)

        var pressedShotButtons: Set<TennisShotButton> = []
        if current.contains(.action) { pressedShotButtons.insert(.a) }
        if current.contains(.action2) { pressedShotButtons.insert(.b) }

        let frame = TennisInputFrame(
            movement: movement(),
            pressedShotButtons: pressedShotButtons,
            shotEvents: queuedShotEvents,
            menuLeftPressed: menuLeftPressed,
            menuRightPressed: menuRightPressed,
            menuAcceptPressed: menuAcceptPressed,
            servePressed: servePressed,
            windowActive: windowActive,
            keyboardFocused: keyboardFocused,
            keyboardFocusLost: queuedKeyboardFocusLost
        )
        queuedShotEvents.removeAll()
        queuedKeyboardFocusLost = false
        virtualController.finishTick()
        return frame
    }

    func clearGameplayInput() {
        virtualController.reset()
        pendingCommands.removeAll()
        queuedShotEvents.removeAll()
    }

    private func inputCommand(for event: SDL_Event) -> InputCommand? {
        let controllerAxisMotion: UInt32 = 0x650
        let controllerButtonDown: UInt32 = 0x651
        let controllerButtonUp: UInt32 = 0x652
        if event.type == controllerAxisMotion {
            if event.caxis.axis == 0 { return InputCommand(id: CommandId.btnLStickX.rawValue, value: event.caxis.value) }
            if event.caxis.axis == 1 { return InputCommand(id: CommandId.btnLStickY.rawValue, value: event.caxis.value) }
            return nil
        }
        if event.type == controllerButtonDown || event.type == controllerButtonUp {
            let down = event.type == controllerButtonDown
            switch event.cbutton.button {
            case 11: return InputCommand(id: CommandId.dpadUp.rawValue, value: down ? 1 : 0)
            case 12: return InputCommand(id: CommandId.dpadDown.rawValue, value: down ? 1 : 0)
            case 13: return InputCommand(id: CommandId.dpadLeft.rawValue, value: down ? 1 : 0)
            case 14: return InputCommand(id: CommandId.dpadRight.rawValue, value: down ? 1 : 0)
            case 0: return InputCommand(id: CommandId.action.rawValue, value: down ? 1 : 0)
            case 1: return InputCommand(id: CommandId.action2.rawValue, value: down ? 1 : 0)
            default: return nil
            }
        }
        let keyDown = UInt32(SDL_KEYDOWN.rawValue)
        let keyUp = UInt32(SDL_KEYUP.rawValue)
        guard event.type == keyDown || event.type == keyUp else { return nil }
        let down = event.type == keyDown
        let key = SDL_KeyCode(rawValue: SDL_KeyCode.RawValue(event.key.keysym.sym))
        switch key {
        case SDLK_w, SDLK_UP: return InputCommand(id: CommandId.dpadUp.rawValue, value: down ? 1 : 0)
        case SDLK_s, SDLK_DOWN: return InputCommand(id: CommandId.dpadDown.rawValue, value: down ? 1 : 0)
        case SDLK_a, SDLK_LEFT: return InputCommand(id: CommandId.dpadLeft.rawValue, value: down ? 1 : 0)
        case SDLK_d, SDLK_RIGHT: return InputCommand(id: CommandId.dpadRight.rawValue, value: down ? 1 : 0)
        case SDLK_j: return InputCommand(id: CommandId.action.rawValue, value: down ? 1 : 0)
        case SDLK_k: return InputCommand(id: CommandId.action2.rawValue, value: down ? 1 : 0)
        case SDLK_RETURN: return InputCommand(id: CommandId.start.rawValue, value: down ? 1 : 0)
        default: return nil
        }
    }

    private func movement() -> TennisPoint {
        let buttons = virtualController.state.buttons
        var x = 0; var y = 0
        if buttons.contains(.dpadLeft) { x = -1 }
        if buttons.contains(.dpadRight) { x = 1 }
        if buttons.contains(.dpadUp) { y = -1 }
        if buttons.contains(.dpadDown) { y = 1 }
        if x == 0, let stickX = virtualController.state.analogValues[.btnLStickX] {
            if stickX < -8192 { x = -1 } else if stickX > 8192 { x = 1 }
        }
        if y == 0, let stickY = virtualController.state.analogValues[.btnLStickY] {
            if stickY < -8192 { y = -1 } else if stickY > 8192 { y = 1 }
        }
        return TennisPoint(x: x, y: y)
    }
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
