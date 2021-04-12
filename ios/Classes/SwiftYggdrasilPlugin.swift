import Flutter
import NetworkExtension
import Yggdrasil
import UIKit
import CocoaAsyncSocket

public class SwiftYggdrasilPlugin: NSObject, FlutterPlugin, GCDAsyncSocketDelegate {
    var vpnManager: NETunnelProviderManager = NETunnelProviderManager()
    
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
            /*
            do {
                try self.vpnManager.connection.startVPNTunnel()
            } catch {
                NSLog(error.localizedDescription)
            }
            */
            let bestPeers = BestPeers()
            
            bestPeers.GetBestPeers() { bestPeersResult in
                NSLog("Success: \(bestPeersResult.isSuccessful)")
                NSLog("Message: \(bestPeersResult.message ?? "No message")")
                NSLog("Peers: \(bestPeersResult.peers.count)")
 
                result(bestPeersResult.isSuccessful)
            }
            
            
            
        } else if (call.method == "stop_vpn") {
            result(false);
        }
    
        result(FlutterMethodNotImplemented)
    }
}
