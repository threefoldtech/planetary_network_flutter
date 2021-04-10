import Flutter
import NetworkExtension
import Yggdrasil
import UIKit

public class SwiftYggdrasilPlugin: NSObject, FlutterPlugin {
  var vpnManager: NETunnelProviderManager = NETunnelProviderManager()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "yggdrasil_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftYggdrasilPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if (call.method == "getPlatformVersion") {
      result("iOS " + UIDevice.current.systemVersion)
    } else if (call.method == "start_vpn") {
      let bestPeers = BestPeers()
      result(bestPeers.GetBestPeers())


      result(true);
    } else if (call.method == "stop_vpn") {
      result(false);
    }
    
    result(FlutterMethodNotImplemented)
  }
}
