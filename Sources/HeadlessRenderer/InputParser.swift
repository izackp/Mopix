import Foundation
import SDL2

enum InputCommand {
    case wait(ticks: Int)
    case keyDown(keycode: SDL_Keycode, scancode: SDL_Scancode)
    case keyUp(keycode: SDL_Keycode, scancode: SDL_Scancode)
    case mouseMove(x: Int32, y: Int32)
    case mouseButton(x: Int32, y: Int32, down: Bool)
}

enum InputParseError: Error, LocalizedError {
    case unknownCommand(String)
    case missingArgument(String)
    case invalidArgument(String)

    var errorDescription: String? {
        switch self {
        case .unknownCommand(let s): return "Unknown input command: '\(s)'"
        case .missingArgument(let s): return "Missing argument for command: '\(s)'"
        case .invalidArgument(let s): return "Invalid argument: '\(s)'"
        }
    }
}

func parseInputCommands(_ input: String) throws -> [InputCommand] {
    guard !input.isEmpty else { return [] }
    var result: [InputCommand] = []
    let parts = input.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    for part in parts {
        let tokens = part.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard let verb = tokens.first?.uppercased() else { continue }
        switch verb {
        case "WAIT":
            guard tokens.count >= 2 else { throw InputParseError.missingArgument(part) }
            guard let n = Int(tokens[1]), n > 0 else { throw InputParseError.invalidArgument(tokens[1]) }
            result.append(.wait(ticks: n))
        case "PRESS":
            guard tokens.count >= 2 else { throw InputParseError.missingArgument(part) }
            let (kc, sc) = try resolveKey(tokens[1])
            result.append(.keyDown(keycode: kc, scancode: sc))
            result.append(.keyUp(keycode: kc, scancode: sc))
        case "KEYDOWN":
            guard tokens.count >= 2 else { throw InputParseError.missingArgument(part) }
            let (kc, sc) = try resolveKey(tokens[1])
            result.append(.keyDown(keycode: kc, scancode: sc))
        case "KEYUP":
            guard tokens.count >= 2 else { throw InputParseError.missingArgument(part) }
            let (kc, sc) = try resolveKey(tokens[1])
            result.append(.keyUp(keycode: kc, scancode: sc))
        case "MOUSE":
            guard tokens.count >= 3 else { throw InputParseError.missingArgument(part) }
            guard let x = Int32(tokens[1]), let y = Int32(tokens[2]) else { throw InputParseError.invalidArgument(part) }
            result.append(.mouseMove(x: x, y: y))
        case "CLICK":
            guard tokens.count >= 3 else { throw InputParseError.missingArgument(part) }
            guard let x = Int32(tokens[1]), let y = Int32(tokens[2]) else { throw InputParseError.invalidArgument(part) }
            result.append(.mouseMove(x: x, y: y))
            result.append(.mouseButton(x: x, y: y, down: true))
            result.append(.mouseButton(x: x, y: y, down: false))
        default:
            throw InputParseError.unknownCommand(verb)
        }
    }
    return result
}

// Expand wait commands into a per-tick array: index = tick (1-based), value = commands to inject
func buildTimeline(from commands: [InputCommand]) -> [Int: [InputCommand]] {
    var timeline: [Int: [InputCommand]] = [:]
    var tick = 1
    for cmd in commands {
        switch cmd {
        case .wait(let n):
            tick += n
        default:
            timeline[tick, default: []].append(cmd)
        }
    }
    return timeline
}

private func resolveKey(_ name: String) throws -> (SDL_Keycode, SDL_Scancode) {
    switch name.uppercased() {
    case "UP":     return (SDL_Keycode(SDLK_UP.rawValue), SDL_Scancode(rawValue: 82))
    case "DOWN":   return (SDL_Keycode(SDLK_DOWN.rawValue), SDL_Scancode(rawValue: 81))
    case "LEFT":   return (SDL_Keycode(SDLK_LEFT.rawValue), SDL_Scancode(rawValue: 80))
    case "RIGHT":  return (SDL_Keycode(SDLK_RIGHT.rawValue), SDL_Scancode(rawValue: 79))
    case "SPACE":  return (SDL_Keycode(SDLK_SPACE.rawValue), SDL_Scancode(rawValue: 44))
    case "RETURN", "ENTER": return (SDL_Keycode(SDLK_RETURN.rawValue), SDL_Scancode(rawValue: 40))
    case "ESCAPE": return (SDL_Keycode(SDLK_ESCAPE.rawValue), SDL_Scancode(rawValue: 41))
    default:
        if name.count == 1, let char = name.lowercased().unicodeScalars.first {
            let kc = SDL_Keycode(Int32(char.value))
            let sc = SDL_Scancode(rawValue: 0) // best-effort; scancode 0 = unknown
            return (kc, sc)
        }
        // Digits 0-9
        if name.count == 1, let _ = Int(name) {
            let kc = SDL_Keycode(Int32(name.unicodeScalars.first!.value))
            return (kc, SDL_Scancode(rawValue: 0))
        }
        throw InputParseError.unknownCommand(name)
    }
}
