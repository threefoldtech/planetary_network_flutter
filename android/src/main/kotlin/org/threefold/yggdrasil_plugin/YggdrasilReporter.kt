package org.threefold.yggdrasil_plugin

import android.util.Log

object YggdrasilReporter{

    init {
        println("Singleton class invoked.")
    }
    private var reportIpFnc : ((String) -> String)? = null;

    fun onReportIp(fnc: (String) -> String){
        reportIpFnc = fnc;

    }
    fun reportIp(ip: String) : String{

       reportIpFnc?.invoke(ip);
        return ip;
    }

}