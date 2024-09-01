import 'package:background_task/background_task.dart';
import 'package:cheer_on_runnner_app/utils/firestore_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'home_page.dart';

@pragma('vm:entry-point')
void backgroundHandler(Location data) {
  debugPrint('backgroundHandler: ${DateTime.now()}, $data');
  Future(() async {
    print('backgroundHandler');

    // Firebaseが初期化されていない場合、初期化を行う
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // 緯度または経度がnullまたは無効な値(0)の場合、処理をスキップする
    if (data.lat == null || data.lng == null || data.lat == 0.0 || data.lng == 0.0) {
      print('Invalid location data, skipping...');
      return;
    }

    // 有効な位置情報データをFirestoreに保存する
    final newLocation = GeoPoint(data.lat!, data.lng!);

    final prefs = await SharedPreferences.getInstance();
    String? runId = prefs.getString('currentRunId');

    if (runId != null) {
      await FirestoreHelper.instance.addLocationToRoute(runId, newLocation);
    } else {
      print("runIdが設定されていません");
    }
  });
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundTask.instance.setBackgroundHandler(backgroundHandler);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cheer To Runner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
