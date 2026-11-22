/// Модели данных, которые приходят с REST API.
/// JSON совпадает с DTO на бэкенде (camelCase).
library;

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
      };

  AppUser copyWith({String? fullName, String? phone}) => AppUser(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email,
        phone: phone ?? this.phone,
      );
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.title,
    required this.slug,
    required this.icon,
  });

  final String id;
  final String title;
  final String slug;
  final String icon;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) => ServiceCategory(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        icon: json['icon'] as String? ?? '',
      );
}

class Master {
  const Master({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.rating,
  });

  final String id;
  final String fullName;
  final String specialization;
  final double rating;

  String get initials {
    final parts = fullName.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  factory Master.fromJson(Map<String, dynamic> json) => Master(
        id: json['id'] as String,
        fullName: json['fullName'] as String? ?? '',
        specialization: json['specialization'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
      );
}

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.categoryTitle,
    required this.categorySlug,
    required this.categoryIcon,
    required this.masters,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final int durationMinutes;
  final String categoryTitle;
  final String categorySlug;
  final String categoryIcon;
  final List<Master> masters;

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        categoryTitle: json['categoryTitle'] as String? ?? '',
        categorySlug: json['categorySlug'] as String? ?? '',
        categoryIcon: json['categoryIcon'] as String? ?? '',
        masters: (json['masters'] as List<dynamic>? ?? const [])
            .map((item) => Master.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class ServiceDetails {
  const ServiceDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.category,
    required this.masters,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final int durationMinutes;
  final ServiceCategory category;
  final List<Master> masters;

  factory ServiceDetails.fromJson(Map<String, dynamic> json) => ServiceDetails(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        category: ServiceCategory.fromJson(json['category'] as Map<String, dynamic>),
        masters: (json['masters'] as List<dynamic>? ?? const [])
            .map((item) => Master.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class Slot {
  const Slot({
    required this.masterId,
    required this.masterName,
    required this.startAt,
  });

  final String masterId;
  final String masterName;
  final DateTime startAt;

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
        masterId: json['masterId'] as String,
        masterName: json['masterName'] as String? ?? '',
        startAt: DateTime.parse(json['startAt'] as String).toLocal(),
      );
}

class ServiceSlots {
  const ServiceSlots({
    required this.serviceId,
    required this.date,
    required this.durationMinutes,
    required this.slots,
  });

  final String serviceId;
  final String date;
  final int durationMinutes;
  final List<Slot> slots;

  factory ServiceSlots.fromJson(Map<String, dynamic> json) => ServiceSlots(
        serviceId: json['serviceId'] as String,
        date: json['date'] as String? ?? '',
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        slots: (json['slots'] as List<dynamic>? ?? const [])
            .map((item) => Slot.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class Booking {
  const Booking({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.masterId,
    required this.masterName,
    required this.startAt,
    required this.endAt,
    required this.price,
    required this.status,
    required this.comment,
  });

  final String id;
  final String serviceId;
  final String serviceTitle;
  final String masterId;
  final String masterName;
  final DateTime startAt;
  final DateTime endAt;
  final double price;
  final String status;
  final String? comment;

  bool get isCancelled => status == 'cancelled';
  bool get isUpcoming => !isCancelled && startAt.isAfter(DateTime.now());

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        serviceId: json['serviceId'] as String? ?? '',
        serviceTitle: json['serviceTitle'] as String? ?? '',
        masterId: json['masterId'] as String? ?? '',
        masterName: json['masterName'] as String? ?? '',
        startAt: DateTime.parse(json['startAt'] as String).toLocal(),
        endAt: DateTime.parse(json['endAt'] as String).toLocal(),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'active',
        comment: json['comment'] as String?,
      );
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AppUser user;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String,
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class PagedServices {
  const PagedServices({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<ServiceItem> items;
  final int total;
  final int page;
  final int pageSize;

  factory PagedServices.fromJson(Map<String, dynamic> json) => PagedServices(
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((item) => ServiceItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num?)?.toInt() ?? 0,
        page: (json['page'] as num?)?.toInt() ?? 1,
        pageSize: (json['pageSize'] as num?)?.toInt() ?? 12,
      );
}
