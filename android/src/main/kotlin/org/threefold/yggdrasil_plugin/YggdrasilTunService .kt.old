package io.github.chronosx88.yggdrasil

import GetBestPeers
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.os.Build
import android.system.OsConstants
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.preference.PreferenceManager
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import dummy.ConduitEndpoint
import io.github.chronosx88.yggdrasil.models.DNSInfo
import io.github.chronosx88.yggdrasil.models.PeerInfo
import io.github.chronosx88.yggdrasil.models.config.Peer
import io.github.chronosx88.yggdrasil.models.config.Utils.Companion.convertPeer2PeerStringList
import io.github.chronosx88.yggdrasil.models.config.Utils.Companion.convertPeerInfoSet2PeerIdSet
import io.github.chronosx88.yggdrasil.models.config.Utils.Companion.deserializeStringList2DNSInfoSet
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
import mobile.Mobile
import mobile.Yggdrasil
import org.jimber.tools.TaskRunner
import org.threefold.yggdrasil_plugin.YggdrasilReporter
import java.io.*
import java.net.*
import kotlin.concurrent.thread


class YggdrasilTunService : VpnService() {

    private lateinit var ygg: Yggdrasil
    private lateinit var tunInputStream: InputStream
    private lateinit var tunOutputStream: OutputStream
    private lateinit var address: String
    private var isClosed = false

    /** Maximum packet size is constrained by the MTU, which is given as a signed short/2 */
    private val MAX_PACKET_SIZE = Short.MAX_VALUE/2
    private var tunInterface: ParcelFileDescriptor? = null
    private var isRunning = false

    private var yggConduitEndpoint: ConduitEndpoint? = null
    companion object {
        private const val TAG = "Yggdrasil-service"
        const val PARAM_PINTENT = "pendingIntent"
        const val COMMAND = "COMMAND"
        const val STOP = "STOP"
        const val START = "START"
        const val CURRENT_PEERS = "CURRENT_PEERS_v1.2.1"
        const val CURRENT_DNS = "CURRENT_DNS_v1.2"
        const val STATIC_IP = "yggdrasil_STATIC_IP"
        const val UPDATE_DNS = "UPDATE_DNS"
        const val UPDATE_PEERS = "UPDATE_PEERS"
        const val STATUS_START = 7
        const val STATUS_FINISH = 8
        const val STATUS_STOP = 9
        const val STATUS_PEERS_UPDATE = 12
        const val IPv6: String = "IPv6"
        const val MESH_PEERS = "MESH_PEERS"
        const val SIGNING_PRIVATE_KEY = "SIGNING_PRIVATE_KEY"
        const val SIGNING_PUBLIC_KEY = "SIGNING_PUBLIC_KEY"
        const val ENC_PRIVATE_KEY = "ENC_PRIVATE_KEY"
        const val ENC_PUBLIC_KEY = "ENC_PUBLIC_KEY"
        const val VPN_REQUEST_CODE = 0x0F
        const val REPORT_IP = "REPORT_IP"
    }

