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
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  int _searchRequestSerial = 0;
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
  final ScrollController _chatScrollController = ScrollController();
  final List<ChatTurn> _chatHistory = [];
  List<Service> _chatSearchResults = [];
  bool _chatLoading = false;
  static const MethodChannel _voiceChannel = MethodChannel('voice_search');
  bool _voiceInProgress = false;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _homeCategories = [];
  List<String> carouselImages = [];
  List<String> brandLogos = [];

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
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
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
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
              "Hi! Tell me what service you need and where you need it. I'll find the closest matches for you.",
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

          // 3. Banner (Carousel). Keep the home promotion art local so its
          // wide crop and visual quality remain consistent on every device.
          carouselImages = const [
            'assets/images/servekeen_promo_banner_v2.png',
          ];

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
    _searchFocusNode.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
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
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _searchRequestSerial++;
      if (mounted) {
        setState(() {
          _searchQuery = '';
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }
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
    final requestId = ++_searchRequestSerial;
    setState(() => _isSearching = true);
    try {
      final results = await ApiService().searchServices(query, limit: 20);
      if (!mounted || requestId != _searchRequestSerial) return;
      var filtered = _rankAndFilterServices(results, query);
      if (filtered.isEmpty && _services.isNotEmpty) {
        filtered = _performLocalSearch(query);
      }
      setState(() {
        _searchResults = filtered;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestSerial) return;
      final fallback = _performLocalSearch(query);
      setState(() {
        _searchResults = fallback;
        _isSearching = false;
      });
      debugPrint('Search error, used local fallback: $e');
    }
  }

  List<Service> _performLocalSearch(String query) {
    if (query.trim().isEmpty) return [];
    final candidates = _showPremiumOnly
        ? _services.where((service) => service.isPremium)
        : _services;
    return rankRelevantServicesAllTiers(
      candidates,
      query,
      categoryNames: _categoryNameById,
    );
  }

  List<Service> _rankAndFilterServices(List<Service> raw, String query) {
    final filtered = _showPremiumOnly
        ? rankRelevantServices(
            raw,
            query,
            tier: VendorTier.premium,
            categoryNames: _categoryNameById,
          )
        : rankRelevantServicesAllTiers(
            raw,
            query,
            categoryNames: _categoryNameById,
          );
    return filtered;
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? const [Color(0xF21B2836), Color(0xF20A0F15)]
              : const [Color(0xF2FFFFFF), Color(0xE6DCE9EC)],
        ),
        border: Border(
          top: BorderSide(
            color: _isDarkMode ? Colors.white12 : Colors.white.withAlpha(210),
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38204670),
            blurRadius: 22,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: _brandColor.withAlpha(_isDarkMode ? 58 : 30),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: _brandColor.withAlpha(_isDarkMode ? 80 : 45),
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: selected ? 25 : 23,
              color: selected
                  ? _brandColor
                  : (_isDarkMode
                        ? _cDarkTextSecondary.withAlpha(155)
                        : _cDeepBlue.withAlpha(145)),
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? _brandColor
                  : (_isDarkMode
                        ? _cDarkTextSecondary.withAlpha(170)
                        : _cDeepBlue.withAlpha(155)),
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _navIndex,
          height: 70,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            if (index != _navIndex) setState(() => _navIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'Sell',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded),
              label: 'Ask AI',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
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
        RefreshIndicator(
          color: _cFusionPurple,
          backgroundColor: _cardSurface,
          onRefresh: _loadServices,
          child: SingleChildScrollView(
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
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: _textSecondary,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No close matches for “$_searchQuery”',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try a category, provider, or location.',
                                  style: GoogleFonts.poppins(
                                    color: _textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _searchController.clear,
                                  child: const Text('Clear search'),
                                ),
                              ],
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: _buildHeaderHero(context),
                  ),
                if (!queryActive)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Categories',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                if (!queryActive) const SizedBox(height: 10),
                if (!queryActive)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
      elevation: 10,
      scrolledUnderElevation: 0,
      shadowColor: _isDarkMode
          ? Colors.black.withAlpha(150)
          : _cDeepBlue.withAlpha(55),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDarkMode
                ? const [Color(0xF21B2836), Color(0xF20A0F15)]
                : const [Color(0xFAFFFFFF), Color(0xE8DDE9EE)],
          ),
          border: Border(
            bottom: BorderSide(
              color: _isDarkMode ? Colors.white12 : Colors.white.withAlpha(220),
            ),
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha(20),
                  Colors.white.withAlpha(230),
                  Colors.white.withAlpha(20),
                ],
              ),
            ),
          ),
        ),
      ),
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
      color: Colors.white.withAlpha(_isDarkMode ? 25 : 235),
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
              color: _showPremiumOnly ? _cElegantPink : _cDeepBlue,
            ),
            const SizedBox(width: 6),
            Text(
              _showPremiumOnly ? 'Premium' : 'Standard',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? Colors.white : _cDeepBlue,
              ),
            ),
            const SizedBox(width: 6),
            Transform.scale(
              scale: 0.85,
              child: Switch.adaptive(
                value: _showPremiumOnly,
                onChanged: (value) => setState(() => _showPremiumOnly = value),
                activeColor: _cElegantPink,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? const [Color(0xFF143257), Color(0xFF0D5C4A)]
              : const [Color(0xFF1769E0), Color(0xFF0A4EAC), Color(0xFF08775B)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(45)),
        boxShadow: [
          BoxShadow(
            color: _cDeepBlue.withAlpha(_isDarkMode ? 55 : 65),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Find trusted services near you',
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              premiumToggle,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Compare providers, ratings and prices—all in one place.',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              height: 1.4,
              color: Colors.white.withAlpha(215),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _homeQuickAction(
                  icon: Icons.near_me_rounded,
                  label: 'Near me',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NearMePage()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _homeQuickAction(
                  icon: Icons.grid_view_rounded,
                  label: 'Categories',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoriesPage()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _homeQuickAction(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Ask AI',
                  onTap: () => setState(() => _navIndex = _tabChat),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _trustSignal(Icons.verified_rounded, 'Verified'),
              _trustSignal(Icons.star_rounded, 'Top rated'),
              _trustSignal(Icons.bolt_rounded, 'Quick response'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustSignal(IconData icon, String label) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF7BF0BE)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white.withAlpha(225),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withAlpha(245),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: _cFusionPurple.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _cFusionPurple, size: 15),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _cDeepBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
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
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    children: [
                      _drawerSectionLabel('Discover'),
                      _drawerTile(Icons.home_rounded, 'Home', () {
                        Navigator.pop(context);
                        setState(() => _navIndex = _tabHome);
                      }, selected: _navIndex == _tabHome),
                      _drawerTile(
                        Icons.grid_view_rounded,
                        'Browse categories',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoriesPage(),
                            ),
                          );
                        },
                      ),
                      _drawerTile(
                        Icons.near_me_rounded,
                        'Services near me',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NearMePage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _drawerSectionLabel('Account'),
                      _drawerTile(
                        Icons.storefront_outlined,
                        'Sell on Servekeen',
                        () {
                          Navigator.pop(context);
                          setState(() => _navIndex = _tabSell);
                        },
                        selected: _navIndex == _tabSell,
                      ),
                      _drawerTile(
                        Icons.auto_awesome_rounded,
                        'Ask AI',
                        () {
                          Navigator.pop(context);
                          setState(() => _navIndex = _tabChat);
                        },
                        selected: _navIndex == _tabChat,
                      ),
                      _drawerTile(
                        Icons.person_outline_rounded,
                        'My profile',
                        () {
                          Navigator.pop(context);
                          setState(() => _navIndex = _tabProfile);
                        },
                        selected: _navIndex == _tabProfile,
                      ),
                      const SizedBox(height: 8),
                      _drawerSectionLabel('Support'),
                      _drawerTile(Icons.info_outline, 'Why Servekeen', () {
                        Navigator.pop(context);
                        _showWhyServekeen(context);
                      }),
                      _drawerTile(
                        Icons.help_outline_rounded,
                        'Help & enquiry',
                        () {
                          Navigator.pop(context);
                          _openSupportTicketSheet(context, 'Help & enquiry');
                        },
                      ),
                      const Divider(height: 24),
                      if (u == null)
                        _drawerTile(Icons.login_rounded, 'Sign in', () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        })
                      else
                        _drawerTile(Icons.logout_rounded, 'Sign out', () async {
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
    bool selected = false,
  }) {
    final color = isDestructive ? Colors.red : _brandColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _brandColor.withAlpha(_isDarkMode ? 45 : 22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _brandColor.withAlpha(70) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withAlpha(18)
                    : _subtleSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
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
            Icon(Icons.chevron_right_rounded, size: 19, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _drawerSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: _textSecondary,
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? const [Color(0xE62A3949), Color(0xE6151F2A)]
              : const [Color(0xF5FFFFFF), Color(0xDDE7EEF1)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? _brandColor.withAlpha(170)
              : _isDarkMode
              ? Colors.white12
              : Colors.white.withAlpha(225),
          width: _searchFocusNode.hasFocus ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withAlpha(70)
                : _cDeepBlue.withAlpha(35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withAlpha(_isDarkMode ? 15 : 155),
            blurRadius: 2,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: GoogleFonts.poppins(color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'Search service, provider or location',
          hintStyle: GoogleFonts.poppins(
            color: _isDarkMode
                ? _cDarkTextSecondary.withAlpha(170)
                : _cDeepBlue.withAlpha(130),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            _searchFocusNode.hasFocus
                ? Icons.manage_search_rounded
                : Icons.search,
            color: _searchFocusNode.hasFocus ? _brandColor : _textSecondary,
          ),
          suffixIconConstraints: const BoxConstraints(
            minHeight: 40,
            minWidth: 40,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(11),
                  child: SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (_searchController.text.trim().isNotEmpty)
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  tooltip: 'Clear search',
                  icon: Icon(Icons.close, color: _textSecondary),
                ),
              IconButton(
                onPressed: _startVoiceSearch,
                tooltip: 'Search by voice',
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
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          final query = value.trim();
          if (query.isEmpty) return;
          _searchDebounce?.cancel();
          _searchQuery = query;
          _performBackendSearch(query);
        },
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
          height: isSmall ? 176 : 230,
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imgUrl.startsWith('http')
                          ? Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) =>
                                  const Icon(Icons.broken_image),
                            )
                          : Image.asset(
                              imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xA8000928), Colors.transparent],
                              stops: [0.0, 0.62],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        top: 18,
                        bottom: 16,
                        width: isSmall ? 170 : 255,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Everything local,\none simple app',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isSmall ? 17 : 24,
                                height: 1.12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _bannerPoint(
                              Icons.near_me_rounded,
                              'Nearby services',
                            ),
                            _bannerPoint(
                              Icons.star_rounded,
                              'Ratings & prices',
                            ),
                            _bannerPoint(Icons.call_rounded, 'Direct contact'),
                            _bannerPoint(
                              Icons.storefront_rounded,
                              'List your business',
                            ),
                          ],
                        ),
                      ),
                    ],
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

  Widget _bannerPoint(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF71F0D2)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white.withAlpha(235),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              decoration: BoxDecoration(
                gradient: _isDarkMode
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xEFFFFFFF), Color(0xCFE1ECEB)],
                      ),
                color: _isDarkMode ? _cDarkElevatedSurface : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isDarkMode
                      ? Colors.white10
                      : Colors.white.withAlpha(220),
                ),
                boxShadow: _isDarkMode
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x24204670),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
              ),
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
            ),
          );
        } else {
          final cat = _homeCategories[index];
          final isNetwork = cat['is_network'] == true;
          final imagePath = (cat['image'] ?? '').toString();
          final id = (cat['id'] ?? '').toString();
          final label = (cat['label'] ?? '').toString();
          final matchingGif = _getCategoryIconForLabel(label);
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              decoration: BoxDecoration(
                gradient: _isDarkMode
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xF2FFFFFF), Color(0xCFE2ECEA)],
                      ),
                color: _isDarkMode ? _cDarkElevatedSurface : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isDarkMode
                      ? Colors.white10
                      : Colors.white.withAlpha(220),
                ),
                boxShadow: _isDarkMode
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x26204670),
                          blurRadius: 13,
                          offset: Offset(0, 6),
                        ),
                      ],
              ),
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
            ),
          );
        }
      },
    );
  }

  static String? _getCategoryIconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('cater') || l.contains('food') || l.contains('restaurant')) {
      return 'assets/images/categories/catering.png';
    }
    if (l.contains('banquet') ||
        l.contains('marriage') ||
        l.contains('wedding') ||
        l.contains('event')) {
      return 'assets/images/categories/banquets.png';
    }
    if (l.contains('hospital') ||
        l.contains('clinic') ||
        l.contains('doctor')) {
      return 'assets/images/categories/clinics.png';
    }
    if (l.contains('resort') ||
        l.contains('villa') ||
        l.contains('house') ||
        l.contains('estate') ||
        l.contains('property')) {
      return 'assets/images/categories/resorts.png';
    }
    if (l.contains('packer') ||
        l.contains('mover') ||
        l.contains('shift') ||
        l.contains('truck')) {
      return 'assets/images/categories/moving.png';
    }
    if (l.contains('adventure') ||
        l.contains('explore') ||
        l.contains('tour') ||
        l.contains('travel')) {
      return 'assets/images/categories/adventure.png';
    }
    if (l.contains('spa') ||
        l.contains('salon') ||
        l.contains('massage') ||
        l.contains('beauty') ||
        l.contains('hair')) {
      return 'assets/images/categories/spa.png';
    }
    if (l.contains('courier') ||
        l.contains('delivery') ||
        l.contains('scooter')) {
      return 'assets/images/categories/courier.png';
    }
    if (l.contains('dance')) return 'assets/images/categories/dance.png';
    if (l.contains('auto') || l.contains('vehicle') || l.contains('car')) {
      return 'assets/images/categories/automotive.png';
    }
    if (l.contains('fun') || l.contains('amusement')) {
      return 'assets/images/categories/fun.png';
    }
    if (l.contains('fitness') || l.contains('gym')) {
      return 'assets/images/categories/fitness.png';
    }
    if (l.contains('clinic') ||
        l.contains('hospital') ||
        l.contains('medical')) {
      return 'assets/images/categories/clinics.png';
    }
    if (l.contains('education') ||
        l.contains('school') ||
        l.contains('tutor')) {
      return 'assets/images/categories/education.png';
    }
    if (l.contains('photo') || l.contains('camera')) {
      return 'assets/images/categories/photography.png';
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
        _buildSellerApplicationForm(context, isLoggedIn: false),
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
      _buildSellerApplicationForm(context, isLoggedIn: true),
    );
  }

  Widget _buildSellerApplicationForm(
    BuildContext context, {
    required bool isLoggedIn,
  }) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      child: Form(
        key: _sellerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: _isDarkMode
                    ? const LinearGradient(
                        colors: [Color(0xFF1B2836), Color(0xFF151F2A)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFDFECFF), Color(0xFFDFF2E6)],
                      ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _isDarkMode ? Colors.white12 : Colors.white,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _softShadow,
                    blurRadius: 20,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3979D4), Color(0xFF24549B)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grow your business',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          'Reach nearby customers and manage your services in one place.',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            height: 1.4,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _sellerBenefit(
                    Icons.add_business_rounded,
                    'Create listings',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _sellerBenefit(
                    Icons.people_alt_outlined,
                    'Reach customers',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _sellerBenefit(
                    Icons.insights_rounded,
                    'View insights',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _borderColor),
                boxShadow: [
                  BoxShadow(
                    color: _softShadow,
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vendor application',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            Text(
                              'Complete the required details below.',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _sellerSubmitting
                            ? null
                            : () => _openVendorLogin(context, isLoggedIn),
                        child: const Text('Vendor login'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sellerFormLabel(
                    Icons.person_outline_rounded,
                    'Your details',
                  ),
                  const SizedBox(height: 10),
                  _sellerField(
                    controller: _sellerNameController,
                    label: 'Full name',
                    icon: Icons.person_outline_rounded,
                    requiredField: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 11),
                  _sellerField(
                    controller: _sellerEmailController,
                    label: 'Business email',
                    icon: Icons.email_outlined,
                    requiredField: true,
                    enabled: _sellerEmailController.text.trim().isEmpty,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    customValidator: (value) {
                      final email = (value ?? '').trim();
                      if (email.isEmpty) return 'Enter your business email';
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 11),
                  _sellerField(
                    controller: _sellerMobileController,
                    label: 'Contact number',
                    icon: Icons.phone_outlined,
                    requiredField: true,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    customValidator: (value) {
                      final digits = (value ?? '').replaceAll(
                        RegExp(r'\D'),
                        '',
                      );
                      if (digits.length < 10) {
                        return 'Enter a valid contact number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _sellerFormLabel(Icons.store_outlined, 'Business details'),
                  const SizedBox(height: 10),
                  _sellerField(
                    controller: _sellerBusinessNameController,
                    label: 'Business name',
                    icon: Icons.storefront_outlined,
                    requiredField: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 11),
                  _sellerField(
                    controller: _sellerPasswordController,
                    label: 'Create vendor password',
                    icon: Icons.lock_outline_rounded,
                    requiredField: true,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    customValidator: (value) {
                      if ((value ?? '').length < 6) {
                        return 'Use at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Your application will be reviewed before the vendor account is activated.',
                    style: GoogleFonts.poppins(
                      color: _textSecondary,
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _sellerSubmitting
                          ? null
                          : _submitSellerRequest,
                      icon: _sellerSubmitting
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _sellerSubmitting
                            ? 'Submitting…'
                            : 'Submit application',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
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

  Widget _sellerBenefit(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: _brandColor, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: _textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sellerFormLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: _brandColor, size: 18),
        const SizedBox(width: 7),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Future<void> _openVendorLogin(BuildContext context, bool isLoggedIn) async {
    final navigator = Navigator.of(context);
    if (isLoggedIn) await ApiService().logout();
    if (!mounted) return;
    final ok = await navigator.push(
      MaterialPageRoute(builder: (_) => const LoginScreen(vendorLogin: true)),
    );
    if (mounted && ok == true) setState(() {});
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
            label: const Text('Add a service'),
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
                    'My Services',
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
                    'View Statistics',
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
    TextInputAction? textInputAction,
    String? Function(String?)? customValidator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
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
        if (customValidator != null) return customValidator(v);
        if (!requiredField) return null;
        if (v == null || v.trim().isEmpty) return 'This field is required';
        return null;
      },
    );
  }

  Future<void> _submitSellerRequest() async {
    if (!(_sellerFormKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _sellerSubmitting = true);
    try {
      final vendor = <String, dynamic>{
        'businessname': _sellerBusinessNameController.text.trim(),
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
        final rawMessage = (vendorResult['message'] ?? 'Failed to save vendor')
            .toString();
        final message = switch (rawMessage) {
          'password_required' => 'Create a password for your vendor account.',
          'weak_password' => 'Use a password with at least 6 characters.',
          'invalid_email' => 'Enter a valid business email address.',
          'unauthorized' =>
            'This vendor account already exists. Please use Vendor login.',
          _ => rawMessage.replaceAll('_', ' '),
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not submit your application. Check your connection and try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sellerSubmitting = false);
    }
  }

  Widget _buildChatContent() {
    return _wrapWithHomeBackground(
      Column(
        children: [
          _buildChatHeader(),
          _buildChatSuggestions(),
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
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
                return _buildChatBubble(turn, isUser);
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
                            '${_chatSearchResults.length} best matches',
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: _isDarkMode
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xF8FFFFFF), Color(0xE8E5EEF2)],
                        ),
                  color: _isDarkMode ? _cardSurface : null,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isDarkMode ? _borderColor : Colors.white,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _softShadow,
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(12, 4, 5, 4),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: _brandColor, size: 22),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: GoogleFonts.poppins(color: _textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Try “spa near Chennai”',
                          hintStyle: GoogleFonts.poppins(
                            color: _textSecondary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: _sendChatMessageFromUi,
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
                        minimumSize: const Size(44, 44),
                      ),
                      onPressed: () {
                        final text = _chatController.text.trim();
                        _sendChatMessageFromUi(text);
                      },
                      child: const Icon(Icons.arrow_upward_rounded, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _softShadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3979D4), Color(0xFF24549B)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ServeKeen Assistant',
                  style: GoogleFonts.poppins(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E9F41),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Ready to find local services',
                      style: GoogleFonts.poppins(
                        color: _textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Help and feedback',
            onPressed: _openChatSupportMenu,
            icon: Icon(Icons.help_outline_rounded, color: _brandColor),
          ),
          IconButton(
            tooltip: 'Clear conversation',
            onPressed: _resetChat,
            icon: Icon(Icons.refresh_rounded, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSuggestions() {
    const suggestions = [
      ('Car rental', Icons.directions_car_rounded),
      ('Catering nearby', Icons.restaurant_rounded),
      ('Spa in Chennai', Icons.spa_rounded),
      ('Top rated clinics', Icons.local_hospital_rounded),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ActionChip(
            avatar: Icon(suggestion.$2, size: 16, color: _brandColor),
            label: Text(suggestion.$1),
            onPressed: _chatLoading
                ? null
                : () => _sendChatMessageFromUi(suggestion.$1),
            labelStyle: GoogleFonts.poppins(
              color: _textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: _cardSurface,
            side: BorderSide(color: _borderColor),
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(ChatTurn turn, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 15,
              backgroundColor: _brandColor.withAlpha(28),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 15,
                color: _brandColor,
              ),
            ),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [_brandColor, const Color(0xFF24549B)],
                      )
                    : null,
                color: isUser ? null : _cardSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 18),
                ),
                border: Border.all(
                  color: isUser ? Colors.white.withAlpha(70) : _borderColor,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _softShadow,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                turn.content,
                style: GoogleFonts.poppins(
                  color: isUser ? Colors.white : _textPrimary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetChat() {
    setState(() {
      _chatHistory
        ..clear()
        ..add(
          ChatTurn(
            role: 'ai',
            content:
                "Hi! Tell me what service you need and where you need it. I'll find the closest matches for you.",
          ),
        );
      _chatSearchResults = [];
      _chatLoading = false;
      _chatController.clear();
    });
  }

  void _sendChatMessageFromUi(String text) {
    final msg = text.trim();
    if (msg.isEmpty) return;
    setState(() {
      _chatHistory.add(ChatTurn(role: 'user', content: msg));
      _chatController.clear();
      _chatLoading = true;
    });
    _scrollChatToBottom();
    _searchAndRespond(msg);
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) return;
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _searchAndRespond(String query) async {
    try {
      final remoteResults = await ApiService().searchServices(query, limit: 30);
      if (!mounted) return;
      final candidates = <String, Service>{
        for (final service in _services) service.id: service,
        for (final service in remoteResults) service.id: service,
      }.values;
      final relevant = rankRelevantServicesAllTiers(
        candidates,
        query,
        categoryNames: _categoryNameById,
      );
      if (relevant.isEmpty) {
        setState(() {
          _chatHistory.add(
            ChatTurn(
              role: 'ai',
              content:
                  'I could not find a close match for "$query". Try a service, category, company, or location such as "car rental", "spa in Chennai", or "catering".',
            ),
          );
          _chatSearchResults = [];
          _chatLoading = false;
        });
        _scrollChatToBottom();
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
      _scrollChatToBottom();
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
      _scrollChatToBottom();
    }
  }

  Future<void> _openChatSupportMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          decoration: BoxDecoration(
            color: _isDarkMode
                ? const Color(0xFF151F2A)
                : const Color(0xFFF4F8F8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isDarkMode ? Colors.white12 : Colors.white,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x44204670), blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _textSecondary.withAlpha(80),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              ListTile(
                dense: true,
                leading: _supportMenuIcon(Icons.rate_review_outlined),
                title: const Text('Provide feedback'),
                subtitle: const Text('Share an idea or suggestion'),
                onTap: () => Navigator.pop(sheetContext, 'feedback'),
              ),
              ListTile(
                dense: true,
                leading: _supportMenuIcon(Icons.person_outline_rounded),
                title: const Text('Help as a customer'),
                subtitle: const Text('Get assistance using ServeKeen'),
                onTap: () => Navigator.pop(sheetContext, 'user'),
              ),
              ListTile(
                dense: true,
                leading: _supportMenuIcon(Icons.storefront_outlined),
                title: const Text('Help as a vendor'),
                subtitle: const Text('Support for listings and your business'),
                onTap: () => Navigator.pop(sheetContext, 'vendor'),
              ),
              ListTile(
                dense: true,
                leading: _supportMenuIcon(Icons.bug_report_outlined),
                title: const Text('Report a problem'),
                subtitle: const Text('Tell us what is not working'),
                onTap: () => Navigator.pop(sheetContext, 'bug'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    final subject = switch (action) {
      'feedback' => 'App feedback',
      'vendor' => 'Need help as vendor',
      'bug' => 'Bug report',
      _ => 'Need help as user',
    };
    await _openSupportTicketSheet(context, subject);
  }

  Widget _supportMenuIcon(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _brandColor.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: _brandColor, size: 20),
    );
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
