import XCTest
import GameEngine
import SDL2
@testable import TennisGame

final class TennisKeyboardFocusLifecycleTests: XCTestCase {
    private func keyEvent(_ key: SDL_KeyCode, down: Bool) -> SDL_Event {
        var event = SDL_Event()
        event.type = UInt32(down ? SDL_KEYDOWN.rawValue : SDL_KEYUP.rawValue)
        event.key.keysym.sym = SDL_Keycode(key.rawValue)
        return event
    }

    private func windowEvent(_ id: SDL_WindowEventID) -> SDL_Event {
        var event = SDL_Event()
        event.type = SDL_WINDOWEVENT.rawValue
        event.window.event = UInt8(id.rawValue)
        return event
    }

    private func mouseDownEvent() -> SDL_Event {
        var event = SDL_Event()
        event.type = SDL_MOUSEBUTTONDOWN.rawValue
        return event
    }

    // MARK: Repeat suppression

    func testHoldingAShotButtonProducesOnePressEdgeAndOneServe() {
        let controller = TennisInputController(windowActive: true, keyboardFocused: true)
        controller.onEvents([keyEvent(SDLK_j, down: true), keyEvent(SDLK_j, down: true), keyEvent(SDLK_j, down: true)])
        let frame = controller.consumeTick()
        XCTAssertEqual(frame.shotEvents, [TennisShotButtonEvent(button: .a, edge: .pressed)])
        XCTAssertTrue(frame.servePressed)

        controller.onEvents([keyEvent(SDLK_j, down: true), keyEvent(SDLK_j, down: true)])
        let held = controller.consumeTick()
        XCTAssertTrue(held.shotEvents.isEmpty, "repeated key-down while held must not re-arm a press edge")
        XCTAssertFalse(held.servePressed, "a held launch input must not launch another serve")
    }

    func testHoldingAMovementKeyProducesSteadyMovementWithoutRestarting() {
        let controller = TennisInputController(windowActive: true, keyboardFocused: true)
        controller.onEvents([keyEvent(SDLK_d, down: true)])
        XCTAssertEqual(controller.consumeTick().movement, TennisPoint(x: 1, y: 0))
        controller.onEvents([keyEvent(SDLK_d, down: true)])
        XCTAssertEqual(controller.consumeTick().movement, TennisPoint(x: 1, y: 0))
        controller.onEvents([keyEvent(SDLK_d, down: false)])
        XCTAssertEqual(controller.consumeTick().movement, TennisPoint(x: 0, y: 0))
    }

    // MARK: Window-active vs surface-focus

    func testWindowActiveAndSurfaceFocusAreIndependentAxes() {
        let controller = TennisInputController(windowActive: true, keyboardFocused: false)
        var frame = controller.consumeTick()
        XCTAssertTrue(frame.windowActive)
        XCTAssertFalse(frame.keyboardFocused)

        controller.onEvents([mouseDownEvent()])
        frame = controller.consumeTick()
        XCTAssertTrue(frame.keyboardFocused)

        controller.onEvents([windowEvent(SDL_WINDOWEVENT_FOCUS_LOST)])
        frame = controller.consumeTick()
        XCTAssertFalse(frame.windowActive)
        XCTAssertFalse(frame.keyboardFocused)

        controller.onEvents([windowEvent(SDL_WINDOWEVENT_FOCUS_GAINED)])
        frame = controller.consumeTick()
        XCTAssertTrue(frame.windowActive, "window can become active again")
        XCTAssertFalse(frame.keyboardFocused, "surface focus does not return without a fresh pointer activation")
    }

    func testUnfocusedSurfaceIgnoresKeyboardInput() {
        let controller = TennisInputController(windowActive: true, keyboardFocused: false)
        controller.onEvents([keyEvent(SDLK_j, down: true)])
        let frame = controller.consumeTick()
        XCTAssertTrue(frame.shotEvents.isEmpty)
        XCTAssertFalse(frame.servePressed)
        XCTAssertEqual(frame.movement, TennisPoint(x: 0, y: 0))
    }

    // MARK: Menu edges

    func testMenuLeftRightAcceptFireOnlyOnFreshPress() {
        let controller = TennisInputController(windowActive: true, keyboardFocused: true)
        controller.onEvents([keyEvent(SDLK_RIGHT, down: true)])
        var frame = controller.consumeTick()
        XCTAssertTrue(frame.menuRightPressed)
        controller.onEvents([keyEvent(SDLK_RIGHT, down: true)])
        frame = controller.consumeTick()
        XCTAssertFalse(frame.menuRightPressed, "held right must not repeat the menu edge")

        controller.onEvents([keyEvent(SDLK_RIGHT, down: false), keyEvent(SDLK_RETURN, down: true)])
        frame = controller.consumeTick()
        XCTAssertTrue(frame.menuAcceptPressed)
    }

