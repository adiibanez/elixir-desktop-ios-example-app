#if !os(watchOS)
import Foundation
import LiveViewNative
import LiveViewNativeCore
import UniformTypeIdentifiers
import PhoenixChannelsClientFFI
import Combine
import os
import LiveViewNativeBleClient

struct MyAppRegistry: RootRegistry {
}

/*struct MyAppRegistry: AggregateRegistry {
    #Registries<
        Addons.bleClient<Self>
    #Root
    >
}*/

@MainActor
class LvnSocketSingleton {
    static let shared: LvnSocketSingleton = {
        let instance = LvnSocketSingleton()
        instance.initialize()
        return instance
    }()
    
    public var session: LiveSessionCoordinator<MyAppRegistry>?
    
    private var currentURL: URL?
    private var lastURLUpdateTimestamp: TimeInterval?
    
    private var socket: Socket?
    private var channel: Channel?
    
    private var cancellables: Set<AnyCancellable> = []
    
    private let logger = Logger(subsystem: "DisconnectedView", category: "UI");
    
    func initialize() {
        
        Bridge.shared.urlAvailableEvent
            .receive(on: DispatchQueue.main) // Ensure updates happen on the main thread
            .sink { [weak self] (url) in
                //self?.scanState =
                
                guard let validURL = url else { return }
                print(">>> URL Available: \(String(describing: validURL))")
                self?.handleUrlAvailable(url)
            }
            .store(in: &cancellables)
        
        
        Task {
            if currentURL == nil {
                logger.error(">>> No URL available")
                return
            }
            
            session = LiveSessionCoordinator<MyAppRegistry>.init(self.currentURL!)
            //Success and all requirements has been met.
            print("liveSessionCoordinator success \(String(describing: session))")
            
            /*guard let session:LiveSessionCoordinator<MyAppRegistry>? = try await LiveSessionCoordinator<MyAppRegistry>(
             URL(string: "http://localhost:4000")!
             )
             else {
             print("Autsch livesession")
             return
             }*/
            
            print("got LiveSessionCoordinator \(session.debugDescription)")
            
            
            /*guard let socket:Socket? = try await session!.getSharedSocket()!
            else {
                print("Ooops, no socket")
                return
            }
            
            //print("Got socket status: \(socket!.status()) url: \(socket?.url())")
            self.socket = socket
            print("Trying to join channel")
            try await join()*/
            
        }
    }
    
    public func handleUrlAvailable(_ url: URL?) {
        guard let validURL = url else {
            print("LvnSocketSingleton: got nil URL")
            return
        }
        
        Task {
            if let lastTimestamp = lastURLUpdateTimestamp,
               Date().timeIntervalSince1970 - lastTimestamp < 2 {
                print("LvnSocketSingleton: Ignoring URL due to debounce threshold.")
                return
            }
            
            print("LvnSocketSingleton: URL Available Event received: \(validURL)")
            await LvnSocketSingleton.shared.session?.reconnect(url: validURL)
            lastURLUpdateTimestamp = Date().timeIntervalSince1970
        }
    }
    
    public func getSocket() -> Socket? {
        return self.socket
    }
    
    public func getChannel() -> Channel? {
        return self.channel
    }
    
    @discardableResult
    public func join() async throws -> [String:Any]{
        
        /*let topic:Topic = Topic.fromString(topic: "sensocto:lvntest:test_1")
        
        let joinPayloadStruct:JoinPayload = .init(id: "1234567890", name: "Test")
        let joinPayload = Payload.jsonPayload(json: try JsonEncoder().encode(joinPayloadStruct))
        
        guard let socket = self.socket else {
            print("join Outsch socket is nil")
            return [:]
        }
        
        self.channel = try await socket.channel(topic: topic, payload: joinPayload)
        let responseJoin = try await channel!.join(timeout: 30000) // LiveViewNativeCore.Payload
        
        print("Channel join Response: \(responseJoin) type: \(type(of: responseJoin)) socket status: \(socket.status())")*/
        return [:]
    }
    
    
    func pushEvent() async throws {
        
        guard let socket = self.socket else {
            print("pushEvent Outsch socket is nil")
            return
        }
        
        /*let joinPayloadStruct:JoinPayload = .init(id: "1234567890", name: "Test")
        let joinPayload = Payload.jsonPayload(json: try JsonEncoder().encode(joinPayloadStruct))
        
        let sendPayloadStruct:JoinPayload = .init(id: "1234567890", name: "Test")
        let sendPayload = Payload.jsonPayload(json: try JsonEncoder().encode(joinPayloadStruct))
        
        try await doPushEvent("action", payload: sendPayload)*/
    }
    
    @MainActor
    @discardableResult
    internal func doPushEvent(_ event: String, payload: LiveViewNativeCore.Payload) async throws -> [String:Any]? {
        guard let channel = channel else {
            return nil
        }
        
        /*guard case .joined = channel.status() else {
            throw LiveSocketError.DisconnectionError
        }
        
        // , timeout: PUSH_TIMEOUT = 30000
        let responsePayload = try await channel.call(event: .user(user: event), payload: payload, timeout: 30000)
        print("Response doPushEvent \(responsePayload)")*/
        return [:]
    }
}

struct JoinPayload: Encodable {
    let id: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}

#endif
