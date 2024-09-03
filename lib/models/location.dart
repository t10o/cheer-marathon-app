import 'package:cloud_firestore/cloud_firestore.dart';

class Location {
  String id;
  DateTime timestamp;
  GeoPoint location;
  double? speed;

  Location({
    required this.id,
    required this.timestamp,
    required this.location,
    this.speed,
  });

  factory Location.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Location(
      id: snapshot.id,
      timestamp: (data?['timestamp'] as Timestamp).toDate(),
      location: data?['location'],
      speed: data?['speed'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "timestamp": Timestamp.fromDate(timestamp),
      "location": location,
      "speed": speed,
    };
  }
}
