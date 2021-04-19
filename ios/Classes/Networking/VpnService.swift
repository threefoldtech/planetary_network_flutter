//
//  VpnService.swift
//  yggdrasil_plugin
//
//  Created by Robert Van Haecke on 16/04/2021.
//

import Foundation
import NetworkExtension

class VpnService {
    var vpnManager: NETunnelProviderManager = NETunnelProviderManager()

    let yggdrasilComponent = "org.jimber.yggdrasil"
    
    var yggdrasilConfig: ConfigurationProxy? = nil
    
    var yggdrasilAdminTimer: DispatchSourceTimer?
    var yggdrasilSelfIP: String = "N/A"
    var yggdrasilSelfSubnet: String = "N/A"
    var yggdrasilSelfCoords: String = "[]"
    var yggdrasilPeers: [[String: Any]] = [[:]]
    var yggdrasilSwitchPeers: [[String: Any]] = [[:]]
    var yggdrasilNodeInfo: [String: Any] = [:]
    
    func initVpn(completionHandler:@escaping () -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { (savedManagers: [NETunnelProviderManager]?, error: Error?) in
            if let error = error {
                print(error)
            }
            
            if let savedManagers = savedManagers {
                for manager in savedManagers {
                    if (manager.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.yggdrasilComponent {
                        print("Found saved VPN Manager")
                        self.vpnManager = manager
                    }
                }
            }
            
            self.vpnManager.loadFromPreferences(completionHandler: { (error: Error?) in
                if let error = error {
                    print(error)
                }
                
                if let vpnConfig = self.vpnManager.protocolConfiguration as? NETunnelProviderProtocol,
                    let confJson = vpnConfig.providerConfiguration!["json"] as? Data {
                    print("Found existing protocol configuration")
                    self.yggdrasilConfig = try? ConfigurationProxy(json: confJson)
                } else  {
                    print("Generating new protocol configuration")
                    self.yggdrasilConfig = ConfigurationProxy()
                }
                
                self.vpnManager.localizedDescription = "Yggdrasil"
                self.vpnManager.isEnabled = true
                
                if let config = self.yggdrasilConfig {
                    //try? config.save(to: &self.vpnManager)
                }
                
                completionHandler()
            })
        }
    }
    
    func startVpnTunnel() {
        do {
            try self.vpnManager.connection.startVPNTunnel()
        } catch {
            NSLog(error.localizedDescription)
        }
    }
}
