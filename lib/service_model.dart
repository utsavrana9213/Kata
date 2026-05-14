import 'dart:convert';

class Service {
  static const double premiumPriceThreshold = 2000;

  final String id;
  final String? userId;
  final String companyName;
  final String serviceName;
  final String? locations;
  final String? categorys;
  final String? subcategory;
  final double? price;
  final String? perPrice;
  final bool? allHour;
  final double? ofPrice;
  final int? percen;
  final String? workingDays;
  final String? openTime;
  final String? closeTime;
  final String? spWorkingDay;
  final String? spOpenTime;
  final String? spCloseTime;
  final String? number;
  final String? imgFold;
  final String? dImgFold;
  final String? address;
  final String? description;
  final String? shortDescription;
  final String? gmap;
  final double? lati;
  final double? lngi;
  final String? plist;
  final bool? isActive;
  final double? avrRat;
  final int? viewsCont;
  final String? email;
  final String? website;
  final String? facebook;
  final String? twitter;
  final String? instagram;
  final String? linkedin;
  final String? slug;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Service({
    required this.id,
    this.userId,
    required this.companyName,
    required this.serviceName,
    this.locations,
    this.categorys,
    this.subcategory,
    this.price,
    this.perPrice,
    this.allHour,
    this.ofPrice,
    this.percen,
    this.workingDays,
    this.openTime,
    this.closeTime,
    this.spWorkingDay,
    this.spOpenTime,
    this.spCloseTime,
    this.number,
    this.imgFold,
    this.dImgFold,
    this.address,
    this.description,
    this.shortDescription,
    this.gmap,
    this.lati,
    this.lngi,
    this.plist,
    this.isActive,
    this.avrRat,
    this.viewsCont,
    this.email,
    this.website,
    this.facebook,
    this.twitter,
    this.instagram,
    this.linkedin,
    this.slug,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPremium => (price ?? 0) > premiumPriceThreshold;

  String? get priceTier {
    final p = price;
    if (p == null) return null;
    return p > premiumPriceThreshold ? 'Premium' : 'Standard';
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    try {
      return Service(
        // The keys must match your PHP JSON output EXACTLY
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString(),
        companyName: (json['companyname'] ?? json['company_name'] ?? 'Unknown Company').toString(),
        serviceName: (json['servicename'] ?? json['service_name'] ?? 'Unknown Service').toString(),
        locations: json['locations']?.toString(),
        categorys: (json['category_id'] ?? json['categorys'] ?? json['category'] ?? json['categories'])?.toString(),
        subcategory: json['subcategory']?.toString(),
        price: _parseDouble(json['price']),
        perPrice: json['perprice']?.toString(),
        allHour: json['allhour'] == '1' || json['allhour'] == 1 || json['allhour'] == true,
        ofPrice: _parseDouble(json['ofprice']),
        percen: _parseInt(json['percen']),
        workingDays: json['workingdays']?.toString(),
        openTime: json['opentime']?.toString(),
        closeTime: json['closetime']?.toString(),
        spWorkingDay: json['spworkingday']?.toString(),
        spOpenTime: json['spopentime']?.toString(),
        spCloseTime: json['spclosetime']?.toString(),
        number: json['number']?.toString(),
        imgFold: json['imgfold']?.toString(),
        dImgFold: json['dimgfold']?.toString(),
        address: json['address']?.toString(),
        description: json['description']?.toString(),
        shortDescription: json['shortdescription']?.toString(),
        gmap: json['gmap']?.toString(),
        lati: _parseDouble(json['lati']),
        lngi: _parseDouble(json['lngi']),
        plist: json['plist']?.toString(),
        isActive: json['is_active'] == '1' || json['is_active'] == 1 || json['is_active'] == true,
        avrRat: _parseDouble(json['avr_rat']),
        viewsCont: _parseInt(json['viewscont']),
        email: json['email']?.toString(),
        website: json['website']?.toString(),
        facebook: json['facebook']?.toString(),
        twitter: json['twitter']?.toString(),
        instagram: json['instagram']?.toString(),
        linkedin: json['linkedin']?.toString(),
        slug: json['slug']?.toString(),
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Helper methods to safely parse numbers from strings
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
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

  String? get primaryImageUrl {
    final candidates = <String>[];
    final d = (dImgFold ?? '').trim();
    if (d.isNotEmpty) candidates.add(d);

    final raw = (imgFold ?? '').trim();
    if (raw.isNotEmpty) {
      candidates.addAll(_expandImgFoldCandidates(raw));
    }

    for (final c in candidates) {
      final v = c.trim();
      if (v.isEmpty) continue;
      if (v.startsWith('http://') || v.startsWith('https://')) return v;
      final normalized = v.startsWith('/') ? v.substring(1) : v;
      return 'https://servekeen.com/$normalized';
    }
    return null;
  }

  static List<String> _expandImgFoldCandidates(String raw) {
    final list = <String>[];
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return list;

    if (trimmed.startsWith('[')) {
      try {
        final decoded = json.decode(trimmed);
        if (decoded is List) {
          for (final e in decoded) {
            final v = e.toString().trim();
            if (v.isNotEmpty) list.add(v);
          }
          return list;
        }
      } catch (_) {}
    }

    if (trimmed.contains(',')) {
      for (final part in trimmed.split(',')) {
        final v = part.trim();
        if (v.isNotEmpty) list.add(v);
      }
      return list;
    }

    list.add(trimmed);
    return list;
  }
}
