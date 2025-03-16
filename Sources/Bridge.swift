//
//  Bridge.swift
//  example
//
//  Created by Dominic Letz on 25.09.21.
//

import Combine
import Foundation
import Network
import ZIPFoundation
import SwiftUI
import os
import SystemConfiguration.CaptiveNetwork

//@MainActor
class Bridge: NSObject, ObservableObject {
    private let logger = Logger(subsystem: "Bridge", category: "Networking");
    
    static let randomBridgePort = UInt16.random(in: 49152...65535)
    
    @Published var progress: Progress = Progress()
    @Published var state: BridgeState = .unknown
    @Published var lastURL: URL?
    
    static let shared: Bridge = {
        let instance = Bridge()
        do {
            
            /*DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let appZip = Bundle.main.url(forResource: "app", withExtension: "zip")
                print("Bridge init: \(String(describing: appZip))")
            }*/
            
            
            
            
            //try instance.unpackApp();
            //try instance.setup();
        } catch(let e) {
            print("Bridge init failed: \(e)");
        }
        return instance
    }()

    //var webview: WebViewController?
    var listener: NWListener?
    let home: URL
    
    
    let  urlAvailableEvent = PassthroughSubject<URL?, Never>()
    
    static public var instance: Bridge?
    var erlangStarted = false
    
    /*func setWebView(view :WebViewController) {
        self.webview = view
        
        logger.info( "setWebView \(String(describing: view))")
        
        //loadURL()
    }*/
    
    func getBridgePort() -> UInt16 {
        return Self.randomBridgePort
    }
    
    func setURL(url :String?) {
        if let lastURLString = url {
            guard !lastURLString.isEmpty else { return }
            self.lastURL = URL(string: lastURLString)
            self.logger.info("setURL \(lastURLString)")
            
            DispatchQueue.main.async {
                self.urlAvailableEvent.send(self.lastURL)
                self.state = .running
            }
            //self.loadURL()
            
        }
    }
    
    /*func loadURL() {
        if let view = self.webview {
            if let url = self.lastURL {
                logger.info("loadURL \(url.absoluteString)")
            } else {
                logger.info("loadURL no url available")
            }
            
            if let url = self.lastURL {
                logger.info ("opening \(url)")
                view.loadURL(url: url)
            }
        } else {
            logger.info("loadURL no webview")
        }
    }*/
    
    private var connectionsByID: [Int: ServerConnection] = [:]
    
