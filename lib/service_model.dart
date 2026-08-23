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
  final String? membershipTier;
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
    this.membershipTier,
    this.createdAt,
    this.updatedAt,
  });

  /// Prefer the server's membership value. Price is only a legacy fallback.
  bool get isPremium {
    final tier = (membershipTier ?? '').trim().toLowerCase();
    if (tier.isNotEmpty) {
      return tier == 'premium' || tier == '1' || tier == 'true';
    }
    return (price ?? 0) > premiumPriceThreshold;
  }

  String? get priceTier {
    if (price == null && (membershipTier ?? '').trim().isEmpty) {
      return null;
    }
    return isPremium ? 'Premium' : 'Standard';
  }

  String? get localAssetImage {
    return assetForLabel(
      [
        serviceName,
        companyName,
        categorys ?? '',
        subcategory ?? '',
        description ?? '',
        shortDescription ?? '',
      ].join(' '),
    );
  }

  static String? assetForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('hospital') ||
        l.contains('clinic') ||
        l.contains('doctor') ||
        l.contains('medical')) {
      return 'assets/images/hospitals.gif';
    }
    if (l.contains('cater') ||
        l.contains('food') ||
        l.contains('restaurant') ||
        l.contains('bar')) {
      return 'assets/images/catering.gif';
    }
    if (l.contains('banquet') ||
        l.contains('marriage') ||
        l.contains('wedding') ||
        l.contains('event')) {
      return 'assets/images/marriage.gif';
    }
    if (l.contains('resort') ||
        l.contains('villa') ||
        l.contains('house') ||
        l.contains('estate') ||
        l.contains('property') ||
        l.contains('real estate')) {
      return 'assets/images/big_house.gif';
    }
    if (l.contains('packer') ||
        l.contains('mover') ||
        l.contains('shift') ||
        l.contains('truck')) {
      return 'assets/images/packers.gif';
    }
    if (l.contains('adventure') ||
        l.contains('explore') ||
        l.contains('tour') ||
        l.contains('travel')) {
      return 'assets/images/girl_exploring.gif';
    }
    if (l.contains('spa') ||
        l.contains('salon') ||
        l.contains('massage') ||
        l.contains('beauty') ||
        l.contains('hair')) {
      return 'assets/images/massage.gif';
    }
    if (l.contains('courier') ||
        l.contains('delivery') ||
        l.contains('scooter')) {
      return 'assets/images/scooter.png';
    }
    return null;
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    try {
      return Service(
        // The keys must match your PHP JSON output EXACTLY
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString(),
        companyName: (json['companyname'] ?? json['company_name'] ?? '')
            .toString()
            .trim(),
        serviceName: (json['servicename'] ?? json['service_name'] ?? '')
            .toString()
            .trim(),
        locations: json['locations']?.toString(),
        categorys:
            (json['category_id'] ??
                    json['categorys'] ??
                    json['category'] ??
                    json['categories'])
                ?.toString(),
        subcategory:
            (json['subcategory_name'] ??
                    json['subname'] ??
                    json['sub_category_name'] ??
                    json['subcategory'])
                ?.toString(),
        price: _parseDouble(json['price']),
        perPrice: json['perprice']?.toString(),
        allHour:
            json['allhour'] == '1' ||
            json['allhour'] == 1 ||
            json['allhour'] == true,
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
        isActive:
            json['is_active'] == '1' ||
            json['is_active'] == 1 ||
            json['is_active'] == true,
        avrRat: _parseDouble(json['avr_rat']),
        viewsCont: _parseInt(json['viewscont']),
        email: json['email']?.toString(),
        website:
            (json['website'] ??
                    json['bwebsite'] ??
                    json['businesswebsite'] ??
                    json['business_website'])
                ?.toString(),
        facebook: json['facebook']?.toString(),
        twitter: json['twitter']?.toString(),
        instagram: json['instagram']?.toString(),
        linkedin: json['linkedin']?.toString(),
        slug: json['slug']?.toString(),
        membershipTier:
            (json['vendor_tier'] ??
                    json['membership_tier'] ??
                    json['tier'] ??
                    json['plist'] ??
                    json['is_premium'])
                ?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
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
