import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'firebase_service.dart';

/// Razorpay payment service — wraps the Razorpay Flutter SDK.
/// Usage:
///   final svc = RazorpayService.instance;
///   svc.init(onSuccess, onFailure, onWalletSelected);
///   svc.startPayment(amount: 500, description: 'Booking fee');
///   svc.dispose(); // call in screen dispose()
class RazorpayService {
  RazorpayService._();
  static final RazorpayService instance = RazorpayService._();

  Razorpay? _razorpay;

  // ─── Replace with your Razorpay KEY_ID ──────────────────────────────────
  // Test key  → rzp_test_XXXXXXXXXXXXXXXXX  (no real money, safe to test)
  // Live key  → rzp_live_XXXXXXXXXXXXXXXXX  (real transactions)
  // Get it from: https://dashboard.razorpay.com → Settings → API Keys
  static const _keyId = 'YOUR_RAZORPAY_KEY_ID';

  void init({
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onFailure,
    void Function(ExternalWalletResponse)? onWallet,
  }) {
    _razorpay?.clear();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    if (onWallet != null) {
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, onWallet);
    }
  }

  /// Open Razorpay checkout.
  /// [amount] is in RUPEES (we convert to paise internally).
  /// [description] appears on the Razorpay sheet.
  /// [bookingId] is stored in notes for reconciliation.
  void startPayment({
    required double amount,
    required String description,
    String? bookingId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) {
    if (kIsWeb) {
      debugPrint('[RazorpayService] Web not supported — use Razorpay JS SDK for web.');
      return;
    }
    if (_razorpay == null) {
      throw StateError('Call RazorpayService.init() before startPayment()');
    }
    final options = <String, dynamic>{
      'key': _keyId,
      'amount': (amount * 100).toInt(), // paise
      'name': 'QueueLess',
      'description': description,
      'prefill': {
        if (customerName != null) 'name': customerName,
        if (customerEmail != null) 'email': customerEmail,
        if (customerPhone != null) 'contact': customerPhone,
      },
      'notes': {
        'bookingId': bookingId ?? '',
        'app': 'queueless',
      },
      'theme': {
        'color': '#6C63FF', // primary purple
      },
      'external': {
        'wallets': ['paytm', 'phonepe', 'googlepay'],
      },
    };
    _razorpay!.open(options);
  }

  /// Save a successful payment to Firestore and update booking status.
  Future<void> handleSuccess(
    PaymentSuccessResponse response, {
    String? bookingId,
    double? amount,
  }) async {
    try {
      await FirebaseService.instance.savePayment(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? '',
        signature: response.signature ?? '',
        bookingId: bookingId,
        amount: amount,
      );
      if (bookingId != null) {
        await FirebaseService.instance.updateBookingStatus(bookingId, 'confirmed');
      }
    } catch (e) {
      debugPrint('[RazorpayService] handleSuccess error: $e');
    }
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
