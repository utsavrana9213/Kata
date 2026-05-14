import 'package:flutter/material.dart';
import 'package:servekeen/home_page.dart';
import 'package:servekeen/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servekeen/theme/palette.dart';

class LoginScreen extends StatefulWidget {
  final bool vendorLogin;
  final bool adminLogin;
  final bool startInSignup;
  final String initialSignupRole;
  const LoginScreen({
    super.key,
    this.vendorLogin = false,
    this.adminLogin = false,
    this.startInSignup = false,
    this.initialSignupRole = 'user',
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _loginPhoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  int _loginMethodIndex = 0; // 0=email, 1=phone otp, 2=whatsapp otp
  bool _otpSent = false;
  String _signupRole = 'user';
  bool _showOptionalSignupDetails = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.vendorLogin || widget.adminLogin) {
      _isLoginMode = true;
      _loginMethodIndex = 0;
      _otpSent = false;
      _otpController.clear();
    }
    if (!widget.vendorLogin && !widget.adminLogin && widget.startInSignup) {
      _isLoginMode = false;
      _signupRole = widget.initialSignupRole;
      _loginMethodIndex = 0;
      _otpSent = false;
      _otpController.clear();
    }
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _autoRedirectIfLoggedIn();
  }

  Future<void> _autoRedirectIfLoggedIn() async {
    await ApiService.loadSession();
    if (!mounted) return;
    if (widget.vendorLogin || widget.adminLogin) return;
    if (ApiService().currentUser != null) {
      final nav = Navigator.of(context);
      if ((widget.vendorLogin || widget.adminLogin) && nav.canPop()) {
        nav.pop(true);
        return;
      }
      nav.pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _loginPhoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _otpChannel() {
    return _loginMethodIndex == 2 ? 'whatsapp' : 'sms';
  }

  bool _isTestValue(String value) => value.trim().toLowerCase() == 'test';

  Future<void> _showAdminSignupDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final passwordController = TextEditingController();
    bool submitting = false;
    bool obscure = true;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Signup as Admin'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Please enter name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Please enter email';
                        if (!s.contains('@'))
                          return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setDialogState(() => obscure = !obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Please enter password';
                        if (v.length < 6)
                          return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false))
                            return;
                          final dialogNav = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(context);
                          setDialogState(() => submitting = true);
                          final result = await ApiService().adminSignup(
                            nameController.text.trim(),
                            emailController.text.trim(),
                            passwordController.text,
                          );
                          if (!mounted || !dialogNav.mounted) return;
                          if (result['status'] == 'success') {
                            dialogNav.pop(true);
                            return;
                          }
                          setDialogState(() => submitting = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                (result['message'] ?? 'Signup failed')
                                    .toString(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign Up'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (ok == true) {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop(true);
        return;
      }
      nav.pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  Future<void> _sendOtp() async {
    final phone = _loginPhoneController.text.trim();
    if (!_isTestValue(phone) && (phone.isEmpty || phone.length < 10)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService().requestOtp(
        channel: _otpChannel(),
        phone: phone,
      );
      if (!mounted) return;
      if (result['status'] == 'success') {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (_isLoginMode) {
        if (_loginMethodIndex == 0) {
          if (widget.adminLogin) {
            result = await ApiService().adminLogin(
              _emailController.text.trim(),
              _passwordController.text,
            );
          } else if (widget.vendorLogin) {
            result = await ApiService().vendorLogin(
              _emailController.text.trim(),
              _passwordController.text,
            );
          } else {
            result = await ApiService().login(
              _emailController.text.trim(),
              _passwordController.text,
            );
          }
        } else {
          result = await ApiService().verifyOtp(
            channel: _otpChannel(),
            phone: _loginPhoneController.text.trim(),
            otp: _otpController.text.trim(),
          );
        }
      } else {
        result = await ApiService().signup({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'mobile': _mobileController.text.trim(),
          'businessname': _businessNameController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
          'role': _signupRole,
          'plan': 'free',
        });
      }

      if (!mounted) return;

      if (result['status'] == 'success') {
        if (!_isLoginMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Logging in...'),
              backgroundColor: Colors.green,
            ),
          );
          // Auto-login after signup
          result = await ApiService().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
          if (!mounted) return;
        }

        if (result['status'] == 'success') {
          final nav = Navigator.of(context);
          if ((widget.vendorLogin || widget.adminLogin) && nav.canPop()) {
            nav.pop(true);
            return;
          }
          nav.pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppPalette.fusionPurple),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppPalette.deepBlue.withAlpha(28)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppPalette.deepBlue.withAlpha(28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppPalette.fusionPurple,
            width: 2,
          ),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVendor = widget.vendorLogin;
    final isAdmin = widget.adminLogin;
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Header
                      const Icon(
                        Icons.account_circle,
                        size: 80,
                        color: AppPalette.fusionPurple,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isAdmin
                            ? 'Admin Login'
                            : (isVendor
                                  ? 'Vendor Login'
                                  : (_isLoginMode
                                        ? 'Welcome Back!'
                                        : 'Create Account')),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.deepBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAdmin
                            ? 'Sign in to manage your admin account'
                            : (isVendor
                                  ? 'Sign in to manage your vendor account'
                                  : (_isLoginMode
                                        ? 'Sign in to continue your journey'
                                        : 'Join us to explore amazing services')),
                        style: TextStyle(
                          fontSize: 16,
                          color: AppPalette.deepBlue.withAlpha(150),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      if (_isLoginMode && !isVendor && !isAdmin) ...[
                        ToggleButtons(
                          isSelected: [
                            _loginMethodIndex == 0,
                            _loginMethodIndex == 1,
                            _loginMethodIndex == 2,
                          ],
                          onPressed: _isLoading
                              ? null
                              : (i) {
                                  setState(() {
                                    _loginMethodIndex = i;
                                    _otpSent = false;
                                    _otpController.clear();
                                  });
                                },
                          borderRadius: BorderRadius.circular(12),
                          constraints: const BoxConstraints(minHeight: 44),
                          color: AppPalette.deepBlue,
                          selectedColor: Colors.white,
                          fillColor: AppPalette.fusionPurple,
                          borderColor: AppPalette.deepBlue.withAlpha(40),
                          selectedBorderColor: AppPalette.fusionPurple,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'Email',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'Phone OTP',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'WhatsApp OTP',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Login/Signup Fields
                      if (!_isLoginMode && !isVendor && !isAdmin) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppPalette.deepBlue.withAlpha(26),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppPalette.fusionPurple.withAlpha(14),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppPalette.fusionPurple.withAlpha(
                                        24,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: AppPalette.fusionPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Basic info',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppPalette.deepBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name *',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return 'Full name is required';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _mobileController,
                                label: 'Mobile Number *',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  final v = (value ?? '').trim();
                                  if (v.isEmpty)
                                    return 'Mobile number is required';
                                  if (v.length < 10)
                                    return 'Enter a valid mobile number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _signupRole,
                                decoration: InputDecoration(
                                  labelText: 'Role',
                                  prefixIcon: const Icon(
                                    Icons.badge,
                                    color: AppPalette.fusionPurple,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppPalette.deepBlue.withAlpha(28),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppPalette.deepBlue.withAlpha(28),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppPalette.fusionPurple,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'user',
                                    child: Text('User'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'seller',
                                    child: Text('Seller'),
                                  ),
                                ],
                                onChanged: _isLoading
                                    ? null
                                    : (v) => setState(
                                        () => _signupRole = v ?? 'user',
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppPalette.deepBlue.withAlpha(26),
                            ),
                          ),
                          child: Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: _showOptionalSignupDetails,
                              onExpansionChanged: (v) => setState(
                                () => _showOptionalSignupDetails = v,
                              ),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppPalette.fusionPurple.withAlpha(24),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.tune,
                                  color: AppPalette.fusionPurple,
                                ),
                              ),
                              title: Text(
                                'Optional details',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.deepBlue,
                                ),
                              ),
                              subtitle: Text(
                                'Business & address (optional)',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppPalette.deepBlue.withAlpha(150),
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                        controller: _businessNameController,
                                        label: 'Business Name (Optional)',
                                        icon: Icons.business,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTextField(
                                        controller: _addressController,
                                        label: 'Address (Optional)',
                                        icon: Icons.home,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _cityController,
                                              label: 'City (Optional)',
                                              icon: Icons.location_city,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _stateController,
                                              label: 'State (Optional)',
                                              icon: Icons.map,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTextField(
                                        controller: _pincodeController,
                                        label: 'Pincode (Optional)',
                                        icon: Icons.pin_drop,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          final v = (value ?? '').trim();
                                          if (v.isEmpty) return null;
                                          if (v.length != 6)
                                            return 'Enter a valid 6-digit pincode';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppPalette.fusionPurple.withAlpha(24),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: AppPalette.fusionPurple,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Login credentials',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.deepBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],

                      if (_isLoginMode &&
                          _loginMethodIndex != 0 &&
                          !isVendor &&
                          !isAdmin) ...[
                        _buildTextField(
                          controller: _loginPhoneController,
                          label: 'Phone Number',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (_isTestValue(value)) {
                              return null;
                            }
                            if (value.trim().length < 10) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            child: Text(_otpSent ? 'Resend OTP' : 'Send OTP'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _otpController,
                          label: 'OTP',
                          icon: Icons.password,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter OTP';
                            }
                            if (_isTestValue(value)) {
                              return null;
                            }
                            if (value.trim().length < 4) {
                              return 'Please enter a valid OTP';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Common Fields (Email & Password)
                      if (!_isLoginMode || _loginMethodIndex == 0) ...[
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address *',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (_isTestValue(value)) {
                              return null;
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password *',
                          icon: Icons.lock,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (_isTestValue(value)) {
                              return null;
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.fusionPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: AppPalette.fusionPurple.withAlpha(77),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isAdmin
                                      ? 'Login as Admin'
                                      : (isVendor
                                            ? 'Login as Vendor'
                                            : (_isLoginMode
                                                  ? (_loginMethodIndex == 0
                                                        ? 'Sign In'
                                                        : 'Verify & Sign In')
                                                  : 'Create Account')),
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Toggle Button
                      if (!isVendor && !isAdmin)
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isLoginMode = !_isLoginMode;
                                  });
                                },
                          child: RichText(
                            text: TextSpan(
                              text: _isLoginMode
                                  ? "Don't have an account? "
                                  : "Already have an account? ",
                              style: TextStyle(color: Colors.grey[600]),
                              children: [
                                TextSpan(
                                  text: _isLoginMode ? 'Sign Up' : 'Sign In',
                                  style: const TextStyle(
                                    color: AppPalette.fusionPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (isVendor) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const HomePage(initialTab: 1),
                                    ),
                                  );
                                },
                          child: const Text('Signup as Vendor'),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const LoginScreen(adminLogin: true),
                                    ),
                                  );
                                },
                          child: const Text('Login as Admin'),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _showAdminSignupDialog,
                          child: const Text('Signup as Admin'),
                        ),
                      ],
                      if (isAdmin) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isLoading ? null : _showAdminSignupDialog,
                          child: const Text('Signup as Admin'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
