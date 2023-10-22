import 'dart:io';
import 'dart:typed_data';

import 'package:file_sync/data/SharedPreference.dart';

void receive(String ip) async {
  String path = await readData("directoryPath") ?? 'path';
  final socket = await Socket.connect(ip, 2714);
  print("Connected to: ${socket.remoteAddress.address}:${socket.remotePort}");
  socket.write('Send Data');
  await socket.listen((Uint8List data) async {
    await Future.delayed(Duration(seconds: 1));
    dataHandler(data,path);
    print("ok: data written");
  });
  await Future.delayed(Duration(seconds: 20));
  socket.close();
  socket.destroy();
}

BytesBuilder builder = new BytesBuilder(copy: false);

void dataHandler(Uint8List data,String path) {
  print(path);
  builder.add(data);
  Uint8List dt = builder.toBytes();
  writeToFile(dt.buffer.asUint8List(0, dt.buffer.lengthInBytes), path);
}

Future<File> writeToFile(Uint8List data, String path) async {
  final file = File(path+'\\tt1.jpg');
  final folder = file.parent;
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }
  return file.writeAsBytes(data);
}
