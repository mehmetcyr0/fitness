class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationDays;
  final int? maxEntries; // null means unlimited
  final List<String> features;
  final bool isPopular;
  final String currency;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    this.maxEntries,
    required this.features,
    this.isPopular = false,
    this.currency = 'TL',
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
      maxEntries: (json['maxEntries'] as num?)?.toInt(),
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      isPopular: json['isPopular'] == true,
      currency: json['currency']?.toString() ?? 'TL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'durationDays': durationDays,
      'maxEntries': maxEntries,
      'features': features,
      'isPopular': isPopular,
      'currency': currency,
    };
  }

  String get formattedPrice => '${price.toStringAsFixed(0)} $currency';
  
  String get durationText {
    if (durationDays >= 365) {
      return '${(durationDays / 365).round()} Yıl';
    } else if (durationDays >= 30) {
      return '${(durationDays / 30).round()} Ay';
    } else {
      return '$durationDays Gün';
    }
  }
}

class UserSubscription {
  final String id;
  final String userId;
  final String planId;
  final SubscriptionPlan? plan;
  final DateTime startDate;
  final DateTime endDate;
  final int? remainingEntries;
  final bool isActive;
  final SubscriptionStatus status;
  final DateTime createdAt;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    this.plan,
    required this.startDate,
    required this.endDate,
    this.remainingEntries,
    required this.isActive,
    required this.status,
    required this.createdAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      planId: json['planId']?.toString() ?? '',
      plan: json['plan'] != null 
          ? SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>)
          : null,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : DateTime.now().add(const Duration(days: 30)),
      remainingEntries: (json['remainingEntries'] as num?)?.toInt(),
      isActive: json['isActive'] == true,
      status: _parseStatus(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  static SubscriptionStatus _parseStatus(dynamic value) {
    if (value == null) return SubscriptionStatus.inactive;
    
    switch (value.toString().toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'pending':
        return SubscriptionStatus.pending;
      default:
        return SubscriptionStatus.inactive;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'plan': plan?.toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'remainingEntries': remainingEntries,
      'isActive': isActive,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int get remainingDays {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return endDate.difference(now).inDays;
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  
  bool get isExpiringSoon => remainingDays <= 7 && remainingDays > 0;
}

enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  pending,
  inactive,
}

class PaymentMethod {
  final String id;
  final String name;
  final String icon;
  final bool isEnabled;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    this.isEnabled = true,
  });
}