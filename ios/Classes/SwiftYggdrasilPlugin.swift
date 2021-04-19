import Flutter
import NetworkExtension
import Yggdrasil
import UIKit
import CocoaAsyncSocket

public class SwiftYggdrasilPlugin: NSObject, FlutterPlugin, GCDAsyncSocketDelegate {
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
        let vpnService = VpnService()
        
        vpnService.initVpn() {
            
            vpnService.startVpnTunnel()
            completionHandler(true)
            /*let bestPeers = BestPeers()
            
            bestPeers.GetBestPeers() { bestPeersResult in
                NSLog("Success: \(bestPeersResult.isSuccessful)")
                NSLog("Message: \(bestPeersResult.message ?? "No message")")
                NSLog("Peers: \(bestPeersResult.peers.count)")

                completionHandler(bestPeersResult.isSuccessful)
            }*/
        }
    }
}
