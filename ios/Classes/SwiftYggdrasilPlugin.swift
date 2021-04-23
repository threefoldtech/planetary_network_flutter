import Flutter
import NetworkExtension
import Yggdrasil
import UIKit
import CocoaAsyncSocket

public class SwiftYggdrasilPlugin: NSObject, FlutterPlugin, GCDAsyncSocketDelegate {
    let vpnService: VpnService
    
    override init() {
        self.vpnService = VpnService()
        super.init()
        
        NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: nil, queue: nil, using: { notification in
            NSLog("Yggdrasil: NEVPNStatusDidChange Notification")
            if let conn = notification.object as? NEVPNConnection {
                
                if (conn.status == .connected) {
                    NSLog("Yggdrasil: Connection made")
                    
                    self.vpnService.makeIPCRequests()
                }
            }
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onYggdrasilSelfUpdated), name: NSNotification.Name.YggdrasilSelfUpdated, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onYggdrasilPeersUpdated), name: NSNotification.Name.YggdrasilPeersUpdated, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onYggdrasilSwitchPeersUpdated), name: NSNotification.Name.YggdrasilSwitchPeersUpdated, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onYggdrasilSettingsUpdated), name: NSNotification.Name.YggdrasilSettingsUpdated, object: nil)
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "yggdrasil_plugin", binaryMessenger: registrar.messenger())
        let instance = SwiftYggdrasilPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        if (call.method == "getPlatformVersion") {
            result("iOS " + UIDevice.current.systemVersion)
        } else if (call.method == "start_vpn") {
            startVpn() { success in
                result(success)
            }
        } else if (call.method == "stop_vpn") {
            result(false);
        }
    
        result(FlutterMethodNotImplemented)
    }
    
    private func startVpn(completionHandler:@escaping (Bool) -> Void) {

        vpnService.initVpn() { result in

            if (!result) {
                completionHandler(false)
                return
            }
            
            self.vpnService.startVpnTunnel()
            completionHandler(true)
        }
    }
    
    func logYggdrasilData() {
        
        NSLog("Yggdrasil Connection Info")
        NSLog("IP Address: \(self.vpnService.yggdrasilSelfIP)")
        NSLog("Subnet: \(self.vpnService.yggdrasilSelfSubnet)")

        //var peerString = String(data: try! JSONSerialization.data(withJSONObject: peer, options: .prettyPrinted), encoding: .utf8)!
    }
    
    @objc func onYggdrasilSelfUpdated(notification: NSNotification) {
        NSLog("Yggdrasil: Notification onYggdrasilSelfUpdated received")
        self.logYggdrasilData()
    }
    
    @objc func onYggdrasilPeersUpdated(notification: NSNotification) {
        NSLog("Yggdrasil: Notification onYggdrasilPeersUpdated received")
        self.logYggdrasilData()
    }
    
    @objc func onYggdrasilSwitchPeersUpdated(notification: NSNotification) {
        NSLog("Yggdrasil: Notification onYggdrasilSwitchPeersUpdated received")
        self.logYggdrasilData()
    }
    
    @objc func onYggdrasilSettingsUpdated(notification: NSNotification) {
        NSLog("Yggdrasil: Notification onYggdrasilSettingsUpdated received")
        self.logYggdrasilData()
    }
}
