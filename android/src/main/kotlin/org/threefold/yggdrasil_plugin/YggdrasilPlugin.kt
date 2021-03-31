package org.threefold.yggdrasil_plugin


import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.github.chronosx88.yggdrasil.YggdrasilTunService
import io.github.chronosx88.yggdrasil.YggdrasilTunService.Companion.VPN_REQUEST_CODE


/** YggdrasilPlugin */
class YggdrasilPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private var channel: MethodChannel? = null
    private lateinit var context: Context
    private lateinit var activity: Activity

    private fun reportIp(ip: String) : String{
        Log.d("ygg", "" + "IP Address: " + ip);
        channel!!.invokeMethod("reportIp", ip)
        return "";
    }



    private fun startVpn(signingPublicKey: String, signingPrivateKey:String, encryptionPublicKey:String, encryptionPrivateKey:String) : Boolean {
        YggdrasilReporter.onReportIp({ ip -> reportIp(ip) });

        val intent = VpnService.prepare(context)
        if (intent!=null){
            activity.startActivityForResult(intent, VPN_REQUEST_CODE)
            return false;
        }

        val intentygg = Intent(context, YggdrasilTunService::class.java)
        val TASK_CODE = 100
        val pi = activity.createPendingResult(TASK_CODE, intentygg, 0)
        intentygg.putExtra(YggdrasilTunService.PARAM_PINTENT, pi)
        intentygg.putExtra(YggdrasilTunService.COMMAND, YggdrasilTunService.START)
        intentygg.putExtra(YggdrasilTunService.STATIC_IP, true)

        intentygg.putExtra(YggdrasilTunService.SIGNING_PUBLIC_KEY, signingPublicKey)
        intentygg.putExtra(YggdrasilTunService.SIGNING_PRIVATE_KEY, signingPrivateKey)
        intentygg.putExtra(YggdrasilTunService.ENC_PUBLIC_KEY, encryptionPublicKey)
        intentygg.putExtra(YggdrasilTunService.ENC_PRIVATE_KEY, encryptionPrivateKey)
        
        val startResult = activity.startService(intentygg)
    
        return true;

    }

  

    private fun stopVpn() {
        val intent = Intent(context, YggdrasilTunService::class.java)
        val TASK_CODE = 100
        val pi = activity.createPendingResult(TASK_CODE, intent, 0)
        intent.putExtra(YggdrasilTunService.PARAM_PINTENT, pi)
        intent.putExtra(YggdrasilTunService.COMMAND, YggdrasilTunService.STOP)
        activity.startService(intent)
    }
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "yggdrasil_plugin")
        channel!!.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "start_vpn") {
            
            val started = startVpn(call.argument<String>("signingPublicKey")!!, call.argument<String>("signingPrivateKey")!!,  call.argument<String>("encryptionPublicKey")!!,call.argument<String>("encryptionPrivateKey")!!);
            Log.d("ygg", "" + "VPN Started ");
            result.success(started)
        } else if (call.method == "stop_vpn") {
            stopVpn()
            Log.d("ygg", "" + "VPN Stopped");
            result.success("")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel!!.setMethodCallHandler(null)
        stopVpn();
    }

    override fun onDetachedFromActivity() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity;
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }


}



