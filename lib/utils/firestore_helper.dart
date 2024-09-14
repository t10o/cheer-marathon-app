import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/location.dart';
import '../models/message.dart';
import '../models/run.dart';

class FirestoreHelper {
  // FirestoreHelperをインスタンス化する
  static final FirestoreHelper instance = FirestoreHelper._createInstance();

  FirestoreHelper._createInstance();

  // 全てのランデータを取得する
  Future<List<Run>> selectAllRuns() async {
    final db = FirebaseFirestore.instance;
    final snapshot = db.collection("runs").withConverter(
          fromFirestore: Run.fromFirestore,
          toFirestore: (Run run, _) => run.toFirestore(),
        );
    final runs = await snapshot.get();
    return runs.docs.map((doc) => doc.data()).toList();
  }

  // 特定のランIDに基づいてランデータを取得する
  Future<Run?> getRunData(String runId) async {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection("runs").doc(runId).withConverter(
          fromFirestore: Run.fromFirestore,
          toFirestore: (Run run, _) => run.toFirestore(),
        );
    final runData = await docRef.get();
    return runData.data();
  }

  // 新しいランデータを挿入または更新する
  Future<void> insertRun(Run run) async {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection("runs").doc(run.id).withConverter(
          fromFirestore: Run.fromFirestore,
          toFirestore: (Run run, options) => run.toFirestore(),
        );
    await docRef.set(run);
  }

  // ランデータを削除する
  Future<void> deleteRun(String runId) async {
    final db = FirebaseFirestore.instance;
    await db.collection("runs").doc(runId).delete();
  }

  // 特定のランの全ての位置情報を取得する
  Future<List<Location>> selectAllLocations(String runId) async {
    final db = FirebaseFirestore.instance;
    final snapshot =
        db.collection("runs").doc(runId).collection("locations").withConverter(
              fromFirestore: Location.fromFirestore,
              toFirestore: (Location location, _) => location.toFirestore(),
            );
    final locations = await snapshot.get();
    return locations.docs.map((doc) => doc.data()).toList();
  }

  // 特定の位置情報を取得する
  Future<Location?> getLocationData(String runId, String locationId) async {
    final db = FirebaseFirestore.instance;
    final docRef = db
        .collection("runs")
        .doc(runId)
        .collection("locations")
        .doc(locationId)
        .withConverter(
          fromFirestore: Location.fromFirestore,
          toFirestore: (Location location, _) => location.toFirestore(),
        );
    final locationData = await docRef.get();
    return locationData.data();
  }

  // 位置情報を挿入または更新する
  Future<void> insertLocation(String runId, Location location) async {
    final db = FirebaseFirestore.instance;
    final docRef = db
        .collection("runs")
        .doc(runId)
        .collection("locations")
        .doc(location.id)
        .withConverter(
          fromFirestore: Location.fromFirestore,
          toFirestore: (Location location, options) => location.toFirestore(),
        );
    await docRef.set(location);
  }

  Future<void> addLocationToRoute(String runId, GeoPoint newLocation) async {
    final db = FirebaseFirestore.instance;
    final runRef = db.collection("runs").doc(runId);

    await runRef.update({
      "route": FieldValue.arrayUnion([newLocation])
    });
  }

  Future<void> addPhotoToRun(String runId, RunPhoto newPhoto) async {
    final db = FirebaseFirestore.instance;
    final runRef = db.collection("runs").doc(runId);

    await runRef.update({
      "photos": FieldValue.arrayUnion([newPhoto.toMap()])
    });
  }

  // 位置情報を削除する
  Future<void> deleteLocation(String runId, String locationId) async {
    final db = FirebaseFirestore.instance;
    await db
        .collection("runs")
        .doc(runId)
        .collection("locations")
        .doc(locationId)
        .delete();
  }

  // 応援メッセージを取得する
  Future<List<Message>> selectAllMessages(String runId) async {
    final db = FirebaseFirestore.instance;
    final snapshot = db
        .collection("messages")
        .where('runId', isEqualTo: runId)
        .withConverter(
          fromFirestore: Message.fromFirestore,
          toFirestore: (Message message, _) => message.toFirestore(),
        );
    final messages = await snapshot.get();
    return messages.docs.map((doc) => doc.data()).toList();
  }

  // メッセージを挿入する
  Future<void> insertMessage(Message message) async {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection("messages").doc().withConverter(
          fromFirestore: Message.fromFirestore,
          toFirestore: (Message message, options) => message.toFirestore(),
        );
    await docRef.set(message);
  }

  // メッセージを削除する
  Future<void> deleteMessage(String messageId) async {
    final db = FirebaseFirestore.instance;
    await db.collection("messages").doc(messageId).delete();
  }

  Future<String> uploadImageToStorage(String imagePath) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef
          .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = imageRef.putFile(File(imagePath));

      await uploadTask.whenComplete(() {});

      final imageUrl = await imageRef.getDownloadURL();

      return imageUrl;
    } catch (e) {
      throw Exception(e);
    }
  }
}
