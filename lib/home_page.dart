import 'package:background_locator_2/background_locator.dart';
import 'package:cheer_on_runnner_app/import.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/run.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

var baseUrl = 'https://cheer-on-runner.com/';

class _HomePageState extends State<HomePage> {
  String url = '';
  final location = Location();

  void _requestLocationPermission() async {
    await RequestLocationPermission.request(location);
  }

  Future<void> _createRunRecord(String runId) async {
    final newRun = Run(
      id: runId,
      startTime: DateTime.now(),
      route: [],
      photos: [],
      status: 'pending',
      url: '$baseUrl$runId',
    );
    await FirestoreHelper.instance.insertRun(newRun);
  }

  Future<void> _saveRunId(String runId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentRunId', runId);
  }

  Future<String?> _getRunId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currentRunId');
  }

  Future<void> _removeRunId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentRunId');
  }

  Future<void> _updateRunStartTime() async {
    final runId = await _getRunId();
    if (runId != null) {
      await FirestoreHelper.instance.insertRun(
        Run(
          id: runId,
          startTime: DateTime.now(),
          route: [],
          photos: [],
          status: 'running',
          url: '$baseUrl$runId',
        ),
      );
    }
  }

  Future<void> _updateRunEndTime() async {
    final runId = await _getRunId();
    if (runId != null) {
      final run = await FirestoreHelper.instance.getRunData(runId);
      if (run != null) {
        run.endTime = DateTime.now();
        run.status = 'completed';
        await FirestoreHelper.instance.insertRun(run);
      }
      await _removeRunId();
    }
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

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
                    var uuid = const Uuid();
                    var newId = uuid.v4();
                    setState(() {
                      url = '$baseUrl$newId';
                    });

                    await _saveRunId(newId); // ローカルストレージにrunIdを保存
                    await _createRunRecord(newId);
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
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: url));
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
                    _requestLocationPermission();
                    await _updateRunStartTime(); // ランニング開始時にstartTimeを更新
                    LocationCallbackHandler.startLocationService();
                  },
                  icon: const Icon(
                    Icons.play_arrow,
                  ),
                  label: const Text("ランニング開始"),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    _requestLocationPermission();
                    await _updateRunEndTime(); // ランニング終了時にendTimeを更新
                    BackgroundLocator.unRegisterLocationUpdate();
                  },
                  icon: const Icon(
                    Icons.stop,
                  ),
                  label: const Text("ランニング終了"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
