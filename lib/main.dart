import 'dart:math';

import 'package:background_task/background_task.dart';
import 'package:cheer_on_runnner_app/utils/firestore_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'home_page.dart';

GeoPoint? lastHandlerLocation;

@pragma('vm:entry-point')
void backgroundHandler(Location data) {
  debugPrint('backgroundHandler: ${DateTime.now()}, $data');
  Future(() async {
    // Firebaseが初期化されていない場合、初期化を行う
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // 緯度または経度がnullまたは無効な値(0)の場合、処理をスキップする
    if (data.lat == null ||
        data.lng == null ||
        data.lat == 0.0 ||
        data.lng == 0.0) {
      if (kDebugMode) {
        print('Invalid location data, skipping...');
      }
      return;
    }

    lastHandlerLocation ??= GeoPoint(data.lat!, data.lng!);

    double deg2rad(double deg) {
      return deg * (pi / 180);
    }

    // 距離を計算する関数
    double calculateDistance(
        double lat1, double lon1, double lat2, double lon2) {
      const double earthRadius = 6371000;
      double dLat = deg2rad(lat2 - lat1);
      double dLon = deg2rad(lon2 - lon1);
      double a = sin(dLat / 2) * sin(dLat / 2) +
          cos(deg2rad(lat1)) *
              cos(deg2rad(lat2)) *
              sin(dLon / 2) *
              sin(dLon / 2);
      double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      return earthRadius * c;
    }

    final newLocation = GeoPoint(data.lat!, data.lng!);

    double? prevLat = lastHandlerLocation?.latitude;
    double? prevLng = lastHandlerLocation?.longitude;

    // 前回取得した座標と今回取得した座標の差が大きい場合、無視する
    if (prevLat != null && prevLng != null) {
      double distance =
          calculateDistance(prevLat, prevLng, data.lat!, data.lng!);
      lastHandlerLocation = GeoPoint(data.lat!, data.lng!);
      if (distance > 30) {
        if (kDebugMode) {
          print('30m以上の移動のため、位置情報をスキップします');
        }
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    String? runId = prefs.getString('currentRunId');

    // 前回の位置情報を取得
    double? lastLat = prefs.getDouble('lastLat');
    double? lastLng = prefs.getDouble('lastLng');

    // 10メートル以上の移動があるかチェック
    if (lastLat != null && lastLng != null) {
      double distance =
          calculateDistance(lastLat, lastLng, data.lat!, data.lng!);
      if (distance < 10) {
        if (kDebugMode) {
          print('10m以内の移動のため、位置情報をスキップします');
        }
        return;
      }
    }

    // Firestoreに位置情報を保存
    if (runId != null) {
      await FirestoreHelper.instance.addLocationToRoute(runId, newLocation);
    } else {
      if (kDebugMode) {
        print("runIdが設定されていません");
      }
    }

    // 新しい位置情報を保存
    await prefs.setDouble('lastLat', data.lat!);
    await prefs.setDouble('lastLng', data.lng!);
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
