import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<String> LocalIp() async {
  String address='';

  //搜寻本机IP
  for (var interface in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
    if(interface.name.startsWith('VM')) continue; //过滤VM虚拟机的虚拟IP
    for (var addr in interface.addresses) {
      if (addr.isLoopback) continue;
      address=addr.address;
    }
  }
  return address;
}

int fileIndex = 0;

void handleClient(Socket client, List<PlatformFile> list) async {
  client.listen((Uint8List data) async {
    await Future.delayed(Duration(seconds: 1));
    final request = String.fromCharCodes(data);
    if (request == 'Send Data' && fileIndex < list.length) {
      Uint8List bytes = list[fileIndex].bytes!;
      client.add(bytes);
      fileIndex++;
    }
  });
}
