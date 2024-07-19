//
//  PeerConnection.swift
//  MultiConnect
//
//  Created by michal on 29/11/2020.
//

import Foundation
import Network
import OSLog

class Connection {
    let log = Logger(subsystem: "Connection", category: "Network")
    
    let connection: NWConnection
    let dataHandler: (Data) -> Void

    init(connection: NWConnection, dataHandler: @escaping (Data) -> Void) {
        self.dataHandler = dataHandler
        
        log.info("Server incoming connection")
        
        self.connection = connection
        
        start()
    }

    func start() {
        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                self.receiveData()
            case .failed(_):
                self.connection.cancel()
            default:
                break
            }
            print("Connection state changed: \(newState)")
        }
        
        connection.start(queue: .main)
    }

    func send(_ data: Data) {
        var length = UInt32(data.count)
        let lengthData = Data(bytes: &length, count: MemoryLayout<UInt32>.size)
        let packet = lengthData + data
        connection.send(content: packet, completion: .contentProcessed({ error in
            if let error = error {
                print("Send error: \(error)")
            }
        }))
    }
    
    func receiveData() {
        guard connection.state == .ready else { return }
        
        // Ricevi la lunghezza del messaggio
        connection.receive(minimumIncompleteLength: MemoryLayout<UInt32>.size, maximumLength: MemoryLayout<UInt32>.size) { lengthData, _, _, error in
            if let error = error {
                self.log.error("Error receiving length: \(error)")
                self.connection.cancel()
                return
            } else if let lengthData = lengthData, lengthData.count == MemoryLayout<UInt32>.size {
                let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self) }
                
                // Ricevi il messaggio JSON
                self.connection.receive(minimumIncompleteLength: Int(length), maximumLength: Int(length)) { data, _, _, error in
                    if let error = error {
                        self.log.error("Error receiving data: \(error)")
                        self.connection.cancel()
                        return
                    } else if let data = data {
                        self.dataHandler(data)
                    }
                    
                    // Ricevi il prossimo messaggio
                    self.receiveData()
                }
            } else {
                self.receiveData() // Riprova a ricevere la lunghezza se i dati sono incompleti
            }
        }
    }
}