    private val FOREGROUND_ID = 1338

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("ygg", "YggdrasilTunService");
        val pi: PendingIntent? = intent?.getParcelableExtra(PARAM_PINTENT)
        when(intent?.getStringExtra(COMMAND)){
            STOP -> {
                isRunning = false
                stopVpn(pi)

            }
            START -> {
                isClosed = false;
                val taskRunner = TaskRunner()

                val connectToYggdrasil: (ArrayList<PeerInfo>) -> Unit =  { data ->
                    if(data.size < 3){
                        //@todo error not enough available peers
                    }
                    val peers = setOf(data[0], data[1], data[2]); //deserializeStringList2PeerInfoSet(intent.getStringArrayListExtra(CURRENT_PEERS))
                    val dns = deserializeStringList2DNSInfoSet(intent.getStringArrayListExtra(CURRENT_DNS))
                    val staticIP: Boolean = intent.getBooleanExtra(STATIC_IP, true)
          
                    var keys = mapOf(SIGNING_PUBLIC_KEY to intent.getStringExtra(SIGNING_PUBLIC_KEY), 
                                     SIGNING_PRIVATE_KEY to  intent.getStringExtra(SIGNING_PRIVATE_KEY), 
                                     ENC_PUBLIC_KEY to intent.getStringExtra(ENC_PUBLIC_KEY),
                                     ENC_PRIVATE_KEY to intent.getStringExtra(ENC_PRIVATE_KEY));
                       
                    ygg = Yggdrasil()
                    Log.d("ygg", "YggdrasilTunService" + "DO WE HAVE A KEY 2 ???" + keys[SIGNING_PUBLIC_KEY]);
                    setupTunInterface(pi, peers, dns, keys)
                    foregroundNotification(FOREGROUND_ID, "Yggdrasil service started")

                }
                taskRunner.executeAsync(GetBestPeers(), connectToYggdrasil)
                isRunning = true


            }
            UPDATE_DNS -> {
                throw Exception("Not implemented");
                //val dns = deserializeStringList2DNSInfoSet(intent.getStringArrayListExtra(CURRENT_DNS))
                //setupIOStreams(dns)
            }
            UPDATE_PEERS -> {
                throw Exception("Not implemented");
                //sendMeshPeerStatus(pi)
            }
        }

