import 'package:flutter/material.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servekeen/theme/palette.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  static const Color _darkBackground = Color(0xFF0D1218);
  static const Color _darkSurface = Color(0xFF1B2836);
  static const Color _darkField = Color(0xFF151F2A);
  static const Color _darkTextPrimary = Color(0xFFEAF2FC);
  static const Color _darkTextSecondary = Color(0xFFB4C3D5);
  static const Color _darkBrandBlue = Color(0xFF75AFFF);

  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBackground =>
      _isDarkMode ? _darkBackground : AppPalette.softBlendBackground;
  Color get _cardSurface => _isDarkMode ? _darkSurface : Colors.white;
  Color get _fieldSurface => _isDarkMode ? _darkField : Colors.white;
  Color get _textPrimary =>
      _isDarkMode ? _darkTextPrimary : AppPalette.deepBlue;
  Color get _textSecondary =>
      _isDarkMode ? _darkTextSecondary : AppPalette.deepBlue.withAlpha(150);
  Color get _brandColor =>
      _isDarkMode ? _darkBrandBlue : AppPalette.fusionPurple;
  Color get _borderColor => _isDarkMode
      ? Colors.white.withAlpha(24)
      : AppPalette.deepBlue.withAlpha(26);
  Color get _shadowColor => _isDarkMode
      ? Colors.black.withAlpha(70)
      : AppPalette.fusionPurple.withAlpha(14);
  List<Color> get _headerGradientColors => _isDarkMode
      ? const [Color(0xFF111D2A), Color(0xFF152536), Color(0xFF102018)]
      : const [
          AppPalette.softBlendBackground,
          AppPalette.lightBlueTint,
          AppPalette.lightPinkTint,
        ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService().getCurrentUser();

      if (mounted) {
        if (result['status'] == 'success' && result['user'] != null) {
          setState(() {
            _currentUser = result['user'];
            _isLoading = false;
          });
          _animationController.forward();
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
      }
    }
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                await ApiService().logout();
                if (!mounted) return;
                Navigator.of(this.context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog({
    required String title,
    required List<Widget> fields,
    required VoidCallback onSave,
  }) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...fields,
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _editMobile() {
    final controller = TextEditingController(
      text: _currentUser?['mobile'] ?? '',
    );
    _showEditDialog(
      title: 'Edit Mobile Number',
      fields: [
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Mobile Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
      onSave: () async {
        Navigator.pop(context);
        await _updateProfile({'mobile': controller.text});
      },
    );
  }

  void _editAddress() {
    final addressCtrl = TextEditingController(
      text: _currentUser?['address'] ?? '',
    );
    final cityCtrl = TextEditingController(text: _currentUser?['city'] ?? '');
    final stateCtrl = TextEditingController(text: _currentUser?['state'] ?? '');
    final pincodeCtrl = TextEditingController(
      text: _currentUser?['pincode'] ?? '',
    );

    _showEditDialog(
      title: 'Edit Address',
      fields: [
        TextFormField(
          controller: addressCtrl,
          decoration: const InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: stateCtrl,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: pincodeCtrl,
          decoration: const InputDecoration(
            labelText: 'Pincode',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.pin_drop),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
      onSave: () async {
        Navigator.pop(context);
        await _updateProfile({
          'address': addressCtrl.text,
          'city': cityCtrl.text,
          'state': stateCtrl.text,
          'pincode': pincodeCtrl.text,
        });
      },
    );
  }

  Future<void> _updateProfile(Map<String, dynamic> data) async {
    setState(() => _isLoading = true);
    final result = await ApiService().updateProfile(data);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        _loadUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update profile'),
          ),
        );
      }
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
    bool showEditButton = false,
    VoidCallback? onEdit,
  }) {
    final effectiveIconColor = _isDarkMode
        ? _brandColor
        : iconColor ?? AppPalette.fusionPurple;
    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (_isDarkMode ? _darkField : effectiveIconColor).withAlpha(
                _isDarkMode ? 255 : 24,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (showEditButton && onEdit != null)
            FilledButton.tonalIcon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
              style: FilledButton.styleFrom(
                backgroundColor: _isDarkMode ? _darkField : null,
                foregroundColor: _brandColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfo() {
    final businessName = _currentUser?['businessname'];
    if (businessName == null || businessName.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Business Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ),
        _buildInfoCard(
          icon: Icons.business,
          title: 'Business Name',
          value: businessName.toString(),
          iconColor: AppPalette.fusionPurple,
          showEditButton: false,
        ),
      ],
    );
  }

  Widget _buildAddressInfo() {
    final address = _currentUser?['address'] ?? '';
    final city = _currentUser?['city'] ?? '';
    final state = _currentUser?['state'] ?? '';
    final pincode = _currentUser?['pincode'] ?? '';

    final fullAddress = [
      address,
      city,
      state,
      pincode,
    ].where((element) => element.toString().isNotEmpty).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Address Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (fullAddress.isNotEmpty)
          _buildInfoCard(
            icon: Icons.location_on,
            title: 'Full Address',
            value: fullAddress,
            iconColor: AppPalette.fusionPurple,
            showEditButton: false, // Edit handled by section header
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No address added yet',
              style: GoogleFonts.poppins(color: _textSecondary),
            ),
          ),

        if (city.toString().isNotEmpty)
          _buildInfoCard(
            icon: Icons.location_city,
            title: 'City',
            value: city.toString(),
            iconColor: AppPalette.fusionPurple,
          ),
        if (state.toString().isNotEmpty)
          _buildInfoCard(
            icon: Icons.map,
            title: 'State',
            value: state.toString(),
            iconColor: AppPalette.fusionPurple,
          ),
        if (pincode.toString().isNotEmpty)
          _buildInfoCard(
            icon: Icons.pin_drop,
            title: 'Pincode',
            value: pincode.toString(),
            iconColor: AppPalette.fusionPurple,
          ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Contact Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ),
        _buildInfoCard(
          icon: Icons.email,
          title: 'Email Address',
          value: _currentUser?['email'] ?? 'Not provided',
          iconColor: AppPalette.fusionPurple,
          showEditButton: false, // Email usually not editable
        ),
        _buildInfoCard(
          icon: Icons.phone,
          title: 'Mobile Number',
          value: _currentUser?['mobile']?.toString() ?? 'Not provided',
          iconColor: AppPalette.fusionPurple,
          showEditButton: false,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No User Data',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in to view your profile',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Go to Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.fusionPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _pageBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: _isDarkMode ? _darkSurface : Colors.white,
            foregroundColor: _textPrimary,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _headerGradientColors,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: _fieldSurface,
                            child: Text(
                              _currentUser!['name'][0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _brandColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentUser!['name'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  (_currentUser!['email'] ?? '').toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: _textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: _openQuickEdit,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _isDarkMode
                                  ? _darkField
                                  : Colors.white.withAlpha(220),
                              foregroundColor: _brandColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildContactInfo(),
                    const SizedBox(height: 24),
                    _buildAddressInfo(),
                    const SizedBox(height: 24),
                    _buildBusinessInfo(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openQuickEdit() {
    final nameCtrl = TextEditingController(
      text: _currentUser?['name']?.toString() ?? '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quick Edit',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameCtrl,
              style: GoogleFonts.poppins(color: _textPrimary),
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: _fieldSurface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _borderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: AppPalette.fusionPurple),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _editMobile();
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Edit Mobile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brandColor,
                      side: BorderSide(color: _brandColor.withAlpha(150)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _editAddress();
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Edit Address'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brandColor,
                      side: BorderSide(color: _brandColor.withAlpha(150)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _updateProfile({'name': nameCtrl.text});
              },
              style: FilledButton.styleFrom(backgroundColor: _brandColor),
              child: const Text('Save'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
