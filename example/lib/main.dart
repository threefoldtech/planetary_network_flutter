import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:yggdrasil_plugin/yggdrasil_plugin.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {


    super.initState();

  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TestPage()
    );
  }

}


class TestPage extends StatelessWidget {
  String _platformVersion = 'Unknown';
  YggdrasilPlugin plugin = YggdrasilPlugin();
  BuildContext _context;

  TestPage() {
    plugin.setOnReportIp(reportIp);
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      appBar: AppBar(title: Text("Test")),
      body: Container(
          child: new Row (
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            RaisedButton(
              color: Colors.redAccent,
              textColor: Colors.white,
              onPressed: () {
                startVPN(context);
              },
              child: Text("Start"),
            ),
            RaisedButton(
              color: Colors.redAccent,
              textColor: Colors.white,
              onPressed: () {
                stopVPN(context);
              },
              child: Text("Stop"),
            )
          ])
      ),
    );
  }

  showAlertDialog(String message) {
    showDialog(
      context: _context,
      builder: (_) => new AlertDialog(
        title: const Text("Your IP"),
        content: new Text(message),
        actions: [
          new FlatButton(
            child: const Text("Ok"),
            onPressed: () {
              Navigator.pop(_context);
            },
          ),
        ],
      ),
    );
  }

  void reportIp(String ip) {
    print("EVEN IN THE UI FFS...");
    showAlertDialog(ip);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    platformVersion = await plugin.platformVersion();
  }


  void startVPN(BuildContext context) async {
    await plugin.startVpn({
      'signingPublicKey': 'signingPublicKey',
      'signingPrivateKey': 'signingPrivateKey', 
      'encryptionPublicKey': 'encryptionPublicKey',
      'encryptionPrivateKey': 'encryptionPrivateKey'
    });
  }

  void stopVPN(BuildContext context) async {
    await plugin.stopVpn();
  }
}