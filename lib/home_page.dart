import 'dart:async';
import 'dart:io';

import 'package:background_task/background_task.dart';
import 'package:cheer_on_runnner_app/import.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
  String tokenText = 'トークンはまだありません';
  late final StreamSubscription<Location> _bgDisposer;
  late final StreamSubscription<StatusEvent> _statusDisposer;

  final fcm = FirebaseMessaging.instance;

  Future getToken() async {
    final token = await fcm.getToken();
    setState(() {
      tokenText = token!;
    });
  }

  @override
  void initState() {
    super.initState();

    _bgDisposer = BackgroundTask.instance.stream.listen((event) {
      final message = '${DateTime.now()}: ${event.lat}, ${event.lng}';
      debugPrint(message);
    });

    Future(() async {
      await getToken();

      final result = await Permission.notification.request();
      debugPrint('notification: $result');
      if (Platform.isAndroid) {
        if (result.isGranted) {
          await BackgroundTask.instance.setAndroidNotification(
            title: 'バックグラウンド処理',
            message: 'バックグラウンド処理を実行中',
          );
        }
      }
    });

    _statusDisposer = BackgroundTask.instance.status.listen((event) {
      final message =
          'status: ${event.status.value}, message: ${event.message}';
      print(message);
    });
  }

  @override
  void dispose() {
    _bgDisposer.cancel();
    _statusDisposer.cancel();
    super.dispose();
  }

  Future<void> _createRunRecord(String runId) async {
    final newRun = Run(
      id: runId,
      fcmToken: tokenText,
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
          fcmToken: tokenText,
          startTime: DateTime.now(),
          route: [],
          photos: [],
          status: 'running',
          url: '$baseUrl$runId',
        ),
      );
    }
  }

  Future<void> _updateRoute() async {
    final runId = await _getRunId();

    if (runId != null) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      GeoPoint currentLocation =
          GeoPoint(position.latitude, position.longitude);

      await FirestoreHelper.instance.addLocationToRoute(runId, currentLocation);
    }
  }

  Future<void> _updateRunEndTime() async {
    final runId = await _getRunId();
    if (runId != null) {
      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final runRef =
              FirebaseFirestore.instance.collection("runs").doc(runId);
          final runSnapshot = await transaction.get(runRef);

          if (runSnapshot.exists) {
            transaction.update(runRef, {
              'endTime': DateTime.now(),
              'status': 'completed',
            });
          }
        });

        // 正常終了時に runId を削除
        await _removeRunId();
      } catch (e) {
        // エラーハンドリング
        print('Error updating run end time: $e');
        await Sentry.captureException(e);
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

      if (photo == null) {
        return;
      }

      var imageUrl =
          await FirestoreHelper.instance.uploadImageToStorage(photo.path);

      final runId = await _getRunId();

      if (runId != null) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        GeoPoint currentLocation =
            GeoPoint(position.latitude, position.longitude);

        final newPhoto = RunPhoto(
          photoUrl: imageUrl,
          location: currentLocation,
          timestamp: DateTime.now(),
        );

        await FirestoreHelper.instance.addPhotoToRun(runId, newPhoto);
      }
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Home")),
        body: SafeArea(
          child: Stack(children: [
            Container(
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

                        await _saveRunId(newId);
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
                                  const SnackBar(
                                      content: Text("URLをクリップボードにコピーしました")),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    ElevatedButton.icon(
                      onPressed: () async {
                        await requestLocationPermission();
                        await _updateRunStartTime();
                        await _updateRoute();
                        await BackgroundTask.instance.start();
                      },
                      icon: const Icon(
                        Icons.play_arrow,
                      ),
                      label: const Text("ランニング開始"),
                    ),
                    ElevatedButton.icon(
                      onPressed: url.isNotEmpty
                          ? () async {
                              await _takePicture();
                            }
                          : null,
                      icon: const Icon(
                        Icons.camera,
                      ),
                      label: const Text("写真を撮る"),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _updateRunEndTime();
                    await BackgroundTask.instance.stop();
                  },
                  icon: const Icon(
                    Icons.stop,
                  ),
                  label: const Text("ランニング終了"),
                ),
              ),
            ),
          ]),
        ));
  }
}
