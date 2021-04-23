//
//  PeerInfo.swift
//  Pods-Runner
//
//  Created by Robert Van Haecke on 11/04/2021.
//

import Foundation

public class PeerInfo {
    var address: String
    var port: UInt16
    var ping: UInt64
    var addressWithPort: String {
        get {
            "\(address):\(port)"
        }
    }
    
    init(address: String, port: UInt16, ping: UInt64) {
        self.address = address
        self.port = port
        self.ping = ping
    }
}
