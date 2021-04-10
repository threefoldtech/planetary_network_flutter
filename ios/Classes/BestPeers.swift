import Foundation

public class BestPeers : NSObject {
    
    public func GetBestPeers() -> String {
        guard let url = URL(string: "https://jimber.io/peers.html") else {
            return "invalid link"
        }

        do {
            let htmlData = try String(contentsOf: url, encoding: .ascii)
        
            let pattern = "((tcp|tls):\\/\\/(.*?))<\\/"
            let regex = try! NSRegularExpression(pattern: pattern)
        
            //let matches = regex.matches(in: htmlData, range: NSRange(location: 0, length: htmlData.utf16.count))
            //let results = matches.map { String(htmlData[Range($0.range(at: 1), in: htmlData)!]) }
            regex.enumerateMatches(in: htmlData, options: [], range: NSRange(location: 0, length: htmlData.utf16.count)) { (result, _, stop) in
                guard let group = result?.range(at: 1),
                      let range = Range(group, in: htmlData)
                else {
                    return
                }
                let address = String(htmlData[range])
                Connect(to: address)
            }
        
            return "finished parsing html";
        } catch let error {
            return "\(error)";
        }
    }

    private func Connect(to: String) {
        NSLog("Connecting to \(to)")
        
        
        
        //let manager = SocketManager(socketURL: URL(string: to)!, config: [.log(true), .compress])
        //let socket = manager.defaultSocket
        
        
        //socket.connect()
        
        NSLog("Done with \(to)")
    }

}
