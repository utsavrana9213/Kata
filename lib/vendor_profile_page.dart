import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servekeen/api_service.dart';

class VendorProfilePage extends StatefulWidget {
  const VendorProfilePage({super.key});

  @override
  State<VendorProfilePage> createState() => _VendorProfilePageState();
}

class _VendorProfilePageState extends State<VendorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = ApiService().currentUser ?? {};
    _businessNameController.text = (u['businessname'] ?? '').toString();
    _nameController.text = (u['name'] ?? '').toString();
    _emailController.text = (u['email'] ?? '').toString();
    _mobileController.text = (u['mobile'] ?? u['number'] ?? u['phone'] ?? '').toString();
    _websiteController.text = (u['bwebsite'] ?? u['businesswebsite'] ?? '').toString();
    _addressController.text = (u['address'] ?? '').toString();
    _cityController.text = (u['city'] ?? '').toString();
    _stateController.text = (u['state'] ?? '').toString();
    _pincodeController.text = (u['pincode'] ?? '').toString();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final vendor = <String, dynamic>{
        'businessname': _businessNameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'bwebsite': _websiteController.text.trim(),
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'is_active': 1,
      };
      if ((vendor['bwebsite'] as String).trim().isEmpty) vendor.remove('bwebsite');

      final result = await ApiService().upsertVendor(vendor);
      if (!mounted) return;
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor profile updated'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((result['message'] ?? 'Failed to update').toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool requiredField = true,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) {
        if (!enabled) return null;
        if (!requiredField) return null;
        if (v == null || v.trim().isEmpty) return 'Required';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vendor Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(controller: _businessNameController, label: 'Business Name', icon: Icons.business, requiredField: true),
                const SizedBox(height: 12),
                _field(controller: _nameController, label: 'Name', icon: Icons.person, requiredField: true),
                const SizedBox(height: 12),
                _field(controller: _emailController, label: 'Email', icon: Icons.email, requiredField: true, keyboardType: TextInputType.emailAddress, enabled: false),
                const SizedBox(height: 12),
                _field(controller: _mobileController, label: 'Mobile', icon: Icons.phone, requiredField: true, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _field(controller: _websiteController, label: 'Business Website', icon: Icons.language, requiredField: false, keyboardType: TextInputType.url),
                const SizedBox(height: 12),
                _field(controller: _addressController, label: 'Address', icon: Icons.location_on, requiredField: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(controller: _cityController, label: 'City', icon: Icons.location_city, requiredField: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(controller: _stateController, label: 'State', icon: Icons.map, requiredField: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _field(controller: _pincodeController, label: 'Pincode', icon: Icons.pin_drop, requiredField: true, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

