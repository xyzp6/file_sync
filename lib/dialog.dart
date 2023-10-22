
import 'dart:io';

import 'package:file_sync/data/receive.dart';
import 'package:path/path.dart' as p;

import 'package:flutter/material.dart';

//首页搜索设备
class Device extends StatefulWidget {
  @override
  State<Device> createState() => _DeviceState();
}

class _DeviceState extends State<Device> {
  List<String> _dev=[];
  bool _scanning=false;

  @override
  void initState() {
    super.initState();
    scanNetwork().then((value) {
      setState(() {
        _dev=value;
        _scanning=false;
      });
    });
  }

  Future<List<String>> scanNetwork() async {
    String address='';
    for (var interface in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
      if(interface.name.startsWith('VM')) continue; //过滤VM虚拟机的虚拟IP
      for (var addr in interface.addresses) {
        if (addr.isLoopback) continue;
        address=addr.address;
      }
    }

    String subnet=address.substring(0, address.lastIndexOf('.'));
    int port=2714;

    List<String> _temp=[];
    setState(() {
      _scanning=true;
    });
    print('开始搜索 IP$subnet端口$port');
    for (var i = 1; i < 255; i++) {
      var ip = '$subnet.$i';
      try {
        final socket = await Socket.connect(ip, port, timeout: Duration(milliseconds: 50));
        print('Found device on $ip:$port');
        _temp.add(ip);
        await socket.close();
      } catch (_) {
        // Ignore errors
      }
    }

    setState(() {
      _scanning=false;
    });
    print('结束搜索');
    return _temp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _scanning?CircularProgressIndicator(): ListView.builder(
        itemCount: _dev.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {
              receive(p.basename(_dev[index]));
            },
            child: ListTile(
              title: Row(
                children: <Widget>[
                  Icon(Icons.devices_other),
                  SizedBox(width: 10),
                  Text(p.basename(_dev[index])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

