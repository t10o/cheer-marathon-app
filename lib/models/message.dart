import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String id;
  String runId;
  String message;
  DateTime timestamp;

  Message({
    required this.id,
    required this.runId,
    required this.message,
    required this.timestamp,
  });

  factory Message.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return Message(
      id: snapshot.id,
      runId: data?['runId'],
      message: data?['message'],
      timestamp: (data?['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "runId": runId,
      "message": message,
      "timestamp": Timestamp.fromDate(timestamp),
    };
  }
}