    // MARK: Serve/shot/charge cancellation on focus loss

    func testFocusLossCancelsInFlightHumanShotTransactionWithoutAlteringScoreOrPhase() {
        // approvedMVP opens with the human serving, so once the serve is live the human is the
        // hitter (not the current receiver) and can pre-arm a return transaction while waiting.
        var simulation = TennisSimulation(surface: .hard, configuration: .approvedMVP)
        let empty = TennisInputFrame(movement: .init(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        _ = simulation.advance(input: empty)
        let serve = TennisInputFrame(movement: .init(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: true)
        _ = simulation.advance(input: serve)
        XCTAssertEqual(simulation.snapshot.phase, .rally)

        let armTransaction = TennisInputFrame(movement: .init(x: 0, y: 0), pressedShotButtons: [.a], shotEvents: [.init(button: .a, edge: .pressed)], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false)
        _ = simulation.advance(input: armTransaction)
        let scoreBefore = simulation.snapshot.score

        let focusLost = TennisInputFrame(movement: .init(x: 0, y: 0), pressedShotButtons: [], shotEvents: [], menuLeftPressed: false, menuRightPressed: false, menuAcceptPressed: false, servePressed: false, keyboardFocusLost: true)
        let cancelTick = simulation.advance(input: focusLost)

        XCTAssertTrue(cancelTick.events.contains(.shotTransactionCancelled(.human)), "terminal events: \(cancelTick.events)")
        XCTAssertEqual(simulation.snapshot.score, scoreBefore, "focus loss must not alter scoring")
        XCTAssertEqual(cancelTick.snapshot.phase, .rally, "focus loss must not change the current screen/phase")
        XCTAssertNotNil(cancelTick.snapshot.ball, "focus loss must not commit, cancel, or otherwise end the live rally")
    }

    func testInputControllerFocusLossClearsHeldStateAndReportsKeyboardFocusLost() {
        let controller = TennisInputController(windowActive: true, keyboardFocused: true)
        controller.onEvents([keyEvent(SDLK_d, down: true), keyEvent(SDLK_j, down: true)])
        _ = controller.consumeTick()

        controller.onEvents([windowEvent(SDL_WINDOWEVENT_FOCUS_LOST)])
        let lostFrame = controller.consumeTick()
        XCTAssertTrue(lostFrame.keyboardFocusLost)
        XCTAssertEqual(lostFrame.movement, TennisPoint(x: 0, y: 0))
        XCTAssertTrue(lostFrame.pressedShotButtons.isEmpty)

        let nextFrame = controller.consumeTick()
        XCTAssertFalse(nextFrame.keyboardFocusLost, "focus-lost is a one-tick edge, not sticky state")
    }

    // MARK: Regain with a held key

    func testRegainingFocusWithAPhysicallyHeldKeyRequiresAFreshPress() {
        let controller = TennisInputController(windowActive: true, keyboardFocused: true)
        controller.onEvents([keyEvent(SDLK_j, down: true)])
        _ = controller.consumeTick()

        controller.onEvents([windowEvent(SDL_WINDOWEVENT_FOCUS_LOST), windowEvent(SDL_WINDOWEVENT_FOCUS_GAINED), mouseDownEvent()])
        let regainFrame = controller.consumeTick()
        XCTAssertTrue(regainFrame.shotEvents.isEmpty, "a key already held when focus returns must not replay a press")
        XCTAssertFalse(regainFrame.servePressed)
        XCTAssertTrue(regainFrame.keyboardFocused)

        controller.onEvents([keyEvent(SDLK_j, down: false), keyEvent(SDLK_j, down: true)])
        let freshPress = controller.consumeTick()
        XCTAssertEqual(freshPress.shotEvents, [TennisShotButtonEvent(button: .a, edge: .pressed)])
        XCTAssertTrue(freshPress.servePressed)
    }

    // MARK: Unmapped / system-modified keys

    func testUnmappedKeyProducesNoMovementOrShotAction() {
        let controller = TennisInputController(windowActive: true, keyboardFocused: true)
        controller.onEvents([keyEvent(SDLK_q, down: true)])
        let frame = controller.consumeTick()
        XCTAssertEqual(frame.movement, TennisPoint(x: 0, y: 0))
        XCTAssertTrue(frame.pressedShotButtons.isEmpty)
        XCTAssertTrue(frame.shotEvents.isEmpty)
        XCTAssertFalse(frame.servePressed)
    }

    // MARK: Cue visibility per screen

    func testClickGameForKeysCueAppearsOnEachScreenWhenUnfocusedAndClearsWhenFocused() async throws {
        let pair = InProcessTransport.makePair()
        pair.server.handler = { message in
            switch message {
            case let .connect(requestId, _, _, _, _):
                await pair.server.send(.response(Response(requestId: requestId, status: .ok)))
            case let .loadResource(requestId, _, kind, _, preferredHandle):
                if kind == .font {
                    await pair.server.send(.response(Response(requestId: requestId, status: .ok, body: .font(handle: preferredHandle ?? 77, family: "test"))))
                }
            default:
                break
            }
        }
        let client = DisplayClient(transport: pair.client, logicalSize: Size(160, 144))
        try await client.connect(name: "TennisKeyboardFocusLifecycleTests", version: 1, logicalSize: Size(160, 144))
        let renderClient = DisplayRenderClient(displayClient: client, windowSize: Size<Int16>(160, 144))
        let renderer = TennisRenderer(fontURL: URL(string: "vd://test-font")!)
        try await renderer.loadResources(using: client)
        let presentation = TennisPresentationState(cues: [], players: [:], ball: nil)

        for screen: TennisScreen in [.title, .surfaceSelect, .match, .result] {
            renderClient.clearCommands()
            let unfocused = TennisFlowState(screen: screen, highlightedSurface: .hard, result: screen == .result ? .human : nil, windowActive: true, keyboardFocused: false)
            try renderer.draw(flow: unfocused, match: nil, presentation: presentation, humanServeBox: TennisGameConfiguration.approvedMVP.humanServeBox, cpuServeBox: TennisGameConfiguration.approvedMVP.cpuServeBox, using: renderClient)
            XCTAssertTrue(containsCueText(renderClient), "expected CLICK GAME FOR KEYS cue on \(screen) while unfocused")

            renderClient.clearCommands()
            let focused = TennisFlowState(screen: screen, highlightedSurface: .hard, result: screen == .result ? .human : nil, windowActive: true, keyboardFocused: true)
            try renderer.draw(flow: focused, match: nil, presentation: presentation, humanServeBox: TennisGameConfiguration.approvedMVP.humanServeBox, cpuServeBox: TennisGameConfiguration.approvedMVP.cpuServeBox, using: renderClient)
            XCTAssertFalse(containsCueText(renderClient), "cue must clear once focused on \(screen)")
        }
    }

    // MARK: VirtualController tick/reset behavior

    func testVirtualControllerFinishTickAdvancesBaselineForEdgeDetection() {
        let controller = VirtualController(clientId: 0, deviceId: 0, state: .blank, statePrevious: .blank)
        controller.pushCommandList(InputCommandList(clientId: 0, deviceId: 0, commands: [InputCommand(id: CommandId.action.rawValue, value: 1)]))
        XCTAssertTrue(controller.state.buttons.contains(.action))
        XCTAssertFalse(controller.statePrevious.buttons.contains(.action))
        controller.finishTick()
        XCTAssertTrue(controller.statePrevious.buttons.contains(.action), "finishTick must commit state as the next tick's baseline")

        controller.pushCommandList(InputCommandList(clientId: 0, deviceId: 0, commands: []))
        XCTAssertTrue(controller.state.buttons.contains(.action), "an empty command list must not clear already-held buttons")
        XCTAssertTrue(controller.statePrevious.buttons.contains(.action), "no new edge should appear while the button stays held")
    }

    func testVirtualControllerResetClearsCurrentAndPreviousState() {
        let controller = VirtualController(clientId: 0, deviceId: 0, state: .blank, statePrevious: .blank)
        controller.pushCommandList(InputCommandList(clientId: 0, deviceId: 0, commands: [InputCommand(id: CommandId.action.rawValue, value: 1)]))
        controller.finishTick()
        controller.reset()
        XCTAssertEqual(controller.state.buttons, PressedControllerButtons(rawValue: 0))
        XCTAssertEqual(controller.statePrevious.buttons, PressedControllerButtons(rawValue: 0))
    }

    private func containsCueText(_ renderer: DisplayRenderClient) -> Bool {
        let commands = Mirror(reflecting: renderer).children.first { $0.label == "cmdList" }?.value as? [DrawCmd]
        return commands?.contains { if case .text(_, let content, _, _) = $0.type { return content == "CLICK GAME FOR KEYS" }; return false } ?? false
    }
}
