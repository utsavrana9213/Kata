import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servekeen/service_model.dart';
import 'package:servekeen/login_screen.dart';
import 'package:servekeen/widgets/dot_grid_painter.dart';
import 'package:servekeen/categories_page.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/all_services_page.dart';
import 'package:servekeen/profile_page.dart';
import 'package:servekeen/category_services_page.dart';
import 'package:servekeen/data/hierarchy_repository.dart';
import 'package:servekeen/service_detail_page.dart';
import 'package:servekeen/my_services_page.dart';
import 'package:servekeen/near_me_page.dart';
import 'package:servekeen/vendor_profile_page.dart';
import 'package:servekeen/vendor_statistics_page.dart';
import 'package:video_player/video_player.dart';
import 'package:servekeen/add_service_page.dart';
import 'package:servekeen/theme/palette.dart';
import 'package:servekeen/vendor_filters.dart';
import 'package:flutter/services.dart';
import 'package:servekeen/main.dart' show setAppThemeMode;

class ChatTurn {
  final String role;
  final String content;
  ChatTurn({required this.role, required this.content});
}

class _SupportTicketSheet extends StatefulWidget {
  final String presetSubject;
  final String userId;
  final String userEmail;
  final String userMobile;
  const _SupportTicketSheet({
    required this.presetSubject,
    required this.userId,
    required this.userEmail,
    required this.userMobile,
  });

  @override
  State<_SupportTicketSheet> createState() => _SupportTicketSheetState();
}

