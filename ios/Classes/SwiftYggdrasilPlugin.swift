import Flutter
import UIKit
import Yggdrasil

public class SwiftYggdrasilPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "yggdrasil_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftYggdrasilPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if (call.method == "getPlatformVersion") {
      result("iOS " + UIDevice.current.systemVersion)
      return
    }
    
    result(false)    
  }
}
