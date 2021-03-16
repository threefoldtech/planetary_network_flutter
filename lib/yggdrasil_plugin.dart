
import 'dart:async';

import 'package:flutter/services.dart';

typedef void onReportIpFnc(String ip);

class YggdrasilPlugin {

  MethodChannel _channel =  const MethodChannel('yggdrasil_plugin');
  onReportIpFnc _reportFnc;
  static final YggdrasilPlugin _singleton = YggdrasilPlugin._internal();

  init(){
    _singleton._channel.setMethodCallHandler(_onCall);
  }

  factory YggdrasilPlugin() {
    _singleton.init();
    return _singleton;
  }

  YggdrasilPlugin._internal();


  void setOnReportIp(onReportIpFnc fnc){
    _reportFnc = fnc;
  }

  Future<void> _onCall(MethodCall call) async {
    print("!!!!!!!ONCALL GOT EVENT!!!!!!!!!!!!!!!!11" + call.method);
    switch(call.method) {
      case "reportIp":
        final String ipAddress = call.arguments;
        _reportFnc(ipAddress);
    }
  }

  Future<String> platformVersion() async {

    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
  Future<String> startVpn() async {
    final String ip = await _channel.invokeMethod('start_vpn'); //@todo notation

    return ip;
  }
}
