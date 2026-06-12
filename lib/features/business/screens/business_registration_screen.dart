import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/widgets/animated_card.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_input.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  const BusinessRegistrationScreen({super.key});

  @override
  State<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState extends State<BusinessRegistrationScreen> {
  int _currentStep = 0;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Clinic';
  bool _loading = false;
  String? _error;

  // Services added in step 1
  final List<Map<String, dynamic>> _services = [];
  final _serviceNameCtrl = TextEditingController();
  final _servicePriceCtrl = TextEditingController();
  final _serviceDurCtrl = TextEditingController();

  // Business hours
  final Map<String, bool> _openDays = {
    'Mon': true, 'Tue': true, 'Wed': true, 'Thu': true,
    'Fri': true, 'Sat': true, 'Sun': false,
  };

  final List<String> _categories = [
    'Clinic', 'Salon', 'Spa', 'Government', 'Consultant', 'Bank', 'Lab', 'Other'
  ];
  final List<String> _stepTitles = ['Business Info', 'Services', 'Hours', 'Confirm & Create'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    _serviceNameCtrl.dispose();
    _servicePriceCtrl.dispose();
    _serviceDurCtrl.dispose();
    super.dispose();
  }

  bool _validateStep() {
    setState(() => _error = null);
    if (_currentStep == 0) {
      if (_nameCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Business name is required');
        return false;
      }
      if (_phoneCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Phone number is required');
        return false;
      }
      if (_addressCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Address is required');
        return false;
      }
    }
    return true;
  }

  Future<void> _createBusiness() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'You must be logged in to create a business');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // Generate a new Firestore document ID
      final docRef = FirebaseFirestore.instance.collection('businesses').doc();
      final businessId = docRef.id;

      final business = BusinessModel(
        id: businessId,
        name: _nameCtrl.text.trim(),
        category: _category,
        description: _descCtrl.text.trim().isEmpty
            ? '$_category services' : _descCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        lat: 0.0,
        lng: 0.0,
        phone: _phoneCtrl.text.trim(),
        rating: 0.0,
        reviewCount: 0,
        isVerified: false,
        plan: 'free',
        ownerId: uid,
        hours: {
          for (final e in _openDays.entries) e.key: e.value,
        },
      );

      // Save business to Firestore
      await FirebaseService.instance.createBusiness(business);

      // Save each service under the business
      for (final svc in _services) {
        await FirebaseService.instance.createService(businessId, svc);
      }

      // Update user doc: set role = 'business', store businessId
      await FirebaseService.instance.updateUser(uid, {
        'role': 'business',
        'businessId': businessId,
      });

      // Initialize an empty queue for this business
      await FirebaseFirestore.instance.collection('queues').doc(businessId).set({
        'businessId': businessId,
        'currentServingToken': '-',
        'totalWaiting': 0,
        'avgWaitMinutes': 0,
        'items': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _error = 'Failed to create business: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitles[_currentStep]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (_currentStep > 0) setState(() => _currentStep--);
            else context.pop();
          },
        ),
      ),
      body: Column(
        children: [
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Step ${_currentStep + 1} of 4',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 4,
                  backgroundColor: AppColors.inputBg,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ]),
          ),
          // Error banner
          if (_error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.coralError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.coralError.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppColors.coralError, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.coralError))),
              ]),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStep(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
            child: PremiumButton(
              label: _currentStep < 3 ? 'Next →' : 'Create My Business 🚀',
              isLoading: _loading,
              onPressed: () async {
                if (!_validateStep()) return;
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                } else {
                  await _createBusiness();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return ListView(key: const ValueKey(0), padding: const EdgeInsets.all(16), children: [
          Center(child: Stack(alignment: Alignment.bottomRight, children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
              child: const Icon(Icons.store_rounded, color: Colors.white, size: 36),
            ),
            Container(
              width: 24, height: 24,
              decoration: const BoxDecoration(gradient: AppGradients.teal, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
            ),
          ])),
          const SizedBox(height: 24),
          PremiumInput(
            label: 'Business Name *',
            hint: 'e.g. Dr. Sharma Clinic',
            controller: _nameCtrl,
            prefixIcon: Icons.store_outlined,
          ),
          const SizedBox(height: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Category *', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
                filled: true, fillColor: AppColors.inputBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? 'Clinic'),
            ),
          ]),
          const SizedBox(height: 14),
          PremiumInput(
            label: 'Description',
            hint: 'What services do you offer?',
            controller: _descCtrl,
            prefixIcon: Icons.description_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          PremiumInput(
            label: 'Phone *',
            hint: '+91 98765 43210',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
          ),
          const SizedBox(height: 14),
          PremiumInput(
            label: 'Address *',
            hint: 'Shop No., Street, Area, City',
            controller: _addressCtrl,
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
          ),
        ]);

      case 1:
        return ListView(key: const ValueKey(1), padding: const EdgeInsets.all(16), children: [
          Text('Add Your Services', style: AppTextStyles.h3),
          Text('(You can add more later from dashboard)', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
          const SizedBox(height: 16),
          // Add service form
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add a Service', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
              const SizedBox(height: 12),
              PremiumInput(label: 'Service Name', hint: 'e.g. General Consultation', controller: _serviceNameCtrl),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: PremiumInput(label: 'Price (₹)', hint: '300', controller: _servicePriceCtrl, keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: PremiumInput(label: 'Duration (min)', hint: '15', controller: _serviceDurCtrl, keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (_serviceNameCtrl.text.isEmpty) return;
                    setState(() {
                      _services.add({
                        'name': _serviceNameCtrl.text.trim(),
                        'price': double.tryParse(_servicePriceCtrl.text) ?? 0.0,
                        'duration': int.tryParse(_serviceDurCtrl.text) ?? 15,
                        'isActive': true,
                      });
                      _serviceNameCtrl.clear();
                      _servicePriceCtrl.clear();
                      _serviceDurCtrl.clear();
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Service'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          if (_services.isEmpty)
            Center(child: Text('No services added yet.\nYou can skip and add later.', style: AppTextStyles.body.copyWith(color: AppColors.textHint), textAlign: TextAlign.center))
          else
            ..._services.asMap().entries.map((e) => AnimatedCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              baseShadow: AppShadows.e1,
              child: Row(children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(gradient: AppGradients.teal, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.white, size: 16)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.value['name'], style: AppTextStyles.h4),
                  Text('${e.value['duration']} min · ₹${(e.value['price'] as double).toInt()}', style: AppTextStyles.caption),
                ])),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 18),
                  onPressed: () => setState(() => _services.removeAt(e.key)),
                ),
              ]),
            )),
        ]);

      case 2:
        return ListView(key: const ValueKey(2), padding: const EdgeInsets.all(16), children: [
          Text('Business Hours', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text('Set which days you are open', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ..._openDays.keys.map((day) => AnimatedCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            baseShadow: AppShadows.e1,
            child: Row(children: [
              SizedBox(width: 40, child: Text(day, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700))),
              Expanded(
                child: Text(
                  _openDays[day]! ? '9:00 AM – 8:00 PM' : 'Closed',
                  style: TextStyle(color: _openDays[day]! ? AppColors.teal : AppColors.textHint, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Switch(
                value: _openDays[day]!,
                onChanged: (v) => setState(() => _openDays[day] = v),
                activeColor: AppColors.primary,
              ),
            ]),
          )),
        ]);

      case 3:
        return ListView(key: const ValueKey(3), padding: const EdgeInsets.all(16), children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.store_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_nameCtrl.text.isEmpty ? 'My Business' : _nameCtrl.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  Text(_category, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 12),
              if (_addressCtrl.text.isNotEmpty) _SummaryRow(Icons.location_on_outlined, _addressCtrl.text),
              if (_phoneCtrl.text.isNotEmpty) _SummaryRow(Icons.phone_outlined, _phoneCtrl.text),
              _SummaryRow(Icons.miscellaneous_services_rounded, '${_services.length} service(s) added'),
            ]),
          ),
          const SizedBox(height: 20),
          const Center(child: Column(children: [
            Icon(Icons.rocket_launch_rounded, size: 56, color: AppColors.primary),
            SizedBox(height: 12),
            Text('Ready to Go Live!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text('Tap "Create My Business" below to\ngo live and start accepting customers!',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ])),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.tealSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: AppColors.tealSuccess, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Customers can find and book you immediately after creation.', style: TextStyle(color: AppColors.tealSuccess, fontSize: 13))),
            ]),
          ),
        ]);

      default:
        return const SizedBox();
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SummaryRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
