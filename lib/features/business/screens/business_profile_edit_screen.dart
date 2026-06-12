import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_input.dart';

class BusinessProfileEditScreen extends StatefulWidget {
  const BusinessProfileEditScreen({super.key});

  @override
  State<BusinessProfileEditScreen> createState() => _BusinessProfileEditScreenState();
}

class _BusinessProfileEditScreenState extends State<BusinessProfileEditScreen> {
  final _nameCtrl = TextEditingController(text: 'Dr. Sharma Clinic');
  final _descCtrl = TextEditingController(text: 'Quality healthcare for all.');
  final _phoneCtrl = TextEditingController(text: '+91 98765 43210');
  final _emailCtrl = TextEditingController(text: 'drsharma@clinic.com');
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Business Profile'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Banner/logo area
            Stack(alignment: Alignment.center, children: [
              Container(height: 120, decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(16))),
              Column(children: [
                const SizedBox(height: 60),
                Stack(alignment: Alignment.bottomRight, children: [
                  Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppShadows.e2), child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 36)),
                  Container(width: 28, height: 28, decoration: const BoxDecoration(gradient: AppGradients.teal, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14)),
                ]),
              ]),
            ]),
            const SizedBox(height: 24),
            PremiumInput(label: 'Business Name', hint: 'Your business name', controller: _nameCtrl, prefixIcon: Icons.store_outlined),
            const SizedBox(height: 14),
            PremiumInput(label: 'Description', hint: 'Short description', controller: _descCtrl, prefixIcon: Icons.description_outlined, maxLines: 3),
            const SizedBox(height: 14),
            PremiumInput(label: 'Phone', hint: '+91 99999 99999', controller: _phoneCtrl, keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined),
            const SizedBox(height: 14),
            PremiumInput(label: 'Email', hint: 'business@email.com', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined),
            const SizedBox(height: 24),
            PremiumButton(
              label: 'Save Changes',
              isLoading: _loading,
              onPressed: () async {
                setState(() => _loading = true);
                try {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    final biz = await FirebaseService.instance.getBusinessByOwner(uid);
                    if (biz != null) {
                      await FirebaseService.instance.updateBusiness(biz.id, {
                        'name': _nameCtrl.text.trim(),
                        'description': _descCtrl.text.trim(),
                        'phone': _phoneCtrl.text.trim(),
                        'email': _emailCtrl.text.trim(),
                      });
                    }
                  }
                  if (mounted) {
                    setState(() => _loading = false);
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated!')));
                  }
                } catch (e) {
                  if (mounted) setState(() => _loading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
