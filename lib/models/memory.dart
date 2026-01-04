import 'package:uuid/uuid.dart';

class Memory {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime date;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? audioUrl;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  Memory({
    String? id,
    required this.userId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.date,
    this.location,
    this.latitude,
    this.longitude,
    this.audioUrl,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert to Firebase-compatible map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'date': date.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'audioUrl': audioUrl,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Firebase data
  factory Memory.fromMap(Map<String, dynamic> map) {
    return Memory(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      imageUrl: map['imageUrl'] as String?,
      date: DateTime.parse(map['date'] as String),
      location: map['location'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      audioUrl: map['audioUrl'] as String?,
      isFavorite: map['isFavorite'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Copy with modifications
  Memory copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? date,
    String? location,
    double? latitude,
    double? longitude,
    String? audioUrl,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Memory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      audioUrl: audioUrl ?? this.audioUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
