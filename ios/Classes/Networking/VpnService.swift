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
    var bestPeers: BestPeers = BestPeers()
    
    let yggdrasilComponent = "org.jimber.yggdrasil.extension"
    
    var yggdrasilConfig: ConfigurationProxy? = nil
    
    var yggdrasilAdminTimer: DispatchSourceTimer?
    var yggdrasilSelfIP: String = "N/A"
    var yggdrasilSelfSubnet: String = "N/A"
    var yggdrasilSelfCoords: String = "[]"
    var yggdrasilPeers: [[String: Any]] = [[:]]
    var yggdrasilSwitchPeers: [[String: Any]] = [[:]]
    var yggdrasilNodeInfo: [String: Any] = [:]
    
    func initVpn(completionHandler:@escaping (Bool) -> Void) {
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
                
                self.getProtocolConfiguration() { result, config in
                    if (!result) {
                        completionHandler(false)
                        return
                    }
                    
                    self.yggdrasilConfig = config
                    self.vpnManager.localizedDescription = "Yggdrasil"
                    self.vpnManager.isEnabled = true
                    
                    guard let config = self.yggdrasilConfig else {
                        completionHandler(false)
                        return
                    }
                    
                    do {
                        try config.save(to: &self.vpnManager) { result in
                            completionHandler(result)
                        }
                    } catch {
                        completionHandler(false)
                    }
                }
            })
        }
    }
    
    func getProtocolConfiguration(completionHandler:@escaping (Bool, ConfigurationProxy?) -> Void) {
        if let vpnConfig = self.vpnManager.protocolConfiguration as? NETunnelProviderProtocol,
            let confJson = vpnConfig.providerConfiguration!["json"] as? Data {
            
            print("Found existing protocol configuration")
            let config = try? ConfigurationProxy(json: confJson)
            completionHandler(true, config)
            
        } else  {
            
            print("Generating new protocol configuration")
            self.generateNewProtocolConfiguration() { result, yggdrasilConfig in
                completionHandler(result, yggdrasilConfig)
            }
            
        }
    }
    
    func generateNewProtocolConfiguration(completionHandler:@escaping (Bool, ConfigurationProxy?) -> Void) {
        let config = ConfigurationProxy()
        
        self.bestPeers.GetBestPeers() { bestPeersResult in
            
            if (!bestPeersResult.isSuccessful) {
                completionHandler(false, nil)
                return
            }
            
            for peer in bestPeersResult.peers {
                NSLog("Adding peer \(peer.addressWithPort)")
                config.add(peer.addressWithPort, in: "Peers")
            }
            
            completionHandler(true, config)
        }
    }
    
    func startVpnTunnel() {
        do {
            NSLog("Yggdrasil: Start VPN Tunnel")
            try self.vpnManager.connection.startVPNTunnel()
        } catch {
            NSLog(error.localizedDescription)
        }
    }
    
    func stopVpnTunnel() {
        self.vpnManager.connection.stopVPNTunnel()
    }
    
    
    func makeIPCRequests() {
        if self.vpnManager.connection.status != .connected {
            return
        }
        if let session = self.vpnManager.connection as? NETunnelProviderSession {
            try? session.sendProviderMessage("address".data(using: .utf8)!) { (address) in
                self.yggdrasilSelfIP = String(data: address!, encoding: .utf8)!
                NotificationCenter.default.post(name: .YggdrasilSelfUpdated, object: nil)
            }
            try? session.sendProviderMessage("subnet".data(using: .utf8)!) { (subnet) in
                self.yggdrasilSelfSubnet = String(data: subnet!, encoding: .utf8)!
                NotificationCenter.default.post(name: .YggdrasilSelfUpdated, object: nil)
            }
            try? session.sendProviderMessage("coords".data(using: .utf8)!) { (coords) in
                self.yggdrasilSelfCoords = String(data: coords!, encoding: .utf8)!
                NotificationCenter.default.post(name: .YggdrasilSelfUpdated, object: nil)
            }
            try? session.sendProviderMessage("peers".data(using: .utf8)!) { (peers) in
                if let jsonResponse = try? JSONSerialization.jsonObject(with: peers!, options: []) as? [[String: Any]] {
                    self.yggdrasilPeers = jsonResponse
                    NotificationCenter.default.post(name: .YggdrasilPeersUpdated, object: nil)
                }
            }
            try? session.sendProviderMessage("switchpeers".data(using: .utf8)!) { (switchpeers) in
                if let jsonResponse = try? JSONSerialization.jsonObject(with: switchpeers!, options: []) as? [[String: Any]] {
                    self.yggdrasilSwitchPeers = jsonResponse
                    NotificationCenter.default.post(name: .YggdrasilSwitchPeersUpdated, object: nil)
                }
            }
        }
    }
}
