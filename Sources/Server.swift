//
//  Server.swift
//  MultiConnect
//
//  Created by michal on 29/11/2020.
//

import Foundation
import Network

class Server {

    private let listener: NWListener

    private var connections: [Connection] = []

    init() throws {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 2

        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.includePeerToPeer = true
        listener = try NWListener(using: .tcp)
        
        listener.service = NWListener.Service(name: "FigacciaManager", type: "_f-manager._tcp")
    }

    func start(dataHandler: @escaping (Data) -> Void) {
        listener.stateUpdateHandler = { newState in
            print("Listener state changed: \(newState)")
        }
        listener.newConnectionHandler = { [weak self] newConnection in
            guard let self = self else { return }
            
            print("Listener opened connection \(newConnection)")
            
            let connection = Connection(connection: newConnection, dataHandler: dataHandler)
           
            
            self.cleanupConnections()
            self.connections += [connection]
        }
        
        listener.start(queue: .main)
    }
    
    func cleanupConnections() {
        for connection in connections where connection.connection.state == .cancelled {
            if let index = connections.firstIndex(where: {$0.connection.state == .cancelled}) {
                connections.remove(at: index)
            }
        }
    }
    
    func stop() {
        self.listener.cancel()
        
        for connection in connections {
            connection.connection.cancel()
        }
    }

    func send(_ data: Data) {
        for connection in connections {
            connection.send(data)
        }
    }
}
