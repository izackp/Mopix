//
//  InProcessTransport.swift
//
//
//  In-process DisplayTransport pair. Client-side and server-side live in the
//  same process: ClientMessages are delivered to a server handler callback,
//  ServerMessages are yielded to an AsyncStream the client consumes.
//

import Foundation

public enum InProcessTransport {

    public static func makePair() -> (client: ClientEnd, server: ServerEnd) {
        var continuation: AsyncStream<ServerMessage>.Continuation!
        let stream = AsyncStream<ServerMessage> { continuation = $0 }
        let server = ServerEnd(clientContinuation: continuation)
        let client = ClientEnd(incoming: stream, server: server)
        return (client, server)
    }

    public final class ClientEnd: DisplayTransport {
        public let incoming: AsyncStream<ServerMessage>
        private let server: ServerEnd

        fileprivate init(incoming: AsyncStream<ServerMessage>, server: ServerEnd) {
            self.incoming = incoming
            self.server = server
        }

        public func send(_ message: ClientMessage) async {
            await server.deliver(message)
        }

        public func send(_ message: ServerMessage) async {
            // Client end does not originate server messages.
        }
    }

    public final class ServerEnd: DisplayTransport {
        public var handler: ((ClientMessage) async -> Void)?
        private let clientContinuation: AsyncStream<ServerMessage>.Continuation

        fileprivate init(clientContinuation: AsyncStream<ServerMessage>.Continuation) {
            self.clientContinuation = clientContinuation
        }

        public func send(_ message: ServerMessage) async {
            clientContinuation.yield(message)
        }

        public func send(_ message: ClientMessage) async {
            // Server end does not originate client messages.
        }

        public func finish() {
            clientContinuation.finish()
        }

        fileprivate func deliver(_ message: ClientMessage) async {
            await handler?(message)
        }
    }
}
