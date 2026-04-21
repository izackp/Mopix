//
//  DisplayTransport.swift
//
//
//  Transport abstraction. Both sides hold one end.
//  In-process: direct function calls. Network: serialize + send.
//

public protocol DisplayTransport: AnyObject {
    func send(_ message: ClientMessage) async
    func send(_ message: ServerMessage) async
}
