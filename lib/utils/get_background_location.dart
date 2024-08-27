import 'dart:isolate';
import 'dart:ui';

import 'package:background_locator_2/background_locator.dart';
import 'package:background_locator_2/location_dto.dart';
import 'package:background_locator_2/settings/android_settings.dart';
import 'package:background_locator_2/settings/ios_settings.dart';
import 'package:background_locator_2/settings/locator_settings.dart';
import 'package:cheer_on_runnner_app/import.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initPlatformState() async {
  await BackgroundLocator.initialize();
}

class LocationCallbackHandler {
  static const String isolateName = "LocatorIsolate";

  @pragma('vm:entry-point')
  static Future<void> _initCallback(Map<dynamic, dynamic> params) async {
    if (kDebugMode) {
      print('initCallback');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _disposeCallback() async {
    if (kDebugMode) {
      print('disposeCallback');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _callback(LocationDto locationDto) async {
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(locationDto.toJson());

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    final newLocation = GeoPoint(locationDto.latitude, locationDto.longitude);

    final prefs = await SharedPreferences.getInstance();
    String? runId = prefs.getString('currentRunId');

    if (runId != null) {
      await FirestoreHelper.instance.addLocationToRoute(runId, newLocation);
    } else {
      print("runIdが設定されていません");
    }
  }

  static void startLocationService() {
    BackgroundLocator.registerLocationUpdate(
      _callback,
      initCallback: _initCallback,
      disposeCallback: _disposeCallback,
      autoStop: false,
      iosSettings: const IOSSettings(
          accuracy: LocationAccuracy.NAVIGATION, distanceFilter: 0),
      androidSettings: const AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 5,
        distanceFilter: 0,
      ),
    );
  }
}