    override init() {
        home = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent(Bundle.main.bundleIdentifier!)
        super.init()
        logger.info("bridge init \(self.home)")
        DispatchQueue.main.async {
            self.state = .unknown
        }
        //Bridge.instance = self
        //setupListener()
    }
    
    
    func setup() throws {
        
        if self.state == .unknown {
            logger.info( "app not ready, needs unpacking, abort")
            return
        }
        
        DispatchQueue.main.async {
            self.state = .starting
        }
        
        setupListener()
        
        let appdir = home.appendingPathComponent("app")
        
        let inet_rc = appdir.appendingPathComponent("inetrc")
        setEnv(name: "ERL_INETRC", value: inet_rc.path)
        //if (!FileManager.default.fileExists(atPath: inet_rc.path)) {
        let rc = #"""
            %% enable EDNS, 0 means enable YES!
            {edns,0}.
            {alt_nameserver, {8,8,8,8}}.
            %% specify lookup method
            {lookup, [dns]}.
            """#
        logger.info("'\(rc)'")
        try! rc.write(to: inet_rc, atomically: true, encoding: .utf8)
    }
    
    func unpackApp() throws {
        
        /*if (Bundle.main.url(forResource: "app", withExtension: "zip") == nil ) {
            print("Bundle lookup app.zip not ready")
            return
        }*/
        
        let infoAttr = try FileManager.default.attributesOfItem(atPath: zipFile().path)
        let infoDate = infoAttr[FileAttributeKey.creationDate] as! Date
        let build = UserDefaults.standard.string(forKey: "app_build_date")
        
        DispatchQueue.main.async {
            self.state = .unpacking
        }
        
        print("Preparing app files \(infoDate.description) installed: \(String(describing: build))")
        
        let appdir = home.appendingPathComponent("app")
        let info = appdir.appendingPathComponent("releases").appendingPathComponent("start_erl.data")
        
        if (!FileManager.default.fileExists(atPath: info.path)) {
            try unzipApp(dest: appdir)
        } else if (infoDate.description != build){
            try FileManager.default.removeItem(atPath: appdir.path)
            try unzipApp(dest: appdir)
            UserDefaults.standard.set(infoDate.description, forKey: "app_build_date")
        }
        
        DispatchQueue.main.async {
            self.state = .unpacked
        }
        
    }
    
    func setupListener() {
        let l = try! NWListener(using: .tcp, on: Bridge.port())
        l.stateUpdateHandler = self.stateDidChange(to:)
        l.newConnectionHandler = self.didAccept(nwConnection:)
        l.start(queue: .global())
        logger.info("setupListener")
        listener = l
    }
    
    func reinit() {
        
        if self.state == .unknown {
            logger.info( "app not ready, needs unpacking, abort")
            return
        }
        
        logger.info("Server re-init called")
        let conn = connectionsByID.first
        if conn == nil ||
            conn?.value.connection.state == .cancelled {
            stopListener()
            setupListener()
        }
    }
    
    static func port() -> NWEndpoint.Port {
        return NWEndpoint.Port(rawValue: randomBridgePort)!
    }
    
    func setEnv(name: String, value: String) {
        if self.state == .unknown {
            logger.info( "setEnv app not ready, needs unpacking, abort")
            return
        }
        
        logger.info("setenv \(name) \(value)")
        setenv(name, value, 1)
    }
    
    func zipFile() -> URL {
        return Bundle.main.url(forResource: "app", withExtension: "zip")!
    }
    
    func unzipApp(dest: URL) throws {
        do {
            try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.unzipItem(at: zipFile(), to: dest, progress: self.progress)
            logger.info("Successfully extracted app files to: \(dest.path)")
        } catch {
            logger.error("Failed to extract app files: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getHostname() -> String {
        // Method 1: Using ProcessInfo (Recommended for most cases)
        // This gets the "Computer Name" as set in System Preferences.
        let hostname = ProcessInfo.processInfo.hostName
        return hostname

        // Method 2: Using gethostname() (POSIX function - less preferred)
        // This gets the lower-level hostname. It *might* be different from
        // the user-friendly "Computer Name".
        // var hostName = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        // guard gethostname(&hostName, hostName.count) == 0 else {
        //   return "unknown" // Or handle the error appropriately
        // }
        // return String(cString: hostName)
    }
    
    func getPlatformSuffix() -> String {
        #if os(macOS)
        return "macos"
        #elseif os(iOS)
        // Further differentiate between iPhone/iPad and simulator
        #if targetEnvironment(simulator)
        return "iossimulator"
        #else
        return "ios"
        #endif
        #elseif os(tvOS)
        return "tvos"
        #elseif os(watchOS)
        return "watchos" // Added watchOS support
        #else
        return "unknown" // Handle other platforms if needed
        #endif
    }
    
    func platformSpecificData() -> String {
        #if os(iOS)
        return "iOS \(UIDevice.current.model)" // Use UIDevice.current
        #endif
        #if os(macOS)
        return "macOS" //Add macOS Value
        #endif
    }
    
    func getLocalIPAddress() -> String? {
        var address: String?

        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        defer { freeifaddrs(ifaddr) } // Deallocate memory

        // Loop through linked list of interfaces
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" || name == "en1" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        return address
    }
    
    
    func stateDidChange(to newState: NWListener.State) {
        
        switch newState {
        case .ready:
            if erlangStarted {
                logger.info("Erlang already started. Skipping")
                break
            }
            erlangStarted = true
            DispatchQueue.main.async {
                self.state = .starting
            }
            
            logger.info("NWListener ready. Starting Elixir")
            setEnv(name: "ELIXIR_DESKTOP_OS", value: "ios");
            setEnv(name: "BRIDGE_PORT", value: (listener?.port?.rawValue.description)!);
            // not really the home directory, but persistent between app upgrades (yes?)
            setEnv(name: "HOME", value: home.path)
            // BINDIR not used on iOS but needs to be defined
            let bindir = home.appendingPathComponent("bin")
            setEnv(name: "BINDIR", value: bindir.path)
            
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let logdir = urls[0].path
            let appdir = home.appendingPathComponent("app")
            
            guard let localIp = getLocalIPAddress() else {
                logger.info("Could not determine local IP address")
                return
            }
            
            // getLocalIPAddress()!
            let result = start_erlang(appdir.path, logdir, "\(getPlatformSuffix())@\(localIp)") // @127.0.0.1
            let swiftResult = handleErlangStartResult(String(cString: result!))
            
            switch swiftResult {
            case .success():
                DispatchQueue.main.async {
                    self.state = .starting
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.state = .failed(error)
                }
                logger.info("Erlang startup failed: \(error)")
            }
            
        case .failed(let error):
            logger.error("Bridge Server failure, error: \(error.localizedDescription)")
            exit(EXIT_FAILURE)
        case .cancelled:
            logger.error("Bridge Server failure, cancelled")
            exit(EXIT_FAILURE)
        case .waiting:
            logger.debug("Bridge Listener waiting")
            break
        default:
            logger.error("Bridge Server unknown new state, check logs")
            break
        }
    }
    
    private func didAccept(nwConnection: NWConnection) {
        let connection = ServerConnection(nwConnection: nwConnection, bridge: self)
        self.connectionsByID[connection.id] = connection
        connection.didStopCallback = { _ in
            self.connectionDidStop(connection)
        }
        connection.start()
        let payload = "\0\0\0\0\0\0\0\0\":reconnect\"".data(using: .utf8)!
        
        let size: UInt32 = CFSwapInt32(UInt32(payload.count))
        var message = withUnsafeBytes(of: size) { Data($0) }
        message.append(payload)
        connection.send(data: message)
        logger.info("server did open connection \(connection.id)")
        DispatchQueue.main.async {
            self.state = .running
        }
    }
    
    private func connectionDidStop(_ connection: ServerConnection) {
        self.connectionsByID.removeValue(forKey: connection.id)
        logger.info("server did close connection \(connection.id)")
    }
    
    private func stopListener() {
        if let l = listener {
            l.stateUpdateHandler = nil
            l.newConnectionHandler = nil
            l.cancel()
        }
    }
    
    //private func stop() {
    public func stop() {
        logger.info("stop() called")
        
        stopListener()
        for connection in self.connectionsByID.values {
            connection.didStopCallback = nil
            connection.stop()
        }
        self.connectionsByID.removeAll()
    }
}

class ServerConnection {
    private let logger = Logger(subsystem: "ServerConnection", category: "Networking");
    //The TCP maximum package size is 64K 65536
    let MTU = 65536
    
    private static var nextID: Int = 0
    let connection: NWConnection
    let id: Int
    var bridge: Bridge
    
    init(nwConnection: NWConnection, bridge: Bridge) {
        self.bridge = bridge
        connection = nwConnection
        id = ServerConnection.nextID
        ServerConnection.nextID += 1
    }
    
    var didStopCallback: ((Error?) -> Void)? = nil
    
    func start() {
        logger.debug("Starting server connection")
        
        connection.stateUpdateHandler = self.stateDidChange(to:)
        setupReceive()
        connection.start(queue: .main)
    }
    
    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            connectionDidFail(error: error)
        case .failed(let error):
            connectionDidFail(error: error)
        case .ready:
            break
        default:
            break
        }
    }
    
    private func setupReceive() {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { (data, _, isComplete, error) in
            if isComplete {
                self.connectionDidEnd()
                return
            }
            
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            
            let length: Int = Int(CFSwapInt32(data!.uint32))
            self.connection.receive(minimumIncompleteLength: length, maximumLength: length) { (datain, _, isComplete, error) in
                if isComplete {
                    self.connectionDidEnd()
                    return
                }
                
                if let error = error {
                    self.connectionDidFail(error: error)
                    return
                }
                
                let ref = datain!.prefix(8)
                let data = datain!.dropFirst(8)
                let json = try! JSONSerialization.jsonObject(with: data, options: [])
                
                let array = json as! [Any]
                //let module = array[0] as? String
                let method = array[1] as? String
                let args = array[2] as? [Any]
                
                //print ("received \(method)")
                if (method == ":loadURL") {
                    let urlString = args![1] as! String
                    self.logger.debug(":loadURL received \(urlString)")
                    self.bridge.setURL(url: urlString)
                    // Nothing to do else, setURL will set the state and send events
                }
                if (method == ":launchDefaultBrowser") {
                    //val uri = Uri.parse(args.getString(0))
                    //if (uri.scheme == "http") {
                    //    val browserIntent = Intent(Intent.ACTION_VIEW, uri)
                    //    applicationContext.startActivity(browserIntent)
                    //} else if (uri.scheme == "file") {
                    //    openFile(uri.path)
                    //}
                }
                
                var response = ref
                if (method == ":getOsDescription") {
                    self.logger.debug(":getOsDescription")
                    
                    
                    response.append(self.dataToList(string: "iOS \(Bridge.shared.platformSpecificData())"))
                } else if (method == ":getCanonicalName") {
                    self.logger.debug(":getCanonicalName")
                    //val primaryLocale = getCurrentLocale(applicationContext)
                    //var locale = "${primaryLocale.language}_${primaryLocale.country}"
                    //stringToList(locale).toByteArray()
                    response.append(self.dataToList(string: "en_en"))
                } else {
                    response.append("use_mock".data(using: .utf8)!)
                }
                
                
                let size: UInt32 = CFSwapInt32(UInt32(response.count))
                var message = withUnsafeBytes(of: size) { Data($0) }
                message.append(response)
                self.send(data: message)
                //self.send(data: response)
                self.setupReceive()
            }
        }
    }
    
    func dataToList(string: String) -> Data {
        return dataToList(data: string.data(using: .utf8)!)
    }
    func dataToList(data: Data) -> Data {
        let numbers = data.map { "\($0)" }
        return "[\(numbers.joined(separator: ","))]".data(using: .utf8)!
    }
    
    func send(data: Data) {
        self.connection.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
        }))
    }
    
    func stop() {
        print("Bridge connection \(id) will stop")
    }
    
    private func connectionDidFail(error: Error) {
        print("Bridge connection \(id) did fail, error: \(error)")
        stop(error: error)
    }
    
    private func connectionDidEnd() {
        print("Bridge connection \(id) did end")
        stop(error: nil)
    }
    
    private func stop(error: Error?) {
        connection.stateUpdateHandler = nil
        connection.cancel()
        if let didStopCallback = didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error)
        }
    }
}

extension Data {
    var uint32: UInt32 {
        get {
            let i32array = self.withUnsafeBytes { $0.load(as: UInt32.self) }
            return i32array
        }
    }
}

enum BridgeState: Equatable {
    static func == (lhs: BridgeState, rhs: BridgeState) -> Bool {
            switch (lhs, rhs) {
            case (.unpacking, .unpacking):
                return true
            case (.unpacked, .unpacked):
                return true
            case (.starting, .starting):
                return true
            case (.running, .running):
                return true
            case (.stopped, .stopped):
                return true
            case (.failed(let lhsError), .failed(let rhsError)):
                return lhsError == rhsError
            case (.unknown, .unknown):
                return true
            default:
                return false // Cases are not the same
            }
        }
    case unpacking
    case unpacked
    case starting
    case running
    case stopped
    case failed(BridgeError)
    case unknown
}

enum BridgeError: Error, Equatable {
    case corrupZip
    case missingSysConfig
    case missingBootFile
    case missingLib
    case startFailed
    case unknownError
    case ok
}

// Converts C++ error strings into Swift errors
func handleErlangStartResult(_ result: String) -> Result<Void, BridgeError> {
    switch result {
    case "error_sys_config_missing":
        return .failure(.missingSysConfig)
    case "error_boot_missing":
        return .failure(.missingBootFile)
    case "error_lib_missing":
        return .failure(.missingLib)
    case "error_erl_start_failed":
        return .failure(.startFailed)
    case "error_unknown":
        return .failure(.unknownError)
        // case ok, means thread detached, trying to start
    default:
        return .success(())
    }
}
