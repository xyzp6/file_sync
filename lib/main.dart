import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:file_sync/data/receive.dart';
import 'package:file_sync/data/send.dart';
import 'package:file_sync/dialog.dart';
import 'package:path/path.dart' as p;

import 'package:file_sync/data/SharedPreference.dart';
import 'package:file_sync/setting.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {

}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex=0;
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme=Theme.of(context).colorScheme;
    Widget page;
    switch(selectedIndex) {
      case 0:
        page=SyncPage();
        break;
      case 1:
        page=FilePage('path');
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(
      builder: (context,constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  backgroundColor: colorScheme.surfaceVariant,
                  extended: constraints.maxWidth>=600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.sync),
                      label: Text('同步'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.file_copy),
                      label: Text('文件'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex=value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class SyncPage extends StatefulWidget {
  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  String address='';
  List<PlatformFile> list=[];

  @override
  void initState() {
    super.initState();
    LocalIp().then((value) {
      setState(() {
        address=value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Setting()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 200,
              width: 200,
              child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Row(
                        children: <Widget>[
                          Icon(Icons.insert_drive_file),
                          SizedBox(width: 10),
                          Text(p.basename(list[index].name)),
                        ],
                      ),
                    );
                  }
              ),
            ),
            ElevatedButton(
                onPressed: () async {
                  // 打开系统文件管理器并选择文件
                  FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true,withData: true);
                  if(result != null) {
                    setState(() {
                      list = result.files;
                    });
                  }
                },
              child: Text('选择文件')),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: () async {
                  // 开启发送服务
                  final server = await ServerSocket.bind(address, 2714);
                  server.listen((client) {
                    handleClient(client, list);
                  });
                },
                child: Text('发送'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('搜索列表'),
                  content: Device(),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'Cancel'),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'OK'),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
              child: Text('接收'),
            ),
            Text('IP$address'),
          ],
        ),
      ),
    );
  }
}

class FilePage extends StatefulWidget {
  String _path="path";

  FilePage(this._path);

  @override
  _FilePageState createState() => _FilePageState(_path);
}

class _FilePageState extends State<FilePage> {
  String _path='path';
  List<FileSystemEntity> _files = [];

  _FilePageState(this._path);

  Future<List<FileSystemEntity>> getFiles(String path) async {
    final dir = Directory(path);
    return dir.listSync();
  }

  @override
  void initState() {
    super.initState();
    if(_path=='path') { //若为path，则为第一次进入
      readData("directoryPath").then((value) {
        _path=value ?? 'path';
        getFiles(_path).then((value) {
          setState(() {
            _files=value;
          });
        });
      });
    } else {
      getFiles(_path).then((value) {
        setState(() {
          _files=value;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Setting()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (BuildContext context, int index) {
          FileSystemEntity fileSystemEntity = _files[index];
          bool isDirectory = fileSystemEntity is Directory;
          return InkWell(
            onTap: isDirectory ? () {
              // 如果是文件夹，点击后进入下一页
              String path = fileSystemEntity.path;
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FilePage(path)),
              );
            } : null,
            child: ListTile(
              title: Row(
                children: <Widget>[
                  Icon(isDirectory ? Icons.folder : Icons.insert_drive_file),
                  SizedBox(width: 10),
                  Text(p.basename(_files[index].path)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

