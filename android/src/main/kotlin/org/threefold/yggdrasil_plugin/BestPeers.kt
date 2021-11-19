package org.threefold.yggdrasil_plugin

import android.util.Log
import org.threefold.yggdrasil_plugin.models.PeerInfo
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.*
import java.util.concurrent.Callable


internal class GetBestPeers() : Callable<ArrayList<PeerInfo>> {
    override fun  call(): ArrayList<PeerInfo> {
        // Some long running task
        val google = URL("https://publicpeers.neilalexander.dev/")
        val `in` = BufferedReader(InputStreamReader(google.openStream()))
        var input: String?
        val stringBuffer = StringBuffer()
        while (`in`.readLine().also { input = it } != null) {
            stringBuffer.append(input)
        }
        `in`.close()
        val htmlData = stringBuffer.toString()

        Log.d("htmldate", "Got html: " + htmlData)
        val regex = Regex("((tcp|tls):\\/\\/(.*?))<\\/")
        val matches = regex.findAll(htmlData)
        val peers = ArrayList<PeerInfo>()
        var fastPeers = 0;

        for(match in matches){
            val urlToParse =  match.groupValues[1];
            val uri = URI(urlToParse)
            Log.d("uri", "scheme: " + uri.scheme + " Host: " + uri.host + " port " + uri.port);
            val start = System.currentTimeMillis()

            try{
                val socket = Socket()

                socket.connect(InetSocketAddress(uri.host, uri.port), 150)
                socket.close()
                val finish = System.currentTimeMillis()
                Log.d("ping", "pingTime: " + (finish - start))
                val scheme: String = uri.scheme;
                val ia: InetAddress = InetAddress.getByName(uri.host);
                var port: Int = uri.port
                var ping: Int = (finish-start).toInt()
                val peer = PeerInfo(scheme, ia, port, ping)

                peers.add(peer)
                if(ping < 150){
                    fastPeers++;
                }
            }catch (e: Exception){
                Log.d("ping", "Ping failed for host " + uri.host);
            }
            if(fastPeers > 2){
                Log.d("ygg", "Found 3 fast hosts (<150ms)");
                break;
            }
        }


        peers.sortBy { it.ping  }
        Log.d("ping", "Lowest ping is  " + peers[0].ping + " followed by " + peers[1].ping);


        return peers;
    }
}