        return START_NOT_STICKY
    }

    private fun setupIOStreams(dns: MutableSet<DNSInfo>){
        address = ygg.addressString
        Log.d("ygg", "My address should be: " + address);
        YggdrasilReporter.reportIp(address);

        var builder =             Builder()
                .addAddress(address, 7)
                .allowFamily(OsConstants.AF_INET)
                .allowBypass()
                .setBlocking(true)
                .setMtu(MAX_PACKET_SIZE)

        if (dns.size > 0) {
            for (d in dns) {
                builder.addDnsServer(d.address)
            }
        }
        /*
        fix for DNS unavailability
         */
        if(!hasIpv6DefaultRoute()){
            builder.addRoute("2000::", 3)
        }
        Log.d("ygg", "establishing: " + (tunInterface == null));

        tunInterface = builder.establish()
        Log.d("ygg", "establish done: " + (tunInterface == null));
        tunInputStream = FileInputStream(tunInterface!!.fileDescriptor)
        tunOutputStream = FileOutputStream(tunInterface!!.fileDescriptor)
        Log.d("ygg", "done! ");
    }

    private fun setupTunInterface(
            pi: PendingIntent?,
            peers: Set<PeerInfo>,
            dns: MutableSet<DNSInfo>,
            keys: Map<String, String>
    ) {
        Log.d("ygg", "START");
        pi!!.send(STATUS_START)
        var configJson = Mobile.generateConfigJSON()
        val gson = Gson()
        var config = gson.fromJson(String(configJson), Map::class.java).toMutableMap()
        config = fixConfig(config, peers)


        config["SigningPublicKey"] = keys[SIGNING_PUBLIC_KEY];
        config["SigningPrivateKey"] = keys[SIGNING_PRIVATE_KEY];
        config["EncryptionPublicKey"] = keys[ENC_PUBLIC_KEY];
        config["EncryptionPrivateKey"] = keys[ENC_PRIVATE_KEY];

        configJson = gson.toJson(config).toByteArray()
        Log.d("ygg", "Configjson, " + gson.toJson(config));  

        yggConduitEndpoint = ygg.startJSON(configJson)



        Log.d("ygg", "setdone, setup iostreams");
        setupIOStreams(dns)
        Log.d("ygg", "threads");
        thread(start = true) {
            val buffer = ByteArray(MAX_PACKET_SIZE)
            while (!isClosed) {
                readPacketsFromTun(yggConduitEndpoint!!, buffer)
            }
        }
        thread(start = true) {
            while (!isClosed) {
                writePacketsToTun(yggConduitEndpoint!!)
            }
        }
        Log.d("ygg", "intent");
        val intent: Intent = Intent().putExtra(IPv6, address)
        pi.send(this, STATUS_FINISH, intent)
    }

    private fun sendMeshPeerStatus(pi: PendingIntent?){
        class Token : TypeToken<List<Peer>>()
        val gson = Gson()
        var meshPeers: List<Peer> = gson.fromJson(ygg.peersJSON, Token().type)
        val intent: Intent = Intent().putStringArrayListExtra(
                MESH_PEERS,
                convertPeer2PeerStringList(meshPeers)
        );
        pi?.send(this, STATUS_PEERS_UPDATE, intent)

    }

    private fun fixConfig(
            config: MutableMap<Any?, Any?>,
            peers: Set<PeerInfo>
    ): MutableMap<Any?, Any?> {

        val whiteList = arrayListOf<String>()
        whiteList.add("")
        val blackList = arrayListOf<String>()
        blackList.add("")
        config["Peers"] = convertPeerInfoSet2PeerIdSet(peers)
        config["Listen"] = ""
        config["AdminListen"] = "tcp://localhost:9001"
        config["IfName"] = "tun0"  
        (config["SessionFirewall"] as MutableMap<Any, Any>)["Enable"] = false
        //(config["SessionFirewall"] as MutableMap<Any, Any>)["AllowFromDirect"] = true
        //(config["SessionFirewall"] as MutableMap<Any, Any>)["AllowFromRemote"] = true
        //(config["SessionFirewall"] as MutableMap<Any, Any>)["AlwaysAllowOutbound"] = true
        //(config["SessionFirewall"] as MutableMap<Any, Any>)["WhitelistEncryptionPublicKeys"] = whiteList
        //(config["SessionFirewall"] as MutableMap<Any, Any>)["BlacklistEncryptionPublicKeys"] = blackList

        (config["SwitchOptions"] as MutableMap<Any, Any>)["MaxTotalQueueSize"] = 4194304
        if (config["AutoStart"] == null) {
            val tmpMap = emptyMap<String, Boolean>().toMutableMap()
            tmpMap["WiFi"] = false
            tmpMap["Mobile"] = false
            config["AutoStart"] = tmpMap
        }
  
        return config
    }

    private fun readPacketsFromTun(yggConduitEndpoint: ConduitEndpoint, buffer: ByteArray) {
        if(!isRunning){
            return
        }
        try {
            // Read the outgoing packet from the input stream.
            val length = tunInputStream.read(buffer)
            yggConduitEndpoint.send(buffer.sliceArray(IntRange(0, length - 1)))
        } catch (e: IOException) {
            Log.d("myTag", "ERR IO PRINTING STACK ");
            e.printStackTrace()
        }
    }

    private fun writePacketsToTun(yggConduitEndpoint: ConduitEndpoint) {
        if(!isRunning){
            return
        }
        val buffer = yggConduitEndpoint.recv()
        if(buffer!=null) {
            try {
                tunOutputStream.write(buffer)
            } catch (e: IOException) {
                e.printStackTrace()
            }
        }
    }

    private fun stopVpn(pi: PendingIntent?) {
        isClosed = true;
        isRunning = false;
        tunInputStream.close()
        tunOutputStream.close()
        tunInterface!!.close()
        ygg.stop()
        Log.d(TAG, "Yggdrasil stopped")
    }

    override fun onDestroy() {
        super.onDestroy()
        stopSelf()
    }

    private fun hasIpv6DefaultRoute(): Boolean {
        val cm =
                getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val networks = cm.allNetworks

            for (network in networks) {
                val linkProperties = cm.getLinkProperties(network)
                if(linkProperties!=null) {
                    val routes = linkProperties.routes
                    for (route in routes) {
                        if (route.isDefaultRoute && route.gateway is Inet6Address) {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }

    private fun foregroundNotification(FOREGROUND_ID: Int, text: String) {
        print("Foreground notification " + text)

    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotificationChannel(channelId: String, channelName: String): String{
        print("Createnotificationchannel")
        return "1"
    }
}
