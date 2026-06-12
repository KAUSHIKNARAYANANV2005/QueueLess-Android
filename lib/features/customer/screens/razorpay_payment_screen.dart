import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/razorpay_service.dart';
import '../../../core/utils/nav_helper.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/animated_card.dart';
import '../../../shared/widgets/glass_container.dart';

class RazorpayPaymentScreen extends StatefulWidget {
  final double amount;
  final String description;
  final String? bookingId;
  final String businessName;

  const RazorpayPaymentScreen({
    super.key,
    required this.amount,
    required this.description,
    required this.businessName,
    this.bookingId,
  });

  @override
  State<RazorpayPaymentScreen> createState() => _RazorpayPaymentScreenState();
}

class _RazorpayPaymentScreenState extends State<RazorpayPaymentScreen>
    with SingleTickerProviderStateMixin {
  bool _paying = false;
  String? _selectedMethod;
  late AnimationController _successCtrl;
  late Animation<double> _successAnim;
  bool _paymentDone = false;

  final _methods = [
    {'id': 'upi', 'label': 'UPI / GPay / PhonePe', 'icon': Icons.qr_code_rounded, 'sub': 'Instant, no charges'},
    {'id': 'card', 'label': 'Credit / Debit Card', 'icon': Icons.credit_card_rounded, 'sub': 'Visa, Mastercard, Rupay'},
    {'id': 'netbanking', 'label': 'Net Banking', 'icon': Icons.account_balance_outlined, 'sub': 'All major banks'},
    {'id': 'wallet', 'label': 'Mobile Wallets', 'icon': Icons.account_balance_wallet_rounded, 'sub': 'Paytm, PhonePe, Amazon Pay'},
  ];

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _successAnim = CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);
    _selectedMethod = 'upi';

    RazorpayService.instance.init(
      onSuccess: _handleSuccess,
      onFailure: _handleFailure,
      onWallet: _handleWallet,
    );
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    RazorpayService.instance.dispose();
    super.dispose();
  }

  // ── Payment Handlers ──────────────────────────────────────────────────────

  Future<void> _handleSuccess(PaymentSuccessResponse res) async {
    setState(() { _paying = false; _paymentDone = true; });
    _successCtrl.forward();

    // Save to Firestore
    await RazorpayService.instance.handleSuccess(
      res,
      bookingId: widget.bookingId,
      amount: widget.amount,
    );

    if (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✅ Payment successful! Booking confirmed.'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ));
        context.go('/appointments');
      }
    }
  }

  void _handleFailure(PaymentFailureResponse res) {
    if (!mounted) return;
    setState(() => _paying = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment failed: ${res.message ?? 'Unknown error'}'),
      backgroundColor: AppColors.coral,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ));
  }

  void _handleWallet(ExternalWalletResponse res) {
    if (!mounted) return;
    setState(() => _paying = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Wallet selected: ${res.walletName}'),
      backgroundColor: AppColors.amber,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ));
  }

  void _startPayment() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() => _paying = true);
    RazorpayService.instance.startPayment(
      amount: widget.amount,
      description: widget.description,
      bookingId: widget.bookingId,
      customerName: user?.displayName,
      customerEmail: user?.email,
      customerPhone: user?.phoneNumber,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tax = widget.amount * 0.18;
    final total = widget.amount + tax;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(fallback: '/home'),
        title: const Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Stack(children: [
        // Gradient top section
        Positioned(top: 0, left: 0, right: 0,
          child: Container(height: 220, decoration: const BoxDecoration(gradient: AppGradients.primary))),
        Positioned(top: -20, right: -20,
          child: Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),

        SafeArea(
          child: _paymentDone
              ? _SuccessView(anim: _successAnim)
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(children: [
                    // ── Order summary card ─────────────────────────────
                    GlassContainer.light(
                      padding: const EdgeInsets.all(16),
                      borderRadius: AppRadius.lg,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                            child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(widget.businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            Text(widget.description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ])),
                        ]),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 8),
                        _BillRow('Service Fee', '₹${widget.amount.toInt()}', white: true),
                        _BillRow('GST (18%)', '₹${tax.toInt()}', white: true),
                        const SizedBox(height: 6),
                        const Divider(color: Colors.white24),
                        _BillRow('Total Payable', '₹${total.toInt()}', white: true, bold: true),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // ── Payment methods ────────────────────────────────
                    AnimatedCard(
                      padding: const EdgeInsets.all(16),
                      baseShadow: AppShadows.e2,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Payment Method', style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        ..._methods.map((m) {
                          final isSelected = _selectedMethod == m['id'];
                          return GestureDetector(
                            key: Key('pay_method_${m['id']}'),
                            onTap: () => setState(() => _selectedMethod = m['id'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryGlow : AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    gradient: isSelected ? AppGradients.primary : null,
                                    color: isSelected ? null : AppColors.inputBg,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Icon(m['icon'] as IconData,
                                    color: isSelected ? Colors.white : AppColors.textSecondary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(m['label'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                                  Text(m['sub'] as String, style: AppTextStyles.caption),
                                ])),
                                if (isSelected)
                                  Container(
                                    width: 20, height: 20,
                                    decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
                                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                                  ),
                              ]),
                            ),
                          );
                        }),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // ── Security note ──────────────────────────────────
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.lock_rounded, size: 13, color: AppColors.textHint),
                      const SizedBox(width: 5),
                      Text('256-bit SSL · Secured by Razorpay', style: AppTextStyles.caption),
                    ]),
                    const SizedBox(height: 20),

                    // ── Pay button ─────────────────────────────────────
                    PremiumButton(
                      key: const Key('pay_now_btn'),
                      label: 'Pay ₹${total.toInt()} Now',
                      isLoading: _paying,
                      onPressed: _paying ? null : _startPayment,
                      icon: Icons.lock_rounded,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel Payment', style: TextStyle(color: AppColors.textHint)),
                    ),
                  ]),
                ),
        ),
      ]),
    );
  }
}

// ── Success overlay ────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final Animation<double> anim;
  const _SuccessView({required this.anim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ScaleTransition(
          scale: anim,
          child: Container(
            width: 120, height: 120,
            decoration: const BoxDecoration(gradient: AppGradients.teal, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
          ),
        ),
        const SizedBox(height: 28),
        Text('Payment Successful!', style: AppTextStyles.h1),
        const SizedBox(height: 10),
        Text('Your booking is confirmed.\nRedirecting to appointments...', style: AppTextStyles.body, textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Bill row helper ────────────────────────────────────────────────────────

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool white;
  final bool bold;
  const _BillRow(this.label, this.value, {this.white = false, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final color = white ? Colors.white : AppColors.textPrimary;
    final subColor = white ? Colors.white70 : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: subColor, fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        Text(value, style: TextStyle(color: color, fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
      ]),
    );
  }
}