class _SupportTicketSheetState extends State<_SupportTicketSheet> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _subjectController.text = widget.presetSubject;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1B2836) : Colors.grey[50]!;
    final textPrimary = isDark ? const Color(0xFFEAF2FC) : AppPalette.deepBlue;
    final border = isDark ? Colors.white.withAlpha(24) : Colors.grey[200]!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Open Ticket',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _sending
                      ? null
                      : () async {
                          final subject = _subjectController.text.trim();
                          final message = _messageController.text.trim();
                          if (subject.isEmpty || message.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter subject and message',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setState(() => _sending = true);
                          final res = await ApiService().sendSupportTicket(
                            subject: subject,
                            message: message,
                            userId: widget.userId,
                            userEmail: widget.userEmail,
                            userMobile: widget.userMobile,
                          );
                          if (!context.mounted) return;
                          setState(() => _sending = false);
                          if (res['status'] == 'success') {
                            Navigator.pop(context, {
                              'subject': subject,
                              'message': message,
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  (res['message'] ?? 'Failed to send ticket')
                                      .toString(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final int initialTab;
  const HomePage({super.key, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const int _tabHome = 0;
  static const int _tabSell = 1;
  static const int _tabChat = 2;
  static const int _tabProfile = 3;

  static const Color _cDeepBlue = AppPalette.darkNavy;
  static const Color _cFusionPurple = AppPalette.primaryBlue;
  static const Color _cElegantPink = AppPalette.primaryGreen;
  static const Color _cSoftBlendBackground = AppPalette.softBlendBackground;
  static const Color _cLightPinkTint = AppPalette.lightPinkTint;
  static const Color _cLightBlueTint = AppPalette.lightBlueTint;
  static const Color _cDarkSurface = Color(0xFF121212);
  static const Color _cDarkElevatedSurface = Color(0xFF1E1E1E);
  static const Color _cDarkMutedSurface = Color(0xFF262626);
  static const Color _cDarkTextPrimary = Color(0xFFEAF2FC);
  static const Color _cDarkTextSecondary = Color(0xFFB4C3D5);
  static const Color _cDarkBrandBlue = Color(0xFF75AFFF);

  int _navIndex = 0;
  final Duration _rotationInterval = const Duration(seconds: 5);
  late final PageController _carouselController;
  int _carouselIndex = 0;
  Timer? _autoScrollTimer;
  final ScrollController _brandScrollController = ScrollController();
  Timer? _brandAutoScrollTimer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  List<Service> _searchResults = [];
  bool _isSearching = false;
  bool _showPremiumOnly = false;
  int _notificationCount = 3;
  VideoPlayerController? _videoController;
  bool _videoMuted = false;
  final GlobalKey<FormState> _sellerFormKey = GlobalKey<FormState>();
  final TextEditingController _sellerNameController = TextEditingController();
  final TextEditingController _sellerEmailController = TextEditingController();
  final TextEditingController _sellerPasswordController =
      TextEditingController();
  final TextEditingController _sellerMobileController = TextEditingController();
  final TextEditingController _sellerBusinessNameController =
      TextEditingController();
  final TextEditingController _sellerBusinessWebsiteController =
      TextEditingController();
  final TextEditingController _sellerAddressController =
      TextEditingController();
  final TextEditingController _sellerCityController = TextEditingController();
  final TextEditingController _sellerStateController = TextEditingController();
  final TextEditingController _sellerPincodeController =
      TextEditingController();
  bool _sellerSubmitting = false;
  final bool _sellerCompleted = false;
  bool _sellerRequestSubmitted = false;

  // Mock data instead of Supabase stream
  final List<Service> _services = [];
  final Map<String, String> _categoryNameById = {};

  final TextEditingController _chatController = TextEditingController();
  final List<ChatTurn> _chatHistory = [];
  List<Service> _chatSearchResults = [];
  bool _chatLoading = false;
  bool _chatShowActions = false;
  bool _chatShowNeedHelpChoices = false;
  static const MethodChannel _voiceChannel = MethodChannel('voice_search');
  bool _voiceInProgress = false;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _homeCategories = [];
  List<String> carouselImages = [];
  List<String> brandLogos = [];

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _appBarSurface => _isDarkMode ? _cDarkSurface : Colors.white;
  Color get _navSurface => _isDarkMode ? const Color(0xFF0A0F15) : Colors.white;
  Color get _cardSurface =>
      _isDarkMode ? _cDarkElevatedSurface : Colors.white.withAlpha(235);
  Color get _fieldSurface => _isDarkMode ? _cDarkSurface : Colors.white;
  Color get _subtleSurface =>
      _isDarkMode ? _cDarkMutedSurface : _cLightBlueTint;
  Color get _textPrimary => _isDarkMode ? _cDarkTextPrimary : _cDeepBlue;
  Color get _textSecondary =>
      _isDarkMode ? _cDarkTextSecondary : _cDeepBlue.withAlpha(150);
  Color get _textMuted =>
      _isDarkMode ? _cDarkTextSecondary.withAlpha(180) : Colors.black54;
  Color get _borderColor =>
      _isDarkMode ? Colors.white.withAlpha(24) : _cDeepBlue.withAlpha(28);
  Color get _brandColor => _isDarkMode ? _cDarkBrandBlue : _cFusionPurple;
  Color get _softShadow =>
      _isDarkMode ? Colors.black.withAlpha(70) : _cFusionPurple.withAlpha(16);
  List<Color> get _pageGradientColors => _isDarkMode
      ? const [Colors.black, Colors.black, Colors.black]
      : const [_cSoftBlendBackground, _cLightBlueTint, _cLightPinkTint];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _carouselController = PageController();
    _startAutoScroll();
    _searchController.addListener(_onSearchChanged);
    _loadServices();
    _initVideo();
    _prefillSellerForm();
    final initial = widget.initialTab;
    if (initial == _tabHome ||
        initial == _tabSell ||
        initial == _tabChat ||
        initial == _tabProfile) {
      _navIndex = initial;
    }
    final u = ApiService().currentUser;
    if (u != null && _roleOf(u) == 'admin') {
      _navIndex = _tabSell;
    }
    if (_chatHistory.isEmpty) {
      _chatHistory.add(
        ChatTurn(
          role: 'ai',
          content:
              "Hello! I'm your Servekeen assistant.\n\nType a service name like:\n• spa\n• catering\n• hospital\n• car rental\n\nI'll find matching services for you!",
        ),
      );
    }
  }

  Future<void> _startVoiceSearch() async {
    if (_voiceInProgress) return;
    setState(() => _voiceInProgress = true);
    try {
      final text = await _voiceChannel.invokeMethod<String>('start');
      if (!mounted) return;
      if (text != null && text.trim().isNotEmpty) {
        _searchController.text = text;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
        _onSearchChanged();
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice search unavailable: ${e.message ?? 'Error'}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _voiceInProgress = false);
    }
  }

  Future<void> _loadServices() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await ApiService().fetchAppData();
      await HierarchyRepository().init();
      final offlineServices = HierarchyRepository().getAllServices();

      if (mounted) {
        setState(() {
          // 1. Services
          if (data['services'] != null) {
            try {
              debugPrint(
                "Services found: ${(data['services'] as List).length}",
              );
              _services.clear();

              // Parse services one by one to catch individual errors
              for (var serviceJson in (data['services'] as List)) {
                try {
                  final service = Service.fromJson(serviceJson);
                  if (service.companyName.isNotEmpty &&
                      service.serviceName.isNotEmpty) {
                    _services.add(service);
                  }
                } catch (e) {
                  debugPrint("Error parsing individual service: $e");
                  debugPrint("Problematic service data: $serviceJson");
                  // Continue with other services
                }
              }

              debugPrint("Successfully loaded ${_services.length} services");
            } catch (e) {
              debugPrint("Error processing services list: $e");
            }
          } else {
            debugPrint("No 'services' key in API response or it is null");
          }
          // The public endpoint occasionally returns a partial/empty payload.
          // Keep the packaged, validated catalogue as a read-only fallback.
          if (_services.isEmpty) _services.addAll(offlineServices);

          // 2. Categories
          if (data['categories'] != null) {
            _categoryNameById.clear();
            final rawCats = (data['categories'] as List);
            for (final c in rawCats) {
              if (c is Map) {
                final id = (c['id'] ?? '').toString().trim();
                final name = (c['category_name'] ?? c['name'] ?? '')
                    .toString()
                    .trim();
                if (id.isNotEmpty && name.isNotEmpty) {
                  _categoryNameById[id] = name;
                }
              }
            }

            _homeCategories = rawCats.take(8).map((e) {
              String imgPath = e['imgfold'] ?? '';
              if (imgPath.isNotEmpty && !imgPath.startsWith('http')) {
                imgPath = "https://servekeen.com/$imgPath";
              }

              return {
                'id': (e['id'] ?? '').toString(),
                'label': (e['category_name'] ?? e['name'] ?? 'Unknown')
                    .toString(),
                'image': imgPath.isNotEmpty
                    ? imgPath
                    : 'assets/images/display1.jpg',
                'is_network': imgPath.isNotEmpty,
              };
            }).toList();
          }

          // 3. Banners (Carousel)
          if (data['banners'] != null) {
            final banners = (data['banners'] as List);
            if (banners.isNotEmpty) {
              carouselImages = banners
                  .map((e) => "https://servekeen.com/${e['imgfold']}")
                  .toList();
            }
          }

          // 4. Brands
          // Use provided local brand images (horizontal logos)
          brandLogos = [
            'assets/images/mgm.jpg',
            'assets/images/mito.jpg',
            'assets/images/naturals.jpg',
            'assets/images/radisson.jpg',
            'assets/images/rainbow.png',
            'assets/images/3m.jpg',
            'assets/images/blue_dart.jpg',
            'assets/images/tata.png',
            'assets/images/yahama.png',
          ];

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("API Error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(_rotationInterval, (timer) {
      final total = 1 + carouselImages.length;
      if (total == 0) return;
      _carouselIndex = (_carouselIndex + 1) % total;
      if (mounted && _carouselController.hasClients) {
        _carouselController.animateToPage(
          _carouselIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {});
      }
    });
    _brandAutoScrollTimer?.cancel();
    _brandAutoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_brandScrollController.hasClients) return;
      final max = _brandScrollController.position.maxScrollExtent;
      if (max <= 0) return;
      final next = _brandScrollController.offset + 120 >= max
          ? 0.0
          : _brandScrollController.offset + 120;
      _brandScrollController.animateTo(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _brandAutoScrollTimer?.cancel();
    _searchDebounce?.cancel();
    _carouselController.dispose();
    _brandScrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _chatController.dispose();
    _videoController?.dispose();
    _sellerNameController.dispose();
    _sellerEmailController.dispose();
    _sellerPasswordController.dispose();
    _sellerMobileController.dispose();
    _sellerBusinessNameController.dispose();
    _sellerBusinessWebsiteController.dispose();
    _sellerAddressController.dispose();
    _sellerCityController.dispose();
    _sellerStateController.dispose();
    _sellerPincodeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.pause();
    } else if (state == AppLifecycleState.resumed && _navIndex == _tabHome) {
      controller.play();
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final q = _searchController.text.trim();
      if (!mounted) return;
      setState(() {
        _searchQuery = q;
        _searchResults = [];
      });
      if (q.isNotEmpty) {
        await _performBackendSearch(q);
      }
    });
  }

  Future<void> _performBackendSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await ApiService().searchServices(query, limit: 20);
      if (!mounted) return;
      var filtered = _rankAndFilterServices(results, query);
      if (filtered.isEmpty && _services.isNotEmpty) {
        filtered = _performLocalSearch(query);
      }
      setState(() {
        _searchResults = filtered;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      final fallback = _performLocalSearch(query);
      setState(() {
        _searchResults = fallback;
        _isSearching = false;
      });
      debugPrint('Search error, used local fallback: $e');
    }
  }

  List<Service> _performLocalSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final terms = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    return _services.where((s) {
      final catName = (_categoryNameById[s.categorys] ?? '').toLowerCase();
      final haystack = [
        s.companyName.toLowerCase(),
        s.serviceName.toLowerCase(),
        (s.subcategory ?? '').toLowerCase(),
        catName,
        (s.locations ?? '').toLowerCase(),
        (s.address ?? '').toLowerCase(),
        (s.shortDescription ?? '').toLowerCase(),
        (s.description ?? '').toLowerCase(),
      ].join(' ');
      return terms.every((t) => haystack.contains(t));
    }).toList();
  }

  List<Service> _rankAndFilterServices(List<Service> raw, String query) {
    final filtered = rankRelevantServices(
      raw,
      query,
      tier: _showPremiumOnly ? VendorTier.premium : VendorTier.standard,
      categoryNames: _categoryNameById,
    );
    if (filtered.isNotEmpty) return filtered;
    // If tier guard filtered out all matches, return raw matching services
    final q = query.trim().toLowerCase();
    return raw.where((s) {
      final catName = (_categoryNameById[s.categorys] ?? '').toLowerCase();
      final haystack = [
        s.companyName.toLowerCase(),
        s.serviceName.toLowerCase(),
        (s.subcategory ?? '').toLowerCase(),
        catName,
        (s.locations ?? '').toLowerCase(),
        (s.address ?? '').toLowerCase(),
      ].join(' ');
      return haystack.contains(q);
    }).toList();
  }

  List<Service> _filteredServices() {
    final q = _searchQuery;
    if (q.isNotEmpty) return _searchResults;
    return _services
        .where((s) => _showPremiumOnly ? s.isPremium : true)
        .toList();
  }

  void _prefillSellerForm() {
    final u = ApiService().currentUser;
    if (u == null) return;
    _sellerNameController.text = (u['name'] ?? '').toString();
    _sellerEmailController.text = (u['email'] ?? '').toString();
    _sellerMobileController.text =
        (u['mobile'] ?? u['number'] ?? u['phone'] ?? '').toString();
    _sellerBusinessNameController.text = (u['businessname'] ?? '').toString();
    _sellerBusinessWebsiteController.text =
        (u['bwebsite'] ?? u['businesswebsite'] ?? '').toString();
    _sellerAddressController.text = (u['address'] ?? '').toString();
    _sellerCityController.text = (u['city'] ?? '').toString();
    _sellerStateController.text = (u['state'] ?? '').toString();
    _sellerPincodeController.text = (u['pincode'] ?? '').toString();
  }

  Future<void> _initVideo() async {
    try {
      final c = VideoPlayerController.asset('assets/images/video.mp4');
      await c.initialize();
      c.setLooping(true);
      c.setVolume(0.0);
      await c.play();
      if (mounted) {
        setState(() {
          _videoController = c;
          _videoMuted = true;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildLeftDrawer(),
      appBar: _buildTopNavAppBar(context),
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            _buildHomeContent(context),
            _buildSellOnServekeen(context),
            _buildChatContent(),
            _buildProfileContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      backgroundColor: _navSurface,
      type: BottomNavigationBarType.fixed,
      elevation: _isDarkMode ? 0 : 8,
      onTap: (index) => setState(() => _navIndex = index),
      selectedItemColor: _brandColor,
      unselectedItemColor: _isDarkMode
          ? _cDarkTextSecondary.withAlpha(150)
          : _cDeepBlue.withAlpha(140),
      selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.storefront_outlined),
          label: 'Sell',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  String _roleOf(Map<String, dynamic> u) {
    final raw = (u['role'] ?? u['user_role'] ?? u['type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (raw.isNotEmpty) return raw;
    return 'user';
  }

  Widget _buildHomeContent(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;
    final queryActive = _searchQuery.isNotEmpty;
    final results = queryActive ? _filteredServices() : const <Service>[];

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _pageGradientColors,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: _isDarkMode ? 0.045 : 0.06,
              child: CustomPaint(painter: DotGridPainter()),
            ),
          ),
        ),
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (queryActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _isSearching
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _cFusionPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Searching...',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Results (${results.length})',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _textPrimary,
                                ),
                              ),
                      ),
                      TextButton(
                        onPressed: results.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AllServicesPage(services: results),
                                  ),
                                );
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: _cFusionPurple,
                        ),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                ),
              if (queryActive && _isSearching)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (queryActive && !_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: results.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 36),
                          child: Center(
                            child: Text(
                              'No services found',
                              style: GoogleFonts.poppins(color: _textMuted),
                            ),
                          ),
                        )
                      : _buildServicesPreviewGrid(
                          context,
                          results.take(12).toList(),
                        ),
                ),
              if (queryActive) const SizedBox(height: 24),
              if (!queryActive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: _buildHeaderHero(context),
                ),
              if (!queryActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'Categories',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _textPrimary,
                    ),
                  ),
                ),
              if (!queryActive) const SizedBox(height: 8),
              if (!queryActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _buildCategoriesGrid(context),
                ),
              if (!queryActive) const SizedBox(height: 12),
              if (!queryActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _buildCarouselCard(context, isSmall),
                ),
              if (!queryActive) const SizedBox(height: 16),
              if (!queryActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'Top Brands',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _textPrimary,
                    ),
                  ),
                ),
              if (!queryActive) const SizedBox(height: 8),
              if (!queryActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _buildBrandStrip(isSmall),
                ),
              if (!queryActive) const SizedBox(height: 16),
              if (!queryActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recommended Services',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllServicesPage(
                                services: _filteredServices(),
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: _cFusionPurple,
                        ),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                ),
              if (!queryActive) const SizedBox(height: 8),
              if (!queryActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _buildServicesPreviewGrid(
                    context,
                    _filteredServices().take(6).toList(),
                  ),
                ),
              if (!queryActive) const SizedBox(height: 16),
              if (!queryActive &&
                  _filteredServices().any((service) => service.isPremium))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _buildPremiumSection(context),
                ),
              if (!queryActive &&
                  _filteredServices().any((service) => service.isPremium))
                const SizedBox(height: 16),
              if (!queryActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _buildTopRatedSection(context),
                ),
              if (!queryActive) const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesPreviewGrid(BuildContext context, List<Service> items) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 480
        ? 2
        : width < 900
        ? 3
        : 4;

    if (items.isEmpty) {
      return const Center(child: Text('No services found.'));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _ServiceCard(service: items[index]),
    );
  }

  Widget _buildHorizontalServicesSection(
    BuildContext context,
    String title,
    List<Service> preview,
    List<Service> allList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllServicesPage(services: allList),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: _brandColor),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 210,
          child: preview.isEmpty
              ? Center(
                  child: Text(
                    'No services found',
                    style: GoogleFonts.poppins(color: _textMuted),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: preview.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final s = preview[index];
                    return SizedBox(
                      width: 160,
                      child: _ServiceCard(service: s),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPremiumSection(BuildContext context) {
    final all = _filteredServices().where((s) => s.isPremium).toList();
    all.sort((a, b) => ((b.price ?? 0).compareTo(a.price ?? 0)));
    final preview = all.take(6).toList();
    return _buildHorizontalServicesSection(
      context,
      'Premium Services',
      preview,
      all,
    );
  }

  Widget _buildTopRatedSection(BuildContext context) {
    final all = List<Service>.from(_filteredServices());
    all.sort((a, b) => ((b.avrRat ?? 0).compareTo(a.avrRat ?? 0)));
    final preview = all.take(6).toList();
    return _buildHorizontalServicesSection(
      context,
      'Top Rated Services',
      preview,
      all,
    );
  }

  PreferredSizeWidget _buildTopNavAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _appBarSurface,
      centerTitle: true,
      automaticallyImplyLeading: false,
      systemOverlayStyle: _isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      foregroundColor: _textPrimary,
      bottom: _navIndex != _tabHome
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _buildSearchBar(context),
              ),
            ),
      title: SizedBox(
        height: 32,
        child: Image.asset(
          'assets/images/top_img.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Text(
            'SERVEKEEN',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: _isDarkMode ? Colors.white : _cFusionPurple,
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        IconButton(
          tooltip: 'Toggle dark mode',
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          onPressed: () => setAppThemeMode(
            Theme.of(context).brightness == Brightness.dark
                ? ThemeMode.light
                : ThemeMode.dark,
          ),
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => _showNotifications(context),
            ),
            if (_notificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: _cElegantPink,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_notificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderHero(BuildContext context) {
    final premiumToggle = Material(
      color: _fieldSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: _borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 6, top: 6, bottom: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showPremiumOnly
                  ? Icons.workspace_premium
                  : Icons.verified_outlined,
              size: 16,
              color: _showPremiumOnly ? _cElegantPink : _cFusionPurple,
            ),
            const SizedBox(width: 6),
            Text(
              _showPremiumOnly ? 'Premium' : 'Standard',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Transform.scale(
              scale: 0.85,
              child: Switch.adaptive(
                value: _showPremiumOnly,
                onChanged: (value) => setState(() => _showPremiumOnly = value),
                activeColor: _cFusionPurple,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );

    final nearMeButton = FilledButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NearMePage()),
        );
      },
      style: FilledButton.styleFrom(
        backgroundColor: _cFusionPurple,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: const Icon(Icons.near_me, size: 18),
      label: Text(
        'Near me',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _softShadow,
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Flexible(fit: FlexFit.loose, child: premiumToggle),
          const SizedBox(width: 10),
          nearMeButton,
        ],
      ),
    );
  }

  Future<void> _showNotifications(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: _cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final items = const [
          (
            'New premium vendors available',
            'Explore highlighted services near you.',
          ),
          (
            'Complete your profile',
            'Add contact details for faster vendor responses.',
          ),
          ('Need help?', 'Open AI Chat or send an enquiry from the Sell tab.'),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('You are all caught up.')),
                  ),
                ...items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _subtleSurface,
                      child: Icon(Icons.notifications_none, color: _brandColor),
                    ),
                    title: Text(
                      item.$1,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      item.$2,
                      style: GoogleFonts.poppins(color: _textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (mounted) setState(() => _notificationCount = 0);
  }

  Drawer _buildLeftDrawer() {
    final u = ApiService().currentUser;
    final name = (u?['name'] ?? 'Guest').toString();
    final email = (u?['email'] ?? '').toString();
    final role = u == null ? 'user' : _roleOf(u);
    return Drawer(
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _pageGradientColors,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: _isDarkMode ? 0.045 : 0.06,
                child: CustomPaint(painter: DotGridPainter()),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: _softShadow,
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _fieldSurface,
                        child: Text(
                          name.isEmpty ? 'U' : name[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _brandColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _subtleSurface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Text(
                          role,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _drawerTile(Icons.home, 'Home', () {
                        Navigator.pop(context);
                        setState(() => _navIndex = _tabHome);
                      }),
                      _drawerTile(Icons.explore, 'Explore', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoriesPage(),
                          ),
                        );
                      }),
                      _drawerTile(Icons.info_outline, 'Why Servekeen', () {
                        Navigator.pop(context);
                        _showWhyServekeen(context);
                      }),
                      _drawerTile(
                        Icons.contact_support_outlined,
                        'Enquire Us',
                        () {
                          Navigator.pop(context);
                          _openSupportTicketSheet(context, 'Enquire Us');
                        },
                      ),
                      _drawerTile(
                        Icons.storefront_outlined,
                        'Sell on Servekeen',
                        () {
                          Navigator.pop(context);
                          setState(() => _navIndex = _tabSell);
                        },
                      ),
                      _drawerTile(Icons.logout, 'Sign Out', () async {
                        await ApiService().logout();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      }, isDestructive: true),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showWhyServekeen(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: _cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final points = const [
          (
            'Verified local discovery',
            'Find service vendors by category, location, and rating.',
          ),
          (
            'Standard and premium options',
            'Switch between value-focused and premium listings.',
          ),
          (
            'Quick contact paths',
            'Call, email, open websites, social profiles, or directions from one page.',
          ),
          (
            'Vendor tools',
            'Sellers can publish, manage, and track service listings.',
          ),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why Servekeen',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...points.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: _cElegantPink,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.$1,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.$2,
                                style: GoogleFonts.poppins(
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _drawerTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : _brandColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: _softShadow,
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'Search services',
          hintStyle: GoogleFonts.poppins(
            color: _isDarkMode
                ? _cDarkTextSecondary.withAlpha(170)
                : _cDeepBlue.withAlpha(130),
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.search, color: _textSecondary),
          suffixIconConstraints: const BoxConstraints(
            minHeight: 40,
            minWidth: 40,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.trim().isNotEmpty)
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                  icon: Icon(Icons.close, color: _textSecondary),
                ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scan – coming soon')),
                  );
                },
                icon: Icon(
                  Icons.qr_code_scanner_outlined,
                  color: _textSecondary,
                ),
              ),
              IconButton(
                onPressed: _startVoiceSearch,
                icon: Icon(
                  _voiceInProgress ? Icons.mic : Icons.mic_none,
                  color: _brandColor,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselCard(BuildContext context, bool isSmall) {
    final total = 1 + carouselImages.length;
    if (total == 0) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "No offers right now",
            style: GoogleFonts.poppins(color: _textMuted),
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: isSmall ? 220 : 260,
          child: PageView.builder(
            controller: _carouselController,
            onPageChanged: (index) => setState(() => _carouselIndex = index),
            itemCount: total,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _cardSurface,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_videoController != null &&
                            _videoController!.value.isInitialized)
                          AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        else
                          const Icon(
                            Icons.videocam,
                            size: 48,
                            color: Colors.grey,
                          ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(102),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    (_videoController?.value.isPlaying ?? false)
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    final c = _videoController;
                                    if (c == null) return;
                                    if (c.value.isPlaying) {
                                      c.pause();
                                    } else {
                                      c.play();
                                    }
                                    setState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    _videoMuted
                                        ? Icons.volume_off
                                        : Icons.volume_up,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    final c = _videoController;
                                    if (c == null) return;
                                    setState(() => _videoMuted = !_videoMuted);
                                    c.setVolume(_videoMuted ? 0.0 : 1.0);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => _FullscreenVideoPage(
                                          assetPath: 'assets/images/video.mp4',
                                          startMuted: _videoMuted,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final imgUrl = carouselImages[index - 1];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _cardSurface,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imgUrl.startsWith('http')
                      ? Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (ctx, err, stack) =>
                              const Icon(Icons.broken_image),
                        )
                      : Image.asset(
                          imgUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _carouselIndex == index
                    ? _brandColor
                    : _isDarkMode
                    ? Colors.white.withAlpha(45)
                    : _cDeepBlue.withAlpha(45),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBrandStrip(bool isSmall) {
    if (brandLogos.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 68,
      child: ListView.builder(
        controller: _brandScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: brandLogos.length,
        itemBuilder: (context, index) {
          final logoUrl = brandLogos[index];
          Widget imgWidget = logoUrl.startsWith('http')
              ? Image.network(
                  logoUrl,
                  width: 92,
                  height: 52,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.business),
                )
              : Image.asset(
                  logoUrl,
                  width: 92,
                  height: 52,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.business, color: Colors.grey),
                );

          return Container(
            width: 104,
            margin: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Center(child: imgWidget),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          children: [
            Text(
              "Error: $_errorMessage",
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
            TextButton(onPressed: _loadServices, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_homeCategories.isEmpty) {
      return Center(
        child: Text(
          "No categories found",
          style: GoogleFonts.poppins(color: _textMuted),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _homeCategories.length,
      itemBuilder: (context, index) {
        final isLast = index == _homeCategories.length - 1;
        if (isLast) {
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesPage()),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _brandColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _brandColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Show More',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        } else {
          final cat = _homeCategories[index];
          final isNetwork = cat['is_network'] == true;
          final imagePath = (cat['image'] ?? '').toString();
          final id = (cat['id'] ?? '').toString();
          final label = (cat['label'] ?? '').toString();
          final matchingGif = _getCategoryGifForLabel(label);
          final isResorts = label.toLowerCase().contains('resort');
          final iconSize = isResorts ? 56.0 : 48.0;

          Widget iconWidget;
          if (matchingGif != null) {
            iconWidget = Image.asset(
              matchingGif,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            );
          } else if (isNetwork &&
              imagePath.isNotEmpty &&
              imagePath.startsWith('http')) {
            iconWidget = Image.network(
              imagePath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) {
                if (matchingGif != null) {
                  return Image.asset(
                    matchingGif,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  );
                }
                return Icon(
                  Icons.category_outlined,
                  color: _brandColor,
                  size: 28,
                );
              },
            );
          } else if (imagePath.isNotEmpty) {
            iconWidget = Image.asset(
              imagePath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) =>
                  Icon(Icons.category_outlined, color: _brandColor, size: 28),
            );
          } else {
            iconWidget = Icon(
              Icons.category_outlined,
              color: _brandColor,
              size: 28,
            );
          }

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CategoryServicesPage(categoryId: id, categoryName: label),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Center(child: iconWidget),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }
      },
    );
  }

  static String? _getCategoryGifForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('cater') || l.contains('food') || l.contains('restaurant')) {
      return 'assets/images/catering.gif';
    }
    if (l.contains('banquet') ||
        l.contains('marriage') ||
        l.contains('wedding') ||
        l.contains('event')) {
      return 'assets/images/marriage.gif';
    }
    if (l.contains('hospital') ||
        l.contains('clinic') ||
        l.contains('doctor')) {
      return 'assets/images/Hospital.gif';
    }
    if (l.contains('resort') ||
        l.contains('villa') ||
        l.contains('house') ||
        l.contains('estate') ||
        l.contains('property')) {
      return 'assets/images/big_house.gif';
    }
    if (l.contains('packer') ||
        l.contains('mover') ||
        l.contains('shift') ||
        l.contains('truck')) {
      return 'assets/images/truck.gif';
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
      return 'assets/images/route.gif';
    }
    return null;
  }

  Widget _wrapWithHomeBackground(Widget child) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _pageGradientColors,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: _isDarkMode ? 0.045 : 0.06,
              child: CustomPaint(painter: DotGridPainter()),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildSellOnServekeen(BuildContext context) {
    final u = ApiService().currentUser;
    if (_sellerRequestSubmitted) {
      return _wrapWithHomeBackground(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sell on Servekeen',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your vendor signup request is pending approval.',
                style: GoogleFonts.poppins(fontSize: 13, color: _textPrimary),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                color: _cardSurface,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: Text(
                        'Login as Vendor',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'After approval, login to get vendor access.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: _textSecondary,
                      ),
                      onTap: () async {
                        final ok = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const LoginScreen(vendorLogin: true),
                          ),
                        );
                        if (!mounted) return;
                        if (ok == true) setState(() {});
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: Text(
                        'Edit Request',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      onTap: () =>
                          setState(() => _sellerRequestSubmitted = false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (u == null) {
      return _wrapWithHomeBackground(
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _sellerFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sell on Servekeen',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fill details to switch your role to Seller.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(vendorLogin: true),
                        ),
                      );
                    },
                    child: const Text('Login as Vendor'),
                  ),
                ),
                const SizedBox(height: 16),
                _sellerField(
                  controller: _sellerNameController,
                  label: 'Name',
                  icon: Icons.person,
                  requiredField: true,
                ),
                const SizedBox(height: 12),
                _sellerField(
                  controller: _sellerEmailController,
                  label: 'Email',
                  icon: Icons.email,
                  requiredField: true,
                  enabled: true,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _sellerField(
                  controller: _sellerMobileController,
                  label: 'Contact Number',
                  icon: Icons.phone,
                  requiredField: true,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _sellerSubmitting ? null : _submitSellerRequest,
                    child: _sellerSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Switch to Seller'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final role = _roleOf(u);
    if (role == 'admin') {
      return _wrapWithHomeBackground(_buildAdminHome(context, u));
    }
    if (role == 'seller' ||
        ApiService().isSellerOnboarded ||
        _sellerCompleted) {
      return _wrapWithHomeBackground(_buildSellerHome(context, u));
    }

    return _wrapWithHomeBackground(
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _sellerFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sell on Servekeen',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Fill details to switch your role to Seller.',
                style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await ApiService().logout();
                    if (!mounted) return;
                    final ok = await navigator.push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(vendorLogin: true),
                      ),
                    );
                    if (!mounted) return;
                    if (ok == true) setState(() {});
                  },
                  child: const Text('Login as Vendor'),
                ),
              ),
              const SizedBox(height: 16),
              _sellerField(
                controller: _sellerNameController,
                label: 'Name',
                icon: Icons.person,
                requiredField: true,
              ),
              const SizedBox(height: 12),
              _sellerField(
                controller: _sellerEmailController,
                label: 'Email',
                icon: Icons.email,
                requiredField: true,
                enabled: _sellerEmailController.text.trim().isEmpty,
              ),
              const SizedBox(height: 12),
              _sellerField(
                controller: _sellerMobileController,
                label: 'Contact Number',
                icon: Icons.phone,
                requiredField: true,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _sellerSubmitting ? null : _submitSellerRequest,
                  child: _sellerSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Switch to Seller'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminHome(BuildContext context, Map<String, dynamic> u) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Dashboard',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome, ${(u['name'] ?? '').toString().isEmpty ? 'Admin' : u['name']}',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Text(
              'You are logged in as Admin.',
              style: GoogleFonts.poppins(fontSize: 13, color: _textPrimary),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_search_outlined),
                  title: Text(
                    'Vendor Signup Requests',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const VendorSignupRequestsPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: Text(
                    'Go to Home',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _navIndex = _tabHome),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(
                    'Sign Out',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    await ApiService().logout();
                    if (!mounted) return;
                    setState(() => _navIndex = _tabHome);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerHome(BuildContext context, Map<String, dynamic> u) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seller Dashboard',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome, ${(u['name'] ?? '').toString().isEmpty ? 'Seller' : u['name']}',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Text(
              'Your seller profile is active. You can now start selling on Servekeen.',
              style: GoogleFonts.poppins(fontSize: 13, color: _textPrimary),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AddServicePage()));
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Service'),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.design_services),
                  title: Text(
                    'My Service',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyServicesPage()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: Text(
                    'Check Statics',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VendorStatisticsPage(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.store),
                  title: Text(
                    'Vendor Profile',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VendorProfilePage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sellerField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool requiredField,
    bool enabled = true,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: _textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: _textSecondary),
        prefixIcon: Icon(icon, color: _brandColor),
        filled: true,
        fillColor: _fieldSurface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _brandColor, width: 1.2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _borderColor),
        ),
      ),
      validator: (v) {
        if (!enabled) return null;
        if (!requiredField) return null;
        if (v == null || v.trim().isEmpty) return 'Required';
        return null;
      },
    );
  }

  Future<void> _submitSellerRequest() async {
    if (!(_sellerFormKey.currentState?.validate() ?? false)) return;
    setState(() => _sellerSubmitting = true);
    try {
      final vendor = <String, dynamic>{
        'businessname': _sellerNameController.text.trim(),
        'email': _sellerEmailController.text.trim(),
        'password': _sellerPasswordController.text,
        'mobile': _sellerMobileController.text.trim(),
        'bwebsite': '',
        'name': _sellerNameController.text.trim(),
        'address': '',
        'city': '',
        'state': '',
        'pincode': '',
        'is_active': 0,
      };
      if ((vendor['bwebsite'] as String).trim().isEmpty) {
        vendor.remove('bwebsite');
      }

      final vendorResult = await ApiService().upsertVendor(vendor);
      if (!mounted) return;
      if (vendorResult['status'] != 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (vendorResult['message'] ?? 'Failed to save vendor').toString(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() => _sellerRequestSubmitted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request submitted. Waiting for admin approval.'),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _sellerSubmitting = false);
    }
  }

  Widget _buildChatContent() {
    return _wrapWithHomeBackground(
      Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: 12,
                left: 8,
                right: 8,
                bottom: 8,
              ),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final turn = _chatHistory[index];
                final isUser = turn.role == 'user';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? _brandColor : _cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: _softShadow,
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      turn.content,
                      style: GoogleFonts.poppins(
                        color: isUser ? Colors.white : _textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_chatSearchResults.isNotEmpty)
            Container(
              height: 180,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Found ${_chatSearchResults.length} services',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AllServicesPage(
                                  services: _chatSearchResults,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: _brandColor,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                          ),
                          child: const Text(
                            'See all',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _chatSearchResults.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final s = _chatSearchResults[index];
                        return SizedBox(
                          width: 150,
                          child: _ServiceCard(service: s),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          if (_chatLoading) const LinearProgressIndicator(),
          if (_chatShowActions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _chatLoading
                        ? null
                        : () {
                            _sendChatMessageFromUi(
                              'I want to provide feedback.',
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brandColor,
                      side: BorderSide(color: _brandColor.withAlpha(150)),
                    ),
                    child: const Text('Provide feedback'),
                  ),
                  OutlinedButton(
                    onPressed: _chatLoading
                        ? null
                        : () {
                            setState(
                              () => _chatShowNeedHelpChoices =
                                  !_chatShowNeedHelpChoices,
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brandColor,
                      side: BorderSide(color: _brandColor.withAlpha(150)),
                    ),
                    child: const Text('Need help'),
                  ),
                  OutlinedButton(
                    onPressed: _chatLoading
                        ? null
                        : () {
                            _sendChatMessageFromUi('I want to report a bug.');
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brandColor,
                      side: BorderSide(color: _brandColor.withAlpha(150)),
                    ),
                    child: const Text('Indicate bug'),
                  ),
                ],
              ),
            ),
          if (_chatShowActions && _chatShowNeedHelpChoices)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: _chatLoading
                        ? null
                        : () {
                            _openSupportTicketSheet(
                              context,
                              'Need help as vendor',
                            );
                          },
                    style: FilledButton.styleFrom(backgroundColor: _brandColor),
                    child: const Text('Need help as vendor'),
                  ),
                  FilledButton(
                    onPressed: _chatLoading
                        ? null
                        : () {
                            _openSupportTicketSheet(
                              context,
                              'Need help as user',
                            );
                          },
                    style: FilledButton.styleFrom(backgroundColor: _brandColor),
                    child: const Text('Need help as user'),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Container(
              decoration: BoxDecoration(
                color: _cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: _brandColor, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: GoogleFonts.poppins(color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ask something...',
                        hintStyle: GoogleFonts.poppins(
                          color: _textSecondary,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _brandColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(36, 36),
                    ),
                    onPressed: () {
                      final text = _chatController.text.trim();
                      _sendChatMessageFromUi(text);
                    },
                    child: const Icon(Icons.send, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendChatMessageFromUi(String text) {
    final msg = text.trim();
    if (msg.isEmpty) return;
    setState(() {
      _chatHistory.add(ChatTurn(role: 'user', content: msg));
      _chatController.clear();
      _chatLoading = true;
      _chatShowActions = true;
      if (msg != 'Need help as vendor.' && msg != 'Need help as user.') {
        _chatShowNeedHelpChoices = false;
      }
    });
    _searchAndRespond(msg);
  }

  Future<void> _searchAndRespond(String query) async {
    try {
      final results = await ApiService().searchServices(query, limit: 5);
      if (!mounted) return;
      final relevant = _rankAndFilterServices(results, query);
      if (relevant.isEmpty) {
        setState(() {
          _chatHistory.add(
            ChatTurn(
              role: 'ai',
              content:
                  'No services found for "$query". Try searching for something else like "spa", "catering", or "hospital".',
            ),
          );
          _chatSearchResults = [];
          _chatLoading = false;
        });
        return;
      }
      setState(() {
        _chatHistory.add(
          ChatTurn(
            role: 'ai',
            content:
                'I found ${relevant.length} relevant services for "$query":',
          ),
        );
        _chatSearchResults = relevant;
        _chatLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chatHistory.add(
          ChatTurn(
            role: 'ai',
            content:
                'Sorry, I could not search right now. Please try again later.',
          ),
        );
        _chatSearchResults = [];
        _chatLoading = false;
      });
    }
  }

  Future<void> _openSupportTicketSheet(
    BuildContext context,
    String presetSubject,
  ) async {
    final u = ApiService().currentUser;
    final userEmail = (u?['email'] ?? '').toString();
    final userMobile = (u?['mobile'] ?? u?['phone'] ?? '').toString();
    final userId = (u?['id'] ?? '').toString();

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _SupportTicketSheet(
          presetSubject: presetSubject,
          userId: userId,
          userEmail: userEmail,
          userMobile: userMobile,
        );
      },
    );

    if (!mounted) return;
    if (result == null) return;
    final subject = (result['subject'] ?? '').toString();
    final message = (result['message'] ?? '').toString();
    if (subject.trim().isEmpty || message.trim().isEmpty) return;
    setState(() {
      _chatHistory.add(ChatTurn(role: 'user', content: subject));
      _chatHistory.add(ChatTurn(role: 'user', content: message));
      _chatHistory.add(
        ChatTurn(role: 'ai', content: 'Ticket sent successfully.'),
      );
      _chatShowActions = true;
      _chatShowNeedHelpChoices = false;
    });
  }

  Widget _buildProfileContent(BuildContext context) {
    return const ProfilePage();
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final imgPath = service.primaryImageUrl ?? '';
    final localAsset = service.localAssetImage;
    final tier = service.priceTier;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? _HomePageState._cDarkElevatedSurface
        : Colors.white.withAlpha(235);
    final placeholderSurface = isDark
        ? _HomePageState._cDarkMutedSurface
        : _HomePageState._cLightBlueTint;
    final textPrimary = isDark
        ? _HomePageState._cDarkTextPrimary
        : _HomePageState._cDeepBlue;
    final textSecondary = isDark
        ? _HomePageState._cDarkTextSecondary
        : _HomePageState._cDeepBlue.withAlpha(150);
    final brandColor = isDark
        ? _HomePageState._cDarkBrandBlue
        : _HomePageState._cFusionPurple;
    final borderColor = isDark
        ? Colors.white.withAlpha(24)
        : _HomePageState._cFusionPurple.withAlpha(26);
    final shadowColor = isDark
        ? Colors.black.withAlpha(70)
        : _HomePageState._cFusionPurple.withAlpha(16);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailPage(service: service),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: imgPath.isNotEmpty
                    ? Image.network(
                        imgPath,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: placeholderSurface,
                          child: localAsset != null
                              ? Image.asset(localAsset, fit: BoxFit.contain)
                              : const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                        ),
                      )
                    : Container(
                        color: placeholderSurface,
                        child: localAsset != null
                            ? Image.asset(localAsset, fit: BoxFit.contain)
                            : const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.serviceName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    service.companyName,
                    style: GoogleFonts.poppins(
                      color: textSecondary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        service.price != null
                            ? '₹${service.price!.toStringAsFixed(0)}'
                            : 'Price on Request',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: brandColor,
                        ),
                      ),
                      if (service.perPrice != null &&
                          service.perPrice!.isNotEmpty)
                        Text(
                          ' / ${service.perPrice}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: textSecondary,
                          ),
                        ),
                      if (tier != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: service.isPremium
                                ? _HomePageState._cElegantPink
                                : placeholderSurface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            tier,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: service.isPremium
                                  ? Colors.white
                                  : textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (service.locations != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 10,
                            color: brandColor.withAlpha(190),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              service.locations!,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VendorSignupRequestsPage extends StatefulWidget {
  const VendorSignupRequestsPage({super.key});

  @override
  State<VendorSignupRequestsPage> createState() =>
      _VendorSignupRequestsPageState();
}

class _VendorSignupRequestsPageState extends State<VendorSignupRequestsPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _vendors = const [];
  final Set<String> _actingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _idOf(Map<String, dynamic> v) =>
      (v['id'] ?? v['vendor_id'] ?? '').toString();
  String _nameOf(Map<String, dynamic> v) => (v['name'] ?? '').toString();
  String _businessOf(Map<String, dynamic> v) =>
      (v['businessname'] ?? v['business_name'] ?? '').toString();
  String _emailOf(Map<String, dynamic> v) => (v['email'] ?? '').toString();
  String _createdAtOf(Map<String, dynamic> v) =>
      (v['created_at'] ?? v['createdAt'] ?? v['registration_date'] ?? '')
          .toString();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService().fetchPendingVendorSignupRequests();
    if (!mounted) return;
    if (res['status'] == 'success' && res['vendors'] is List) {
      final raw = (res['vendors'] as List).cast<dynamic>();
      final parsed = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is Map) parsed.add(item.cast<String, dynamic>());
      }
      setState(() {
        _vendors = parsed;
        _loading = false;
      });
      return;
    }
    setState(() {
      _error = (res['message'] ?? 'Failed to load requests').toString();
      _loading = false;
    });
  }

  Future<void> _act(Map<String, dynamic> v, bool approve) async {
    final id = _idOf(v);
    if (id.isEmpty) return;
    if (_actingIds.contains(id)) return;
    setState(() => _actingIds.add(id));
    try {
      final res = approve
          ? await ApiService().approveVendorSignupRequest(vendorId: id)
          : await ApiService().rejectVendorSignupRequest(vendorId: id);
      if (!mounted) return;
      if (res['status'] == 'success') {
        setState(
          () => _vendors = _vendors.where((e) => _idOf(e) != id).toList(),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((res['message'] ?? 'Failed').toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _actingIds.remove(id));
    }
  }

  Widget _vendorCard(Map<String, dynamic> v) {
    final id = _idOf(v);
    final name = _nameOf(v);
    final business = _businessOf(v);
    final email = _emailOf(v);
    final createdAt = _createdAtOf(v);
    final acting = id.isNotEmpty && _actingIds.contains(id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFEAF2FC) : AppPalette.deepBlue;
    final textSecondary = isDark
        ? const Color(0xFFB4C3D5)
        : AppPalette.deepBlue.withAlpha(150);
    final borderColor = isDark
        ? Colors.white.withAlpha(24)
        : AppPalette.deepBlue.withAlpha(26);

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1B2836) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              business.isEmpty ? 'Vendor Request' : business,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            if (name.isNotEmpty)
              Text(
                'Name: $name',
                style: GoogleFonts.poppins(fontSize: 12, color: textSecondary),
              ),
            if (email.isNotEmpty)
              Text(
                'Email: $email',
                style: GoogleFonts.poppins(fontSize: 12, color: textSecondary),
              ),
            if (createdAt.isNotEmpty)
              Text(
                'Registration: $createdAt',
                style: GoogleFonts.poppins(fontSize: 12, color: textSecondary),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: acting ? null : () => _act(v, true),
                    child: acting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: acting ? null : () => _act(v, false),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFEAF2FC) : AppPalette.deepBlue;
    final textSecondary = isDark
        ? const Color(0xFFB4C3D5)
        : AppPalette.deepBlue.withAlpha(150);
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D1218)
          : AppPalette.softBlendBackground,
      appBar: AppBar(
        title: Text(
          'Vendor Signup Requests',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF151F2A) : Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: _vendors.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Text(
                              'No pending requests',
                              style: GoogleFonts.poppins(color: textSecondary),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) =>
                            _vendorCard(_vendors[index]),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: _vendors.length,
                      ),
              ),
      ),
    );
  }
}

class _FullscreenVideoPage extends StatefulWidget {
  final String assetPath;
  final bool startMuted;
  const _FullscreenVideoPage({
    required this.assetPath,
    this.startMuted = false,
  });

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  VideoPlayerController? _controller;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _muted = widget.startMuted;
    _init();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _init() async {
    final c = VideoPlayerController.asset(widget.assetPath);
    await c.initialize();
    c.setLooping(true);
    c.setVolume(_muted ? 0.0 : 1.0);
    await c.play();
    if (mounted) {
      setState(() => _controller = c);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: (_controller != null && _controller!.value.isInitialized)
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : const Icon(Icons.videocam, size: 64, color: Colors.white),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      (_controller?.value.isPlaying ?? false)
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      final c = _controller;
                      if (c == null) return;
                      if (c.value.isPlaying) {
                        c.pause();
                      } else {
                        c.play();
                      }
                      setState(() {});
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _muted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      final c = _controller;
                      if (c == null) return;
                      setState(() => _muted = !_muted);
                      c.setVolume(_muted ? 0.0 : 1.0);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
