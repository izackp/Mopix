//
//  Commands.swift
//  TestGame
//
//  Created by Isaac Paul on 5/11/22.
//

import Foundation

class CommandMapper {
    
}

class CommandRouter {
    
}


//Note: Doesn't this get packed anyways? (Packing only compresses down to byte not bit
public struct PressedControllerButtons : OptionSet {
    public let rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public static let back      = PressedControllerButtons(rawValue: 1 << ButtonId.back.index)
    public static let action    = PressedControllerButtons(rawValue: 1 << ButtonId.action.index)
    public static let action2   = PressedControllerButtons(rawValue: 1 << ButtonId.action2.index)
    public static let action3   = PressedControllerButtons(rawValue: 1 << ButtonId.action3.index)
    public static let action4   = PressedControllerButtons(rawValue: 1 << ButtonId.action4.index)
    public static let action5   = PressedControllerButtons(rawValue: 1 << ButtonId.action5.index)
    public static let start     = PressedControllerButtons(rawValue: 1 << ButtonId.start.index)
    public static let select    = PressedControllerButtons(rawValue: 1 << ButtonId.select.index)
    public static let l3        = PressedControllerButtons(rawValue: 1 << ButtonId.l3.index)
    public static let r3        = PressedControllerButtons(rawValue: 1 << ButtonId.r3.index)
    public static let home      = PressedControllerButtons(rawValue: 1 << ButtonId.home.index)
    public static let dpadLeft  = PressedControllerButtons(rawValue: 1 << ButtonId.dpadLeft.index)
    public static let dpadRight = PressedControllerButtons(rawValue: 1 << ButtonId.dpadRight.index)
    public static let dpadUp    = PressedControllerButtons(rawValue: 1 << ButtonId.dpadUp.index)
    public static let dpadDown  = PressedControllerButtons(rawValue: 1 << ButtonId.dpadDown.index)
}

public enum ButtonId: Int, ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = ButtonId(rawValue: value) ?? ButtonId.unknown
    }
    
    public typealias IntegerLiteralType = Int
    
    case action // Accept
    case action2
    case action3
    case action4
    case action5
    
    case back // Cancel
    case start
    case select
    case l3
    case r3
    
    case home //Guide
    case dpadLeft
    case dpadRight
    case dpadUp
    case dpadDown
    
    case leftShoulder
    case leftShoulder2
    case rightShoulder
    case rightShoulder2
    
    case unknown
    
    public var index: Int {
        return rawValue
    }
    
    public var command: CommandId {
        switch self {
        case .action: return CommandId.action
        case .action2: return CommandId.action2
        case .action3: return CommandId.action3
        case .action4: return CommandId.action4
        case .action5: return CommandId.action5
        case .back: return CommandId.back
        case .dpadDown: return CommandId.dpadDown
        case .dpadLeft: return CommandId.dpadLeft
        case .dpadRight: return CommandId.dpadRight
        case .dpadUp: return CommandId.dpadUp
        case .home: return CommandId.home
        case .l3: return CommandId.l3
        case .leftShoulder: return CommandId.leftShoulder
        case .leftShoulder2: return CommandId.leftShoulder2
        case .r3: return CommandId.r3
        case .rightShoulder: return CommandId.rightShoulder
        case .rightShoulder2: return CommandId.rightShoulder2
        case .select: return CommandId.select
        case .start: return CommandId.start
        case .unknown: return CommandId.unknown
        }
    }
}

public enum AnalogId: Int, ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = AnalogId(rawValue: value) ?? AnalogId.unknown
    }
    
    public typealias IntegerLiteralType = Int
    
    case leftShoulder
    case leftShoulder2
    case rightShoulder
    case rightShoulder2
    
    case btnLStickX
    case btnLStickY
    case btnRStickX
    case btnRStickY
    case unknown
    
    public var index: Int {
        return rawValue
    }
    
    public var command: CommandId {
        switch self {
        case .btnLStickX: return CommandId.btnLStickX
        case .btnLStickY: return CommandId.btnLStickY
        case .btnRStickX: return CommandId.btnRStickX
        case .btnRStickY: return CommandId.btnRStickY
        case .leftShoulder: return CommandId.leftShoulder
        case .leftShoulder2: return CommandId.leftShoulder2
        case .rightShoulder: return CommandId.rightShoulder
        case .rightShoulder2: return CommandId.rightShoulder2
        case .unknown: return CommandId.unknown
        }
    }
}


