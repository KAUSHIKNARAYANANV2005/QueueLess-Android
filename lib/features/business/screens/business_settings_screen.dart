import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_input.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../core/theme/theme_provider.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  BusinessModel? _business;
  bool _loading = true;
  bool _saving = false;
  
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  double _lat = 0.0;
  double _lng = 0.0;
  bool _isOpen = true;
  
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final Map<String, Map<String, dynamic>> _hours = {};

  @override
  void initState() {
    super.initState();
    // Initialize default hours
    for (var day in _days) {
      _hours[day] = {'isOpen': true, 'start': '09:00 AM', 'end': '06:00 PM'};
    }
    _loadSettings();
  }
  
  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final biz = await FirebaseService.instance.getBusinessByOwner(uid);
      if (biz != null) {
        _business = biz;
        _nameCtrl.text = _business!.name;
        _categoryCtrl.text = _business!.category;
        _phoneCtrl.text = _business!.phone;
        _addressCtrl.text = _business!.address;
        _descCtrl.text = _business!.description;
        _lat = _business!.lat;
        _lng = _business!.lng;
        _isOpen = _business!.isOpen;
        
        if (_business!.hours != null) {
          for (var day in _days) {
            if (_business!.hours!.containsKey(day)) {
              _hours[day] = Map<String, dynamic>.from(_business!.hours![day]);
            }
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _geocodeAddress() async {
    try {
      List<Location> locations = await locationFromAddress(_addressCtrl.text);
      if (locations.isNotEmpty) {
        setState(() {
          _lat = locations.first.latitude;
          _lng = locations.first.longitude;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address geocoded successfully!'), backgroundColor: AppColors.tealSuccess),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geocoding failed: $e'), backgroundColor: AppColors.coralError),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_business == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseService.instance.updateBusiness(_business!.id, {
        'name': _nameCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'lat': _lat,
        'lng': _lng,
        'isOpen': _isOpen,
        'hours': _hours,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved!'), backgroundColor: AppColors.tealSuccess),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.coralError),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectTime(String day, String field) async {
    final currentStr = _hours[day]![field] as String;
    final parts = currentStr.split(' ');
    final hm = parts[0].split(':');
    int h = int.parse(hm[0]);
    int m = int.parse(hm[1]);
    if (parts[1] == 'PM' && h != 12) h += 12;
    if (parts[1] == 'AM' && h == 12) h = 0;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
    );
    if (time != null && mounted) {
      // ignore: use_build_context_synchronously
      final formatted = time.format(context);
      setState(() {
        _hours[day]![field] = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Venue Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venue Settings'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.go('/dashboard')),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: isDark ? AppGradients.bgDark : AppGradients.bgLight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business status toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: _isOpen ? AppGradients.teal : const LinearGradient(colors: [Color(0xFFB0BEC5), Color(0xFF90A4AE)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.e2,
                ),
                child: Row(children: [
                  const Icon(Icons.store_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Business Status', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(_isOpen ? 'Open for Bookings' : 'Closed', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  ])),
                  Switch(value: _isOpen, onChanged: (v) => setState(() => _isOpen = v), activeColor: Colors.white, activeTrackColor: Colors.white38),
                ]),
              ),
              const SizedBox(height: 24),
              // Theme Mode toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.e1,
                ),
                child: Row(
                  children: [
                    Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Dark Mode', style: AppTextStyles.h4)),
                    Switch(
                      value: isDark,
                      onChanged: (v) {
                        themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('General Data', style: AppTextStyles.h2),
              const SizedBox(height: 12),
              isDark ? GlassContainer.dark(child: _buildGeneralForm()) : GlassContainer.light(child: _buildGeneralForm()),
              const SizedBox(height: 24),
              Text('Operating Hours', style: AppTextStyles.h2),
              const SizedBox(height: 12),
              isDark ? GlassContainer.dark(child: _buildHoursForm()) : GlassContainer.light(child: _buildHoursForm()),
              const SizedBox(height: 24),
              PremiumButton(
                label: 'Save Changes',
                isLoading: _saving,
                onPressed: _saveSettings,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.coralError),
                label: const Text('Sign Out', style: TextStyle(color: AppColors.coralError, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  side: const BorderSide(color: AppColors.coralError),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGeneralForm() {
    return Column(
      children: [
        PremiumInput(label: 'Business Name', controller: _nameCtrl, prefixIcon: Icons.storefront_outlined),
        const SizedBox(height: 16),
        PremiumInput(label: 'Category', controller: _categoryCtrl, prefixIcon: Icons.category_outlined),
        const SizedBox(height: 16),
        PremiumInput(label: 'Contact Phone', controller: _phoneCtrl, keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined),
        const SizedBox(height: 16),
        PremiumInput(label: 'Description', controller: _descCtrl, prefixIcon: Icons.description_outlined),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: PremiumInput(label: 'Address', controller: _addressCtrl, prefixIcon: Icons.location_on_outlined)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.map_outlined, color: AppColors.primary),
              onPressed: _geocodeAddress,
              tooltip: 'Geocode Address',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
              child: Text('Lat: ${_lat.toStringAsFixed(4)}', style: AppTextStyles.bodySmall),
            )),
            const SizedBox(width: 8),
            Expanded(child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
              child: Text('Lng: ${_lng.toStringAsFixed(4)}', style: AppTextStyles.bodySmall),
            )),
          ],
        )
      ],
    );
  }
  
  Widget _buildHoursForm() {
    return Column(
      children: _days.map((day) {
        final data = _hours[day]!;
        final isOpen = data['isOpen'] as bool;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Row(
                  children: [
                    Checkbox(
                      value: isOpen,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => data['isOpen'] = v ?? false),
                    ),
                    Expanded(child: Text(day.substring(0, 3), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              Expanded(
                child: isOpen 
                  ? Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(day, 'start'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: Text(data['start'], style: AppTextStyles.bodySmall),
                            ),
                          ),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('-')),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(day, 'end'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: Text(data['end'], style: AppTextStyles.bodySmall),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(child: Text('Closed', style: TextStyle(color: AppColors.textHint))),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
