//
//  CommandRepeater.swift
//  TestGame
//
//  Created by Isaac Paul on 6/9/22.
//

import Foundation

public protocol ICommandListener {
    func onCommandList(_ commandList:InputCommandList)
}

public protocol IVirutalControllerListener : AnyObject {
    func onInput(_ controller:VirtualController)
}
//
public class CommandRepeater {
    public init(commandListeners: [ICommandListener] = [], listeners: [UInt64 : [IVirutalControllerListener]] = [:], commandsThisTickById: [UInt64 : InputCommandList] = [:], virtualControllersById: [UInt64 : VirtualController] = [:]) {
        self.commandListeners = commandListeners
        self.listeners = listeners
        self.commandsThisTickById = commandsThisTickById
        self.virtualControllersById = virtualControllersById
    }

    
    var commandListeners:[ICommandListener] = []
    var listeners:[UInt64:[IVirutalControllerListener]] = [:]
    var commandsThisTickById:[UInt64:InputCommandList] = [:]
    var virtualControllersById:[UInt64:VirtualController] = [:]
    
    public func newTick() {
        commandsThisTickById.removeAll()
    }
    
    public func onCommand( _ list:InputCommandList) {
        let id = list.getUniqueId()
        commandsThisTickById[id] = list
        let controller = getVirtualController(id: id, list.clientId, list.deviceId)
        controller.pushCommandList(list)
        let allListeners = listeners[id] ?? []
        for eachListener in allListeners {
            eachListener.onInput(controller)
        }
        for eachListener in commandListeners {
            eachListener.onCommandList(list)
        }
    }
    
    public func getVirtualController(id:UInt64, _ clientId:UInt32, _ deviceId:UInt32) -> VirtualController {
        if let value = virtualControllersById[id] {
            return value
        }
        let new = VirtualController(clientId: clientId, deviceId: deviceId, state: ControllerState.blank, statePrevious: ControllerState.blank)
        virtualControllersById[id] = new
        return new
    }
    
    public func addListener(_ clientId:UInt32, _ deviceId:UInt32, _ listener:IVirutalControllerListener) {
        let id:UInt64 = (UInt64(clientId) << 32) & UInt64(deviceId)
        addListener(id, listener)
    }
    
    public func addListener(_ id: UInt64, _ listener:IVirutalControllerListener) {
        var list = listeners[id] ?? []
        list.append(listener)
        listeners[id] = list
    }
    
    public func removeListener(_ clientId:UInt32, _ deviceId:UInt32, _ listener:IVirutalControllerListener) {
        let id:UInt64 = (UInt64(clientId) << 32) & UInt64(deviceId)
        removeListener(id, listener)
    }
    
    public func removeListener(_ id: UInt64, _ listener:IVirutalControllerListener) {
        if var list = listeners[id] {
            list.removeAll(where: { $0 === listener })
        }
    }
}
