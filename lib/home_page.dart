import 'package:background_task/background_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // クリップボード用にインポート
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

var baseUrl = 'https://cheer-on-runner.com/';

class _HomePageState extends State<HomePage> {
  String url = '';  // 状態を管理するためにurlをState内に移動

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    var uuid = Uuid();
                    var newId = uuid.v4();
                    setState(() {
                      url = '$baseUrl$newId';  // URLを更新し、画面に反映
                    });
                  },
                  icon: const Icon(
                    Icons.play_arrow,
                  ),
                  label: const Text("URL作成"),
                ),
                if (url.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            url,
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,  // 長いURLが表示エリアに収まるように省略
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: url));  // URLをクリップボードにコピー
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("URLをクリップボードにコピーしました")),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                ElevatedButton.icon(
                  onPressed: () async {
                    await BackgroundTask.instance.start();
                  },
                  icon: const Icon(
                    Icons.play_arrow,
                  ),
                  label: const Text("ランニング開始"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
