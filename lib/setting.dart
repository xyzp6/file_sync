import 'package:file_picker/file_picker.dart';
import 'package:file_sync/data/SharedPreference.dart';
import 'package:flutter/material.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  String _path='加载中';

  @override
  void initState() {
    super.initState();
    readData("directoryPath").then((value) {
      setState(() {
        _path=value ?? '未设定';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Column(
        children: <Widget>[
          Text('同步',style: TextStyle(fontSize: 20),),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('文件位置'),
              SizedBox(width: 10,),
              FilledButton(
                onPressed: () async {
                  String? directoryPath = await FilePicker.platform.getDirectoryPath();
                  if (directoryPath != null) {
                    saveData("directoryPath", directoryPath);
                    setState(() {
                      _path=directoryPath;
                    });
                  } else {
                    print('没有选择任何文件夹');
                  }
                },
                child: Text('点我选择'),
              ),
            ],
          ),
          Text('当前位置：$_path'),
        ],
      ),
    );
  }
}