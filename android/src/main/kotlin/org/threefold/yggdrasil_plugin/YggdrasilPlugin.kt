package org.threefold.yggdrasil_plugin

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.VpnService
import android.util.Log
import androidx.annotation.NonNull
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.jimber.tools.TaskRunner
import org.threefold.yggdrasil_plugin.models.PeerInfo

/** YggdrasilPlugin */
class YggdrasilPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private var channel: MethodChannel? = null
    private lateinit var context: Context
    private lateinit var activity: Activity
    private lateinit var config: ConfigurationProxy
    private var currentIp = ""
    private var state = PacketTunnelState

    var VPN_REQUEST_CODE = 0x0F // const val?
    private val RECEIVER_INTENT = "eu.neilalexander.yggdrasil.PacketTunnelState.MESSAGE"

    private fun reportIp(ip: String): String {
        Log.d("ygg", "" + "IP Address: " + ip)
        channel!!.invokeMethod("reportIp", ip)
        return ""
    }

    private fun startVpn(
        signingPublicKey: String,
        signingPrivateKey: String,
        encryptionPublicKey: String,
        encryptionPrivateKey: String
    ): Boolean {

        val taskRunner = TaskRunner()
        Log.d("ygg", "preparing vpn service ")
        
        val intent = VpnService.prepare(context)
        if (intent != null) {
            Log.d("ygg", "Start activity for result... ")
            activity.startActivityForResult(intent, VPN_REQUEST_CODE)
            return false;
        }

        val connectToYggdrasil: (ArrayList<PeerInfo>) -> Unit = { data ->
            if (data.size < 3) {
                // @todo error not enough available peers
            }

     

            config = ConfigurationProxy(context)
            Log.d("pubkey", signingPublicKey) // Replace public key with app key
            config.updateJSON { json ->
                json.put("SigningPublicKey", signingPublicKey)
                json.put("SigningPrivateKey", signingPrivateKey)
                json.put("EncryptionPublicKey", encryptionPublicKey)
                json.put("EncryptionPrivateKey", encryptionPrivateKey)
            }
            data.forEach {
                Log.d("ygg", "Adding peer" + it)
                config.updateJSON { json -> json.getJSONArray("Peers").put(it) }
            }

            LocalBroadcastManager.getInstance(activity)
                .registerReceiver(receiver, IntentFilter(PacketTunnelProvider.RECEIVER_INTENT))

            val intentygg = Intent(context, PacketTunnelProvider::class.java)
            val TASK_CODE = 100
            val pi = activity.createPendingResult(TASK_CODE, intentygg, 0)
            intentygg.action = PacketTunnelProvider.ACTION_START
            val startResult = activity.startService(intentygg)
        }
        taskRunner.executeAsync(GetBestPeers(), connectToYggdrasil)

        return true
    }

    private fun stopVpn() {
        val intent = Intent(context, PacketTunnelProvider::class.java)
        intent.action = PacketTunnelProvider.ACTION_STOP
        activity.startService(intent)
    }
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "yggdrasil_plugin")
        channel!!.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        Log.d("ygg", " ######### ATTACH ")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d("ygg", " ######### On method call " + call.method)
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "start_vpn") {

            val started =
                startVpn(
                    call.argument<String>("signingPublicKey")!!,
                    call.argument<String>("signingPrivateKey")!!,
                    call.argument<String>("encryptionPublicKey")!!,
                    call.argument<String>("encryptionPrivateKey")!!
                )
            Log.d("ygg", "" + "VPN Started ")

            result.success(started)
        } else if (call.method == "stop_vpn") {
            stopVpn()
            Log.d("ygg", "" + "VPN Stopped")
            result.success("")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel!!.setMethodCallHandler(null)
        stopVpn()
    }

    override fun onDetachedFromActivity() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d("ygg", "************************ Attach")
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    private val receiver: BroadcastReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent) {

                when (intent.getStringExtra("type")) {
                    "state" -> {

                        // if(intent.getBooleanExtra("started", false)){
                        //     Log.d("ygg", "STARTED");

                        // if (state.dhtCount() == 0) {
                        //     Log.d("ygg", "No connectivity");
                        // } else {

                        //     Log.d("ygg", "Enabled");
                        // }
                        if(intent.getStringExtra("ip") == null){
                            currentIp = "";
                            return;
                        }
                        if (currentIp != intent.getStringExtra("ip")) {
                            // ip has changed!.
                            currentIp = intent.getStringExtra("ip")
                            reportIp(currentIp)
                        }
                    }
                }
            }
        }
}
