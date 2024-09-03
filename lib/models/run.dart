import 'package:cloud_firestore/cloud_firestore.dart';

class Run {
  String id;
  DateTime startTime;
  DateTime? endTime;
  List<GeoPoint> route;
  List<RunPhoto> photos;
  String status;
  String url;

  Run({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.route,
    required this.photos,
    required this.status,
    required this.url,
  });

  factory Run.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Run(
      id: data?['id'],
      startTime: (data?['startTime'] as Timestamp).toDate(),
      endTime: data?['endTime'] != null
          ? (data?['endTime'] as Timestamp).toDate()
          : null,
      route: List<GeoPoint>.from(data?['route'] ?? []),
      photos: (data?['photos'] as List<dynamic>?)
              ?.map((photo) => RunPhoto.fromMap(photo))
              .toList() ??
          [],
      status: data?['status'],
      url: data?['url'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "id": id,
      "startTime": Timestamp.fromDate(startTime),
      "endTime": endTime != null ? Timestamp.fromDate(endTime!) : null,
      "route": route,
      "photos": photos.map((photo) => photo.toMap()).toList(),
      "status": status,
      "url": url,
    };
  }
}

class RunPhoto {
  String photoUrl;
  GeoPoint location;
  DateTime timestamp;

  RunPhoto({
    required this.photoUrl,
    required this.location,
    required this.timestamp,
  });

  factory RunPhoto.fromMap(Map<String, dynamic> map) {
    return RunPhoto(
      photoUrl: map['photoUrl'],
      location: map['location'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "photoUrl": photoUrl,
      "location": location,
      "timestamp": Timestamp.fromDate(timestamp),
    };
  }
}
