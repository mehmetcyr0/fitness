import 'exercise_model.dart';

class WorkOutItem {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String exerciseId;
  final Exercise exercise;
  final String workOutId;
  final Unit unit; // enum
  final int set;
  final int quantity;
  final bool isDeleted;

  WorkOutItem({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.exerciseId,
    required this.exercise,
    required this.workOutId,
    required this.unit,
    required this.set,
    required this.quantity,
    required this.isDeleted,
  });

  factory WorkOutItem.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw Exception('Cannot create WorkOutItem from null data');
    }

    try {
      return WorkOutItem(
        id: json['id']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        exerciseId: json['exerciseId']?.toString() ?? '',
        exercise: json['exercise'] != null
            ? Exercise.fromJson(json['exercise'] as Map<String, dynamic>)
            : Exercise(
                id: '',
                createdAt: DateTime.now(),
                isDeleted: false,
                consumerId: '',
                consumer: '',
                name: 'Unknown Exercise',
              ),
        workOutId: json['workOutId']?.toString() ?? '',
        unit: _parseUnit(json['unit']) ?? Unit.reps,
        set: _parseInt(json['set']) ?? 0,
        quantity: _parseInt(json['quantity']) ?? 0,
        isDeleted: json['isDeleted'] == true,
      );
    } catch (e) {
      throw Exception('Error parsing WorkOutItem from JSON: $e. JSON: $json');
    }
  }

  static Unit? _parseUnit(dynamic value) {
    if (value == null) return null;

    int? unitIndex;
    if (value is int) {
      unitIndex = value;
    } else if (value is String) {
      unitIndex = int.tryParse(value);
    }

    if (unitIndex != null && unitIndex >= 0 && unitIndex < Unit.values.length) {
      switch (unitIndex) {
        case 0:
          return Unit.reps;
        case 1:
          return Unit.distance;
        case 2:
          return Unit.sec;
        default:
          return Unit.reps; // Default fallback
      }
    }

    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'exerciseId': exerciseId,
      'exercise': exercise.toJson(),
      'workOutId': workOutId,
      'unit': unit.index,
      'set': set,
      'quantity': quantity,
      'isDeleted': isDeleted,
    };
  }
}

enum Unit {
  reps, // 0 - tekrar
  distance, // 1 - mesafe
  sec, // 2 - saniye
}
