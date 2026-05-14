import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:servekeen/service_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:servekeen/data/hierarchy_repository.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/theme/palette.dart';
import 'package:servekeen/widgets/dot_grid_painter.dart';

class ServiceDetailPage extends StatefulWidget {
  final Service service;
  const ServiceDetailPage({super.key, required this.service});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  late final List<String> images;
  String? _categoryName;
  List<String> _subNames = [];
  double? _avgRating;
  int? _ratingCount;
  int? _myRating;
  bool _showReviewForm = true;
  Map<String, dynamic>? _myReview;
  final TextEditingController _ratingNameController = TextEditingController();
  final TextEditingController _ratingReviewController = TextEditingController();
  int _ratingReviewWords = 0;
  List<Map<String, dynamic>> _serviceReviews = [];
  bool _loadingRating = false;
  bool _submittingRating = false;
  String? _ratingStatusText;
  bool _ratingStatusIsError = false;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    images = _extractImages(widget.service);
    _resolveCategoryAndSubs();
    ApiService().trackServiceEvent(widget.service.id, 'view_details');
    _avgRating = widget.service.avrRat;
    _ratingStatusText = 'Tap a star to rate';
    final u = ApiService().currentUser;
    final name = (u?['name'] ?? u?['username'] ?? u?['full_name'] ?? '').toString().trim();
    if (name.isNotEmpty) _ratingNameController.text = name;
    _ratingReviewController.addListener(() {
      final next = _countWords(_ratingReviewController.text);
      if (next != _ratingReviewWords && mounted) {
        setState(() => _ratingReviewWords = next);
      }
    });
    _loadRating();
  }

  @override
  void dispose() {
    _ratingNameController.dispose();
    _ratingReviewController.dispose();
    super.dispose();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  int _countWords(String input) {
    final t = input.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).where((e) => e.trim().isNotEmpty).length;
  }

  String? get _currentUserId => ApiService().currentUser?['id']?.toString();

  bool get _hasMyRating => ApiService().isLoggedIn && (_myRating ?? 0) > 0;

  Map<String, dynamic>? _findMyReview(List<Map<String, dynamic>> reviews) {
    if (!_hasMyRating) return null;
    final uid = _currentUserId;
    if (uid != null && uid.trim().isNotEmpty) {
      for (final r in reviews) {
        final ru = (r['user_id'] ?? r['userId'] ?? '').toString().trim();
        if (ru.isNotEmpty && ru == uid.trim()) return r;
      }
    }
    final nameGuess = _ratingNameController.text.trim().toLowerCase();
    if (nameGuess.isNotEmpty) {
      for (final r in reviews) {
        final u = (r['username'] ?? r['name'] ?? '').toString().trim().toLowerCase();
        if (u.isNotEmpty && u == nameGuess) return r;
      }
    }
    final my = _myRating ?? 0;
    if (my > 0) {
      for (final r in reviews) {
        final rating = _toInt(r['rating'] ?? r['stars']) ?? 0;
        if (rating == my) return r;
      }
    }
    return null;
  }

  Future<void> _loadRating({bool keepStatusText = false}) async {
    final prevText = _ratingStatusText;
    final prevIsError = _ratingStatusIsError;
    setState(() {
      _loadingRating = true;
      if (!keepStatusText) _ratingStatusText = null;
      if (!keepStatusText) _ratingStatusIsError = false;
    });
    final res = await ApiService().fetchServiceRatingSummary(widget.service.id);
    if (!mounted) return;
    if (res['status'] == 'success') {
      final payload = (res['data'] ?? res['rating'] ?? res['stats'] ?? res) as Object?;
      final data = res['data'];
      final reviewsPayload = (res['reviews'] ?? (data is Map ? data['reviews'] : null) ?? (payload is Map ? payload['reviews'] : null)) as Object?;
      Map<String, dynamic>? m;
      if (payload is Map) m = payload.cast<String, dynamic>();
      final parsedReviews = <Map<String, dynamic>>[];
      if (reviewsPayload is List) {
        for (final item in reviewsPayload) {
          if (item is Map) parsedReviews.add(item.cast<String, dynamic>());
        }
      }
      if (m != null) {
        setState(() {
          final nextMyRating = _toInt(m?['my_rating'] ?? m?['user_rating'] ?? m?['rating']) ?? _myRating;
          _avgRating = _toDouble(m?['average'] ?? m?['avg'] ?? m?['avg_rating'] ?? m?['avr_rat']) ?? _avgRating;
          _ratingCount = _toInt(m?['count'] ?? m?['total'] ?? m?['ratings'] ?? m?['ratings_count']) ?? _ratingCount;
          _myRating = nextMyRating;
          _serviceReviews = parsedReviews;
          _myReview = _findMyReview(parsedReviews);
          final myText = (_myReview?['review_text'] ?? _myReview?['reviewText'] ?? _myReview?['description'] ?? _myReview?['review'] ?? '').toString().trim();
          if (ApiService().isLoggedIn && (nextMyRating ?? 0) > 0) {
            _showReviewForm = myText.isEmpty;
          } else {
            _showReviewForm = true;
          }
          _loadingRating = false;
          if (!keepStatusText) {
            _ratingStatusText = 'Tap a star to rate';
            _ratingStatusIsError = false;
          } else {
            _ratingStatusText = prevText;
            _ratingStatusIsError = prevIsError;
          }
        });
        return;
      }
    }
    setState(() {
      _loadingRating = false;
      if (!keepStatusText) {
        _ratingStatusText = (res['message'] ?? 'Failed to load rating').toString();
        _ratingStatusIsError = true;
      } else {
        _ratingStatusText = prevText;
        _ratingStatusIsError = prevIsError;
      }
    });
  }

  Future<void> _submitRating() async {
    if (_submittingRating) return;
    if (!ApiService().isLoggedIn) {
      setState(() {
        _ratingStatusText = 'Please login to rate this service.';
        _ratingStatusIsError = true;
      });
      return;
    }
    final rating = _myRating;
    if (rating == null || rating < 1 || rating > 5) {
      setState(() {
        _ratingStatusText = 'Please select a rating.';
        _ratingStatusIsError = true;
      });
      return;
    }
    final username = _ratingNameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _ratingStatusText = 'Please enter your name.';
        _ratingStatusIsError = true;
      });
      return;
    }
    final reviewText = _ratingReviewController.text.trim();
    final words = _countWords(reviewText);
    if (reviewText.isNotEmpty && words > 100) {
      setState(() {
        _ratingStatusText = 'Review must be 100 words or less.';
        _ratingStatusIsError = true;
      });
      return;
    }
    setState(() {
      _submittingRating = true;
      _ratingStatusText = null;
      _ratingStatusIsError = false;
    });
    final res = await ApiService().submitServiceRating(
      serviceId: widget.service.id,
      rating: rating,
      username: username,
      reviewText: reviewText,
    );
    if (!mounted) return;
    if (res['status'] == 'success') {
      final payload = (res['data'] ?? res['rating'] ?? res) as Object?;
      final data = res['data'];
      final reviewsPayload = (res['reviews'] ?? (data is Map ? data['reviews'] : null) ?? (payload is Map ? payload['reviews'] : null)) as Object?;
      if (payload is Map) {
        final m = payload.cast<String, dynamic>();
        final parsedReviews = <Map<String, dynamic>>[];
        if (reviewsPayload is List) {
          for (final item in reviewsPayload) {
            if (item is Map) parsedReviews.add(item.cast<String, dynamic>());
          }
        }
        setState(() {
          _avgRating = _toDouble(m['average'] ?? m['avg'] ?? m['avg_rating'] ?? m['avr_rat']) ?? _avgRating;
          _ratingCount = _toInt(m['count'] ?? m['total'] ?? m['ratings'] ?? m['ratings_count']) ?? _ratingCount;
          _myRating = _toInt(m['my_rating'] ?? m['user_rating'] ?? m['rating']) ?? _myRating;
          _serviceReviews = parsedReviews;
        });
      }
      setState(() {
        _submittingRating = false;
        _ratingStatusText = 'Thanks for rating!';
        _ratingStatusIsError = false;
        _showReviewForm = reviewText.isEmpty;
      });
      _ratingReviewController.clear();
      await _loadRating(keepStatusText: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thanks for rating!', style: GoogleFonts.poppins())),
      );
      return;
    }
    setState(() {
      _submittingRating = false;
      _ratingStatusText = (res['message'] ?? 'Failed to submit rating').toString();
      _ratingStatusIsError = true;
    });
  }

  List<String> _extractImages(Service s) {
    final list = <String>[];
    final d = s.dImgFold ?? '';
    if (d.isNotEmpty) list.add(d);
    final raw = s.imgFold ?? '';
    if (raw.isNotEmpty) {
      try {
        final arr = json.decode(raw);
        if (arr is List) {
          for (final e in arr) {
            final p = e.toString();
            if (p.isNotEmpty) list.add('images/service/${p.replaceAll('["', '').replaceAll('"]', '')}');
          }
        } else {
          list.add(raw);
        }
      } catch (_) {
        list.add(raw);
      }
    }
    final expanded = list.map((p) => p.startsWith('http') ? p : "https://servekeen.com/$p").toList();
    final unique = <String>[];
    for (final u in expanded) {
      if (!unique.contains(u)) unique.add(u);
    }
    return unique;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final derived = _deriveLatLng(s);
    final priceStr = s.price != null ? NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(s.price) : 'Price on request';
    final avg = _avgRating ?? s.avrRat;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.serviceName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppPalette.deepBlue)),
        backgroundColor: Colors.white,
        foregroundColor: AppPalette.deepBlue,
        centerTitle: true,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppPalette.softBlendBackground,
                      AppPalette.lightBlueTint,
                      AppPalette.lightPinkTint,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(opacity: 0.06, child: CustomPaint(painter: DotGridPainter())),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildImages(),
              const SizedBox(height: 12),
              _buildHeader(s, priceStr),
              const SizedBox(height: 12),
              _buildChips(s),
              const SizedBox(height: 12),
              _buildSectionTitle('Description'),
              _buildCard(Text((s.description ?? s.shortDescription ?? 'No description').toString(), style: GoogleFonts.poppins(color: AppPalette.deepBlue))),
              const SizedBox(height: 12),
              _buildSectionTitle('Location'),
              _buildCard(Row(children: [const Icon(Icons.place, color: AppPalette.fusionPurple), const SizedBox(width: 8), Expanded(child: Text(s.address ?? s.locations ?? 'Not available', style: GoogleFonts.poppins(color: AppPalette.deepBlue)))])),
              const SizedBox(height: 12),
              _buildSectionTitle('Rating & Stats'),
              _buildCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _buildStars(avg),
                  const SizedBox(width: 12),
                  if (avg != null) Text(avg.toStringAsFixed(1), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppPalette.deepBlue)),
                  if (_ratingCount != null) ...[
                    const SizedBox(width: 8),
                    Text('($_ratingCount)', style: GoogleFonts.poppins(color: AppPalette.deepBlue.withAlpha(150))),
                  ],
                  const Spacer(),
                  if (s.viewsCont != null) Text('Views: ${s.viewsCont}', style: GoogleFonts.poppins(color: AppPalette.deepBlue.withAlpha(150))),
                ]),
                const SizedBox(height: 12),
                if (_showReviewForm || !_hasMyRating) _buildReviewForm() else _buildMyReviewSummary(),
              ])),
              const SizedBox(height: 12),
              _buildSectionTitle('Reviews'),
              _buildCard(_buildReviews()),
              const SizedBox(height: 12),
              _buildSectionTitle('Business Info'),
              _buildCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (s.companyName.isNotEmpty) Text(s.companyName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppPalette.deepBlue)),
                const SizedBox(height: 8),
                if (s.number != null && s.number!.isNotEmpty)
                  InkWell(onTap: () => _openPhone(s.number!), child: Row(children: [const Icon(Icons.phone, size: 16, color: AppPalette.fusionPurple), const SizedBox(width: 6), Expanded(child: Text(s.number!, style: GoogleFonts.poppins(color: AppPalette.deepBlue)))])),
                if (s.email != null && s.email!.isNotEmpty)
                  InkWell(onTap: () => _openEmail(s.email!), child: Row(children: [const Icon(Icons.email, size: 16, color: AppPalette.fusionPurple), const SizedBox(width: 6), Expanded(child: Text(s.email!, style: GoogleFonts.poppins(color: AppPalette.deepBlue)))])),
                if (s.website != null && s.website!.isNotEmpty)
                  InkWell(onTap: () => _openWebsite(s.website!), child: Row(children: [const Icon(Icons.web_asset, size: 16, color: AppPalette.fusionPurple), const SizedBox(width: 6), Expanded(child: Text(_displayWebsite(s.website!), style: GoogleFonts.poppins(color: AppPalette.deepBlue)))])),
              ])),
              const SizedBox(height: 12),
              _buildSectionTitle('Map'),
              _buildCard(
                derived != null
                    ? SizedBox(
                        height: 220,
                        child: _buildMapOnly(derived, s),
                      )
                    : Container(height: 180, alignment: Alignment.center, child: const Icon(Icons.map, color: Colors.grey)),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _bottomActionsBar(s),
    );
  }

  Widget _buildRatingInput() {
    final selected = _myRating;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final v = index + 1;
        final active = selected != null && v <= selected;
        return InkWell(
          onTap: _submittingRating
              ? null
              : () {
                  setState(() => _myRating = v);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              active ? Icons.star : Icons.star_border,
              size: 24,
              color: active ? Colors.amber : Colors.grey,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Your rating', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const Spacer(),
          _buildRatingInput(),
        ]),
        const SizedBox(height: 12),
        Text('Your name', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _ratingNameController,
          decoration: InputDecoration(
            hintText: 'Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        Text('Description (max 100 words)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _ratingReviewController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Write your review...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Words: $_ratingReviewWords/100',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: _ratingReviewWords > 100 ? Colors.red : Colors.black54,
            fontWeight: _ratingReviewWords > 100 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Spacer(),
          FilledButton(
            onPressed: (_loadingRating || _submittingRating) ? null : _submitRating,
            child: Text('Submit', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ]),
        if ((_ratingStatusText ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _ratingStatusText!.trim(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _ratingStatusIsError ? Colors.red : Colors.black54,
              fontWeight: _ratingStatusIsError ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
        if (_loadingRating || _submittingRating) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    );
  }

  Widget _buildMyReviewSummary() {
    final r = _myReview;
    final rating = _myRating ?? 0;
    final username = (r?['username'] ?? r?['name'] ?? _ratingNameController.text.trim()).toString().trim();
    final text = (r?['review_text'] ?? r?['reviewText'] ?? r?['description'] ?? r?['review'] ?? '').toString().trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Your review', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: () {
                final nextName = username;
                if (nextName.isNotEmpty) _ratingNameController.text = nextName;
                if (text.isNotEmpty) _ratingReviewController.text = text;
                setState(() => _showReviewForm = true);
              },
              child: Text('Edit', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      username.isEmpty ? 'User' : username,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (rating > 0) _buildStars(rating.toDouble()),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                text.isEmpty ? 'No description provided.' : text,
                style: GoogleFonts.poppins(color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviews() {
    final list = _serviceReviews;
    if (list.isEmpty) {
      return Text('No reviews yet', style: GoogleFonts.poppins(color: Colors.black54));
    }
    final children = <Widget>[];
    for (int i = 0; i < list.length; i++) {
      final r = list[i];
      final rating = _toInt(r['rating'] ?? r['stars']) ?? 0;
      final username = (r['username'] ?? r['name'] ?? 'User').toString();
      final text = (r['review_text'] ?? r['reviewText'] ?? r['description'] ?? r['review'] ?? '').toString();
      if (i > 0) children.add(const Divider(height: 20));
      children.add(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                username.trim().isEmpty ? 'User' : username.trim(),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            if (rating > 0) _buildStars(rating.toDouble()),
          ]),
          if (text.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(text.trim(), style: GoogleFonts.poppins(color: Colors.black87)),
          ],
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildImages() {
    if (images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: AppPalette.lightBlueTint, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _imageIndex = i),
            itemBuilder: (context, index) {
              final url = images[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(url, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                ),
              );
            },
          ),
          Positioned(
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == _imageIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppPalette.fusionPurple : AppPalette.deepBlue.withAlpha(60),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Service s, String priceStr) {
    final priceLabel = priceStr + (s.perPrice != null && s.perPrice!.isNotEmpty ? ' / ${s.perPrice}' : '');
    return _buildCard(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.serviceName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: AppPalette.deepBlue)),
        const SizedBox(height: 6),
        Text(s.companyName, style: GoogleFonts.poppins(color: AppPalette.deepBlue.withAlpha(150))),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppPalette.lightBlueTint,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppPalette.deepBlue.withAlpha(24)),
        ),
        child: Text(priceLabel, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppPalette.fusionPurple, fontSize: 12)),
      ),
    ]));
  }

  LatLng? _deriveLatLng(Service s) {
    if (s.lati != null && s.lngi != null) {
      return LatLng(s.lati!, s.lngi!);
    }
    final link = (s.gmap ?? '').toString();
    if (link.isEmpty) return null;
    final r1 = RegExp(r'@(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)');
    final m1 = r1.firstMatch(link);
    if (m1 != null) {
      final lat = double.tryParse(m1.group(1)!);
      final lng = double.tryParse(m1.group(2)!);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    final r2 = RegExp(r'!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)');
    final m2 = r2.firstMatch(link);
    if (m2 != null) {
      final lat = double.tryParse(m2.group(1)!);
      final lng = double.tryParse(m2.group(2)!);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    final r3 = RegExp(r'q=(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)');
    final m3 = r3.firstMatch(link);
    if (m3 != null) {
      final lat = double.tryParse(m3.group(1)!);
      final lng = double.tryParse(m3.group(2)!);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    return null;
  }

  Widget _buildMapOnly(LatLng pos, Service s) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    return GestureDetector(
      onTap: () => _openExternalMap(pos, s),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          liteModeEnabled: isAndroid,
          initialCameraPosition: CameraPosition(target: pos, zoom: 15),
          markers: {
            Marker(
              markerId: MarkerId(s.id),
              position: pos,
              infoWindow: InfoWindow(title: s.serviceName, snippet: s.companyName),
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          compassEnabled: false,
        ),
      ),
    );
  }

  // Removed static map URL

  Future<void> _openExternalMap(LatLng pos, Service s) async {
    ApiService().trackServiceEvent(s.id, 'tap_map');
    final label = Uri.encodeComponent(s.serviceName);
    final geoUrl = Uri.parse('geo:${pos.latitude},${pos.longitude}?q=${pos.latitude},${pos.longitude}($label)');
    final webUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}');
    if (await canLaunchUrl(geoUrl)) {
      await launchUrl(geoUrl);
      return;
    }
    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  }

  Future<void> _openPhone(String raw) async {
    ApiService().trackServiceEvent(widget.service.id, 'tap_phone');
    final number = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: number);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return;
    await Clipboard.setData(ClipboardData(text: number));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dialer unavailable. Number copied.')));
    }
  }

  Future<void> _openEmail(String email) async {
    ApiService().trackServiceEvent(widget.service.id, 'tap_email');
    final uri = Uri(scheme: 'mailto', path: email);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return;
    await Clipboard.setData(ClipboardData(text: email));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email app unavailable. Address copied.')));
    }
  }

  String _normalizeWebsite(String url) {
    var u = url.trim();
    if (u.startsWith('//')) {
      u = 'https:$u';
    }
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    return u;
  }

  String _displayWebsite(String url) {
    final u = _normalizeWebsite(url);
    return u.replaceFirst(RegExp(r'^https?://'), '');
  }

  Future<void> _openWebsite(String url) async {
    ApiService().trackServiceEvent(widget.service.id, 'tap_website');
    final u = _normalizeWebsite(url);
    final uri = Uri.parse(u);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return;
    await Clipboard.setData(ClipboardData(text: u));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Browser unavailable. URL copied.')));
    }
  }

  Widget _buildChips(Service s) {
    final cats = (s.categorys ?? '').toString();
    final subs = (s.subcategory ?? '').toString();
    final catLabel = (_categoryName ?? (cats.isEmpty ? 'Category' : cats));
    final subLabels = _subNames.isNotEmpty
        ? _subNames
        : (subs.isEmpty ? <String>[] : subs.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList());
    final children = <Widget>[
      Chip(
        label: Text(catLabel, style: GoogleFonts.poppins(color: AppPalette.deepBlue, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        shape: StadiumBorder(side: BorderSide(color: AppPalette.deepBlue.withAlpha(26))),
      ),
      ...subLabels.map((e) => Chip(
            label: Text(e, style: GoogleFonts.poppins(color: AppPalette.deepBlue)),
            backgroundColor: Colors.white,
            shape: StadiumBorder(side: BorderSide(color: AppPalette.deepBlue.withAlpha(26))),
          )),
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppPalette.deepBlue));
  }

  Future<void> _resolveCategoryAndSubs() async {
    try {
      await HierarchyRepository().init();
      final s = widget.service;
      final catId = (s.categorys ?? '').toString();
      if (catId.isNotEmpty) {
        final cats = HierarchyRepository().getCategories();
        final match = cats.firstWhere(
          (c) => c.id == catId,
          orElse: () => CategoryNode(catId, 'Category $catId'),
        );
        _categoryName = match.name;
        final subsStr = (s.subcategory ?? '').toString();
        if (subsStr.isNotEmpty) {
          final nodes = await HierarchyRepository().getSubcategories(catId);
          final idList = subsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          _subNames = idList.map((id) {
            final m = nodes.firstWhere(
              (n) => n.id == id,
              orElse: () => SubcategoryNode(id, 'Subcategory $id'),
            );
            return m.name;
          }).toList();
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Widget _buildCard(Widget child) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.deepBlue.withAlpha(26)),
          boxShadow: [
            BoxShadow(color: AppPalette.fusionPurple.withAlpha(14), blurRadius: 12, offset: const Offset(0, 8)),
          ],
        ),
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      ),
    );
  }

  Widget _buildStars(double? rating) {
    final r = rating ?? 0;
    final full = r.floor();
    final half = (r - full) >= 0.5;
    final items = <Icon>[];
    for (int i = 0; i < full; i++) {
      items.add(const Icon(Icons.star, color: Colors.amber, size: 18));
    }
    if (half) items.add(const Icon(Icons.star_half, color: Colors.amber, size: 18));
    while (items.length < 5) {
      items.add(const Icon(Icons.star_border, color: Colors.amber, size: 18));
    }
    return Row(children: items);
  }

  Widget _buildActions(Service s) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: s.number != null && s.number!.isNotEmpty ? () => _openPhone(s.number!) : null,
            icon: const Icon(Icons.phone),
            label: Text('Call', style: GoogleFonts.poppins(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1),
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.fusionPurple,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              minimumSize: const Size(0, 44),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              final pos = _deriveLatLng(s);
              if (pos != null) _openExternalMap(pos, s);
            },
            icon: const Icon(Icons.directions),
            label: Text('Directions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.fusionPurple,
              side: BorderSide(color: AppPalette.fusionPurple.withAlpha(120)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              minimumSize: const Size(0, 44),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: s.website != null && s.website!.isNotEmpty ? () => _openWebsite(s.website!) : null,
            icon: const Icon(Icons.public),
            label: Text('Website', style: GoogleFonts.poppins(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.fusionPurple,
              side: BorderSide(color: AppPalette.fusionPurple.withAlpha(120)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              minimumSize: const Size(0, 44),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomActionsBar(Service s) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppPalette.deepBlue.withAlpha(26))),
          boxShadow: [
            BoxShadow(color: AppPalette.fusionPurple.withAlpha(12), blurRadius: 12, offset: const Offset(0, -4)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: _buildActions(s),
      ),
    );
  }
}
