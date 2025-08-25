import 'package:fitness/models/workoutItem_model.dart';

class WorkOut {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? name;
  final double duration; // double (number, double)
  final String? description;
  final String? image;
  final bool isDeleted;
  final List<WorkOutItem>? workOutItems;
  final String consumerId;
  final String consumer;

  WorkOut({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.name,
    required this.duration,
    this.description,
    this.image,
    required this.isDeleted,
    this.workOutItems,
    required this.consumerId,
    required this.consumer,
  });

  factory WorkOut.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw Exception('Cannot create WorkOut from null data');
    }

    try {
      return WorkOut(
        id: json['id']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        name: json['name']?.toString(),
        duration: _parseDouble(json['duration']) ?? 0.0,
        description: json['description']?.toString(),
        image: json['image']?.toString(),
        isDeleted: json['isDeleted'] == true,
        workOutItems: json['workOutItems'] != null
            ? _parseWorkOutItems(json['workOutItems'])
            : null,
        consumerId: json['consumerId']?.toString() ?? '',
        consumer: json['consumer']?.toString() ?? '',
      );
    } catch (e) {
      throw Exception('Error parsing WorkOut from JSON: $e. JSON: $json');
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static List<WorkOutItem>? _parseWorkOutItems(dynamic workOutItemsData) {
    if (workOutItemsData == null) return null;

    try {
      if (workOutItemsData is List) {
        return workOutItemsData
            .where((item) => item != null)
            .map((item) => WorkOutItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // If parsing fails, return empty list instead of null
      return <WorkOutItem>[];
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'name': name,
      'duration': duration,
      'description': description,
      'image': image,
      'isDeleted': isDeleted,
      'workOutItems': workOutItems?.map((e) => e.toJson()).toList(),
      'consumerId': consumerId,
      'consumer': consumer,
    };
  }
}