public enum CommandId: UInt32, ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt32) {
        self = CommandId(rawValue: value) ?? CommandId.unknown
    }
    
    public typealias IntegerLiteralType = UInt32
    
    case action // Accept
    case action2
    case action3
    case action4
    case action5
    
    case back // Cancel
    case start
    case select
    case l3
    case r3
    
    case home //Guide
    case dpadLeft
    case dpadRight
    case dpadUp
    case dpadDown
    
    case leftShoulder
    case leftShoulder2
    case rightShoulder
    case rightShoulder2
    
    case btnLStickX //19
    case btnLStickY
    case btnRStickX
    case btnRStickY
    case mouseX
    case mouseY
    
    case unknown
    
    public var buttonId: ButtonId? {
        let value = self.rawValue
        if (value < 19) {
            return ButtonId(rawValue: Int(value))
        }
        return nil
    }
    
    public var analogId: AnalogId? {
        switch self {
        case .btnLStickX: return AnalogId.btnLStickX
        case .btnLStickY: return AnalogId.btnLStickY
        case .btnRStickX: return AnalogId.btnRStickX
        case .btnRStickY: return AnalogId.btnRStickY
        case .leftShoulder: return AnalogId.leftShoulder
        case .leftShoulder2: return AnalogId.leftShoulder2
        case .rightShoulder: return AnalogId.rightShoulder
        case .rightShoulder2: return AnalogId.rightShoulder2
        default: return nil
        }
    }
}

public struct InputCommand {
    public init(id: UInt32, value: Int16) {
        self.id = id
        self.value = value
    }

    public let id:UInt32
    public let value:Int16
}

public struct InputCommandList {
    public init(clientId: UInt32, deviceId: UInt32, commands: [InputCommand]) {
        self.clientId = clientId
        self.deviceId = deviceId
        self.commands = commands
    }

    public let clientId:UInt32
    public let deviceId:UInt32
    public let commands:[InputCommand]
    
    public func getUniqueId() -> UInt64 {
        let id:UInt64 = (UInt64(clientId) << 32) & UInt64(deviceId)
        return id
    }
}

/* need to handle shift / click / release shift / release click */
public struct ControllerState {
    public init(buttons: PressedControllerButtons, analogValues: [AnalogId : Int16] = [:], commands: [InputCommand]) {
        self.buttons = buttons
        self.analogValues = analogValues
        self.commands = commands
    }

    public var buttons:PressedControllerButtons //Represents last state
    public var analogValues:[AnalogId:Int16] = [:] //Represents last state
    public var commands:[InputCommand]
    
    public static let blank = ControllerState(buttons: PressedControllerButtons(rawValue: 0), commands: [])
    
    
}

extension ControllerState {

}

public class VirtualController {
    public init(clientId: UInt32, deviceId: UInt32, state: ControllerState, statePrevious: ControllerState) {
        self.clientId = clientId
        self.deviceId = deviceId
        self.state = state
        self.statePrevious = statePrevious
    }
    
    public let clientId:UInt32
    public let deviceId:UInt32
    public var state:ControllerState
    public var statePrevious:ControllerState
    
    public func pushCommandList(_ commandList:InputCommandList) {
        statePrevious = state //TODO: Hopefully copys
        state.commands = commandList.commands
        for eachCommmand in commandList.commands {
            
            guard let commandEnum = CommandId(rawValue: eachCommmand.id) else { continue }
            
            if let analogId = commandEnum.analogId {
                state.analogValues[analogId] = eachCommmand.value
            } else if let buttonId = commandEnum.buttonId {
                let button = PressedControllerButtons(rawValue: 1 << buttonId.index)
                if (eachCommmand.value > 0) {
                    state.buttons.insert(button)
                } else {
                    state.buttons.subtract(button)
                }
            }
        }
    }
}
