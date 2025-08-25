import 'workout_model.dart';

class Exercise {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? name;
  final String? description;
  final String? image;
  final String? video;
  final bool isDeleted;
  final List<WorkOut>? workOuts;
  final String consumerId;
  final String consumer;

  Exercise({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.name,
    this.description,
    this.image,
    required this.consumer,
    this.video,
    required this.isDeleted,
    this.workOuts,
    required this.consumerId,
  });

  factory Exercise.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw Exception('Cannot create Exercise from null data');
    }

    try {
      return Exercise(
        id: json['id']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        name: json['name']?.toString(),
        description: json['description']?.toString(),
        image: json['image']?.toString(),
        video: json['video']?.toString(),
        isDeleted: json['isDeleted'] == true,
        workOuts: json['workOuts'] != null
            ? _parseWorkOuts(json['workOuts'])
            : null,
        consumerId: json['consumerId']?.toString() ?? '',
        consumer: json['consumer']?.toString() ?? '',
      );
    } catch (e) {
      throw Exception('Error parsing Exercise from JSON: $e. JSON: $json');
    }
  }

  static List<WorkOut>? _parseWorkOuts(dynamic workOutsData) {
    if (workOutsData == null) return null;

    try {
      if (workOutsData is List) {
        return workOutsData
            .where((item) => item != null)
            .map((item) => WorkOut.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // If parsing fails, return empty list instead of null
      return <WorkOut>[];
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'name': name,
      'description': description,
      'image': image,
      'video': video,
      'isDeleted': isDeleted,
      'workOuts': workOuts?.map((e) => e.toJson()).toList(),
      'consumerId': consumerId,
      'consumer': consumer,
    };
  }
}
