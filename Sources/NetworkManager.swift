import Foundation
import OSLog

public class EasySwiftCommunication {
    
    public static let shared = EasySwiftCommunication()

    private let log = Logger()
    
    private let server: Server?
    
    var delegate: EasySwiftCommunicationDelegate?
    
    init() {
        do {
            self.server = try Server()
        } catch {
            log.error("Cannot create server: \(error)")
            server = nil
        }
    }
    
    func startListener() {
        guard let server = server else {
            log.error("Cannot start listener: server not initialized")
            return
        }
        
        server.start(dataHandler: { data in
            self.delegate?.notificationReceived(with: data)
        })
    }

    func send(_ data: Data) {
        guard let server = server else {
            log.error("Cannot send data: server not initialized")
            return
        }
        
        server.send(data)
    }
    
    deinit {
        server?.stop()
    }
}

protocol EasySwiftCommunicationDelegate {
    func notificationReceived(with data: Data)
}
