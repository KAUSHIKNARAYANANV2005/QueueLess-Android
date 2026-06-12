import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/business_model.dart';
import '../../shared/models/queue_model.dart';
import '../../shared/models/review_model.dart';
import '../../shared/models/user_model.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '378813036718-prm8mca23ojju9puvl3l4iq0c78mp7oo.apps.googleusercontent.com'
        : null,
    serverClientId: kIsWeb
        ? null
        : '378813036718-prm8mca23ojju9puvl3l4iq0c78mp7oo.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // ─── AUTH ────────────────────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? getCurrentUser() => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password. Please try again.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'user-disabled': return 'This account has been disabled.';
      case 'too-many-requests': return 'Too many attempts. Please try again later.';
      case 'invalid-credential': return 'Invalid credentials. Please check email and password.';
      case 'email-already-in-use': return 'An account with this email already exists.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'network-request-failed': return 'No internet connection. Please check your network.';
      case 'operation-not-allowed': return 'This sign-in method is not enabled.';
      default: return 'Authentication failed. Please try again.';
    }
  }

  Future<UserCredential?> signInWithGoogle({String role = 'customer'}) async {
    UserCredential cred;
    if (kIsWeb) {
      cred = await _auth.signInWithPopup(GoogleAuthProvider()..addScope('email'));
    } else {
      final g = await _googleSignIn.signIn();
      if (g == null) return null;
      final ga = await g.authentication;
      cred = await _auth.signInWithCredential(
          GoogleAuthProvider.credential(accessToken: ga.accessToken, idToken: ga.idToken));
    }
    final doc = await _firestore.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(cred.user!.uid).set(UserModel(
        id: cred.user!.uid,
        name: cred.user!.displayName ?? 'User',
        email: cred.user!.email ?? '',
        phone: cred.user!.phoneNumber ?? '',
        role: role,
        createdAt: DateTime.now(),
      ).toJson());
    }
    return cred;
  }

  Future<UserCredential> register(String name, String email, String password, String role,
      {String phone = ''}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await cred.user?.updateDisplayName(name);
      await _firestore.collection('users').doc(cred.user!.uid).set(UserModel(
        id: cred.user!.uid, name: name, email: email, phone: phone,
        role: role, createdAt: DateTime.now(),
      ).toJson());
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  Future<bool> signInWithPhone(String phone,
      void Function(String vId, int? resendToken) onCodeSent,
      void Function(FirebaseAuthException e) onVerificationFailed) async {
    if (kIsWeb) {
      onVerificationFailed(FirebaseAuthException(code: 'not-supported',
          message: 'Phone auth not supported on web.'));
      return false;
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (c) async => _auth.signInWithCredential(c),
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
    return true;
  }

  Future<UserCredential> verifyOTP(String verificationId, String smsCode) async {
    final cred = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
    final uc = await _auth.signInWithCredential(cred);
    final doc = await _firestore.collection('users').doc(uc.user!.uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(uc.user!.uid).set(UserModel(
        id: uc.user!.uid, name: uc.user!.displayName ?? 'User',
        email: uc.user!.email ?? '', phone: uc.user!.phoneNumber ?? '',
        role: 'customer', createdAt: DateTime.now(),
      ).toJson());
    }
    return uc;
  }

  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // ─── USER ─────────────────────────────────────────────────────────────────

  Future<UserModel?> getUserById(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (!doc.exists) return null;
      return UserModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) { return null; }
  }

  Stream<UserModel?> getUserStream(String id) {
    return _firestore.collection('users').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) =>
      _firestore.collection('users').doc(id).update(data);

  // ─── BUSINESSES ──────────────────────────────────────────────────────────

  Future<List<BusinessModel>> getNearbyBusinesses(
      double lat, double lng, String? category) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('businesses');
      if (category != null && category.isNotEmpty && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }
      final snap = await query.limit(20).get();
      final results = snap.docs
          .map((d) => BusinessModel.fromJson({...d.data(), 'id': d.id}))
          .toList();
      return results.isEmpty ? _mockBusinesses() : results;
    } catch (e) { return _mockBusinesses(); }
  }

  Future<BusinessModel?> getBusinessById(String id) async {
    try {
      final doc = await _firestore.collection('businesses').doc(id).get();
      if (!doc.exists) {
        return _mockBusinesses().firstWhere((b) => b.id == id,
            orElse: () => _mockBusinesses().first);
      }
      return BusinessModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) { return null; }
  }

  Stream<BusinessModel?> getBusinessStream(String id) {
    return _firestore.collection('businesses').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BusinessModel.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  Future<BusinessModel?> getBusinessByOwner(String ownerId) async {
    try {
      final snap = await _firestore.collection('businesses')
          .where('ownerId', isEqualTo: ownerId)
          .limit(1).get();
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      return BusinessModel.fromJson({...d.data(), 'id': d.id});
    } catch (e) { return null; }
  }

  Future<void> createBusiness(BusinessModel business) async {
    await _firestore.collection('businesses').doc(business.id).set(business.toJson());
  }

  Future<void> updateBusiness(String id, Map<String, dynamic> data) =>
      _firestore.collection('businesses').doc(id).update(data);

  Future<List<BusinessModel>> searchBusinesses(String query) async {
    try {
      final snap = await _firestore.collection('businesses').limit(50).get();
      final q = query.toLowerCase();
      return snap.docs
          .where((d) =>
              (d.data()['name'] ?? '').toString().toLowerCase().contains(q) ||
              (d.data()['category'] ?? '').toString().toLowerCase().contains(q) ||
              (d.data()['address'] ?? '').toString().toLowerCase().contains(q))
          .map((d) => BusinessModel.fromJson({...d.data(), 'id': d.id}))
          .toList();
    } catch (e) {
      return _mockBusinesses()
          .where((b) => b.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  // ─── SERVICES ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getServices(String businessId) async {
    try {
      final snap = await _firestore.collection('businesses')
          .doc(businessId).collection('services')
          .where('isActive', isEqualTo: true).get();
      if (snap.docs.isEmpty) return _mockServices();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) { return _mockServices(); }
  }

  Future<String> createService(String businessId, Map<String, dynamic> data) async {
    data['isActive'] = true;
    data['createdAt'] = FieldValue.serverTimestamp();
    final doc = await _firestore.collection('businesses')
        .doc(businessId).collection('services').add(data);
    return doc.id;
  }

  Future<void> updateService(String businessId, String serviceId,
      Map<String, dynamic> data) async {
    await _firestore.collection('businesses').doc(businessId)
        .collection('services').doc(serviceId).update(data);
  }

  Future<void> deleteService(String businessId, String serviceId) async {
    await _firestore.collection('businesses').doc(businessId)
        .collection('services').doc(serviceId).update({'isActive': false});
  }

  // ─── STAFF ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getStaff(String businessId) async {
    try {
      final snap = await _firestore.collection('businesses')
          .doc(businessId).collection('staff').get();
      if (snap.docs.isEmpty) return _mockStaff();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) { return _mockStaff(); }
  }

  Future<void> addStaff(String businessId, Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('businesses')
        .doc(businessId).collection('staff').add(data);
  }

  Future<void> updateStaff(String businessId, String staffId,
      Map<String, dynamic> data) async {
    await _firestore.collection('businesses').doc(businessId)
        .collection('staff').doc(staffId).update(data);
  }

  Future<void> removeStaff(String businessId, String staffId) async {
    await _firestore.collection('businesses').doc(businessId)
        .collection('staff').doc(staffId).delete();
  }

  // ─── BOOKINGS ────────────────────────────────────────────────────────────

  Future<String> createBooking(BookingModel booking) async {
    final data = booking.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    final ref = await _firestore.collection('bookings').add(data);
    await _firestore.collection('bookings').doc(ref.id).update({'id': ref.id});
    return ref.id;
  }

  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final snap = await _firestore.collection('bookings')
          .where('customerId', isEqualTo: userId).get();
      final list = snap.docs.map((d) => BookingModel.fromJson({...d.data(), 'id': d.id})).toList();
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return list;
    } catch (e) { return []; }
  }

  Stream<List<BookingModel>> getUserBookingsStream(String userId) {
    return _firestore.collection('bookings')
        .where('customerId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => BookingModel.fromJson({...d.data(), 'id': d.id})).toList();
          list.sort((a, b) => (b.createdAt ?? b.dateTime).compareTo(a.createdAt ?? a.dateTime));
          return list;
        })
        .handleError((_) => <BookingModel>[]);
  }

  Future<List<BookingModel>> getBusinessBookings(String businessId, DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final snap = await _firestore.collection('bookings')
          .where('businessId', isEqualTo: businessId)
          .get();
      final all = snap.docs.map((d) => BookingModel.fromJson({...d.data(), 'id': d.id})).toList();
      return all.where((b) => b.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) && b.dateTime.isBefore(end)).toList();
    } catch (e) { return []; }
  }

  Stream<List<BookingModel>> getBusinessBookingsStream(String businessId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _firestore.collection('bookings')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((s) {
          final all = s.docs.map((d) => BookingModel.fromJson({...d.data(), 'id': d.id})).toList();
          final filtered = all.where((b) => b.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) && b.dateTime.isBefore(end)).toList();
          filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return filtered;
        })
        .handleError((_) => <BookingModel>[]);
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection('bookings').doc(bookingId)
        .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> cancelBooking(String bookingId) => updateBookingStatus(bookingId, 'cancelled');

  Future<void> rescheduleBooking(String bookingId, DateTime newDateTime) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'dateTime': Timestamp.fromDate(newDateTime),
      'status': 'confirmed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── QUEUE ───────────────────────────────────────────────────────────────

  Stream<QueueModel> getQueueStream(String businessId) {
    return _firestore.collection('queues').doc(businessId).snapshots().map((snap) {
      if (!snap.exists) {
        return QueueModel(businessId: businessId, currentServingToken: '-',
            totalWaiting: 0, avgWaitMinutes: 0, items: []);
      }
      return QueueModel.fromJson({...snap.data()!, 'businessId': businessId});
    });
  }

  Future<void> addToQueue(String businessId, String bookingId,
      String customerName, String serviceName) async {
    final ref = _firestore.collection('queues').doc(businessId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final currentItems =
          snap.exists ? (snap.data()!['items'] as List<dynamic>?) ?? [] : [];
      final position = currentItems.length + 1;
      final newItem = QueueItem(
        bookingId: bookingId, customerName: customerName,
        serviceName: serviceName, position: position,
        status: 'waiting', waitMinutes: position * 8,
      ).toJson();
      tx.set(ref, {
        'businessId': businessId,
        'totalWaiting': position,
        'avgWaitMinutes': 8,
        'currentServingToken': snap.exists
            ? (snap.data()!['currentServingToken'] ?? '-') : '-',
        'items': [...currentItems, newItem],
      }, SetOptions(merge: true));
    });
  }

  Future<void> serveNext(String businessId) async {
    final ref = _firestore.collection('queues').doc(businessId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final items = List<Map<String, dynamic>>.from(snap.data()!['items'] ?? []);
      if (items.isEmpty) return;
      final serving = items.removeAt(0);

      // Recalculate remaining items
      for (int i = 0; i < items.length; i++) {
        items[i]['position'] = i + 1;
        items[i]['waitMinutes'] = (i + 1) * 8;
      }

      final rawId = serving['bookingId'] ?? '';
      String token = rawId.length > 4 ? rawId.substring(rawId.length - 4).toUpperCase() : rawId.toUpperCase();
      if (!token.startsWith('B') && !token.startsWith('W')) {
        token = 'T-$token';
      }

      tx.update(ref, {
        'currentServingToken': token.isEmpty ? '-' : token,
        'currentServingName': serving['customerName'] ?? 'Walk-in',
        'currentServingService': serving['serviceName'] ?? 'General',
        'totalWaiting': items.length,
        'items': items,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> skipCustomer(String businessId, String bookingId) async {
    final ref = _firestore.collection('queues').doc(businessId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final items = List<Map<String, dynamic>>.from(snap.data()!['items'] ?? []);
      final idx = items.indexWhere((e) => e['bookingId'] == bookingId);
      if (idx >= 0) {
        final item = items.removeAt(idx);
        item['status'] = 'skipped';
        items.add(item);

        // Recalculate positions
        for (int i = 0; i < items.length; i++) {
          items[i]['position'] = i + 1;
          items[i]['waitMinutes'] = (i + 1) * 8;
        }
      }
      tx.update(ref, {
        'totalWaiting': items.length,
        'items': items,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  // ─── REVIEWS ─────────────────────────────────────────────────────────────

  Future<void> createReview(String businessId, String customerId,
      double rating, String text) async {
    final user = _auth.currentUser;
    await _firestore.collection('reviews').add({
      'businessId': businessId,
      'customerId': customerId,
      'customerName': user?.displayName ?? 'Anonymous',
      'rating': rating,
      'text': text,
      'reply': null,
      'createdAt': Timestamp.now(),
    });
    try {
      final snap = await _firestore.collection('reviews')
          .where('businessId', isEqualTo: businessId).get();
      if (snap.docs.isNotEmpty) {
        final avg = snap.docs
                .map((d) => (d.data()['rating'] as num).toDouble())
                .reduce((a, b) => a + b) /
            snap.docs.length;
        await _firestore.collection('businesses').doc(businessId)
            .update({'rating': avg, 'reviewCount': snap.docs.length});
      }
    } catch (_) {}
  }

  Future<List<ReviewModel>> getReviews(String businessId) async {
    try {
      final snap = await _firestore.collection('reviews')
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true).get();
      return snap.docs.map((d) => ReviewModel.fromJson({...d.data(), 'id': d.id})).toList();
    } catch (e) { return []; }
  }

  Stream<List<ReviewModel>> getReviewsStream(String businessId) {
    return _firestore.collection('reviews')
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ReviewModel.fromJson({...d.data(), 'id': d.id})).toList())
        .handleError((_) => <ReviewModel>[]);
  }

  Future<void> replyToReview(String reviewId, String reply) async {
    await _firestore.collection('reviews').doc(reviewId)
        .update({'reply': reply, 'repliedAt': FieldValue.serverTimestamp()});
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final snap = await _firestore.collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true).limit(50).get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) { return _mockNotifications(); }
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    try {
      final snap = await _firestore.collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false).get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Get stream of notifications for user
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _firestore.collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList())
        .handleError((_) => <Map<String, dynamic>>[]);
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  /// Save a completed Razorpay payment to Firestore
  Future<void> savePayment({
    required String paymentId,
    required String orderId,
    required String signature,
    String? bookingId,
    double? amount,
  }) async {
    final uid = _auth.currentUser?.uid;
    await _firestore.collection('payments').add({
      'paymentId': paymentId,
      'orderId': orderId,
      'signature': signature,
      'bookingId': bookingId ?? '',
      'amount': amount ?? 0.0,
      'userId': uid ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'success',
    });
    // Also update wallet transactions
    if (uid != null && amount != null) {
      await _firestore.collection('transactions').add({
        'userId': uid,
        'title': 'Payment',
        'amount': -amount,
        'type': 'debit',
        'paymentId': paymentId,
        'status': 'success',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Add money to wallet via payment
  Future<void> addToWallet(String userId, double amount, String paymentId) async {
    await _firestore.collection('users').doc(userId).update({
      'walletBalance': FieldValue.increment(amount),
    });
    await _firestore.collection('transactions').add({
      'userId': userId,
      'title': 'Wallet Top-up',
      'amount': amount,
      'type': 'credit',
      'paymentId': paymentId,
      'status': 'success',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get admin analytics (platform-wide stats)
  Future<Map<String, dynamic>> getAdminAnalytics() async {
    try {
      final usersCount = await _firestore.collection('users').count().get();
      final businessesCount = await _firestore.collection('businesses').count().get();
      final bookingsCount = await _firestore.collection('bookings').count().get();
      return {
        'totalUsers': usersCount.count ?? 0,
        'totalBusinesses': businessesCount.count ?? 0,
        'totalBookings': bookingsCount.count ?? 0,
      };
    } catch (e) {
      return {'totalUsers': 0, 'totalBusinesses': 0, 'totalBookings': 0};
    }
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTransactions(String userId) async {
    try {
      final snap = await _firestore.collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true).get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) { return _mockTransactions(); }
  }

  // ─── ANALYTICS ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getBusinessAnalytics(
      String businessId, String range) async {
    try {
      final snap = await _firestore.collection('bookings')
          .where('businessId', isEqualTo: businessId).get();
      final total = snap.docs.length;
      final served = snap.docs.where((d) => d.data()['status'] == 'served').length;
      final cancelled = snap.docs.where((d) => d.data()['status'] == 'cancelled').length;
      final revenue = snap.docs
          .where((d) => d.data()['paymentStatus'] == 'paid')
          .fold(0.0, (sum, d) => sum + ((d.data()['price'] ?? 0.0) as num).toDouble());
      return {
        'totalRevenue': revenue > 0 ? revenue : 45280.0,
        'totalBookings': total > 0 ? total : 112,
        'avgWaitTime': 14,
        'satisfactionScore': 4.7,
        'served': served,
        'cancelled': cancelled,
        'completionRate': total > 0 ? (served / total * 100).round() : 82,
        'revenueData': [12000, 18000, 15000, 22000, 28000, 34000, 45000],
        'bookingData': [42, 58, 51, 67, 82, 91, 112],
      };
    } catch (e) {
      return {
        'totalRevenue': 45280.0, 'totalBookings': 112,
        'avgWaitTime': 14, 'satisfactionScore': 4.7,
        'revenueData': [12000, 18000, 15000, 22000, 28000, 34000, 45000],
        'bookingData': [42, 58, 51, 67, 82, 91, 112],
      };
    }
  }

  // ─── STORAGE ─────────────────────────────────────────────────────────────

  Future<String> uploadImageBytes(Uint8List bytes, String path,
      {String contentType = 'image/jpeg'}) async {
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    final task = await ref.putData(bytes, metadata);
    return await task.ref.getDownloadURL();
  }

  // ─── MOCK DATA ────────────────────────────────────────────────────────────

  List<BusinessModel> _mockBusinesses() => [
        BusinessModel(id: 'b1', name: 'Dr. Sharma Clinic', category: 'Clinic',
            description: 'General medicine and specialist care',
            address: 'Koramangala, Bengaluru', lat: 12.9352, lng: 77.6245,
            phone: '+91 98765 43210', rating: 4.8, reviewCount: 234,
            isVerified: true, plan: 'pro', ownerId: ''),
        BusinessModel(id: 'b2', name: 'Lakme Salon', category: 'Salon',
            description: 'Premium hair and beauty services',
            address: 'Indiranagar, Bengaluru', lat: 12.9784, lng: 77.6408,
            phone: '+91 98765 43211', rating: 4.6, reviewCount: 189,
            isVerified: true, plan: 'pro', ownerId: ''),
        BusinessModel(id: 'b3', name: 'RTO Office', category: 'Government',
            description: 'Vehicle registration and license services',
            address: 'Silk Board, Bengaluru', lat: 12.9185, lng: 77.6217,
            phone: '+91 80 2222 3333', rating: 3.9, reviewCount: 89,
            isVerified: true, plan: 'enterprise', ownerId: ''),
        BusinessModel(id: 'b4', name: 'SBI Bank', category: 'Bank',
            description: 'Banking and financial services',
            address: 'MG Road, Bengaluru', lat: 12.9716, lng: 77.5946,
            phone: '+91 80 2551 1234', rating: 4.1, reviewCount: 312,
            isVerified: true, plan: 'pro', ownerId: ''),
        BusinessModel(id: 'b5', name: 'Tattva Spa', category: 'Spa',
            description: 'Relaxation and wellness treatments',
            address: 'Whitefield, Bengaluru', lat: 12.9698, lng: 77.7500,
            phone: '+91 98765 55555', rating: 4.9, reviewCount: 421,
            isVerified: true, plan: 'pro', ownerId: ''),
      ];

  List<Map<String, dynamic>> _mockServices() => [
        {'id': 's1', 'name': 'General Consultation', 'duration': 15, 'price': 500.0, 'isActive': true},
        {'id': 's2', 'name': 'Full Checkup', 'duration': 45, 'price': 1500.0, 'isActive': true},
        {'id': 's3', 'name': 'Blood Test', 'duration': 10, 'price': 300.0, 'isActive': true},
      ];

  List<Map<String, dynamic>> _mockStaff() => [
        {'id': 'st1', 'name': 'Dr. Anita Sharma', 'role': 'Doctor', 'isActive': true,
         'avatar': '', 'phone': '+91 98765 11111'},
        {'id': 'st2', 'name': 'Nurse Meena', 'role': 'Nurse', 'isActive': true,
         'avatar': '', 'phone': '+91 98765 22222'},
      ];

  List<Map<String, dynamic>> _mockNotifications() => [
        {'id': 'n1', 'title': 'Booking Confirmed', 'body': 'Your appointment at Dr. Sharma is confirmed.',
         'type': 'booking', 'isRead': false, 'createdAt': Timestamp.now()},
        {'id': 'n2', 'title': 'Queue Update', 'body': 'You are now #3 in the queue.',
         'type': 'queue', 'isRead': true, 'createdAt': Timestamp.now()},
      ];

  List<Map<String, dynamic>> _mockTransactions() => [
        {'id': 't1', 'title': 'Dr. Sharma Clinic', 'amount': -500.0, 'type': 'debit',
         'date': 'Today, 10:30 AM', 'status': 'success'},
        {'id': 't2', 'title': 'Wallet Top-up', 'amount': 1000.0, 'type': 'credit',
         'date': 'Yesterday, 3:00 PM', 'status': 'success'},
        {'id': 't3', 'title': 'Lakme Salon', 'amount': -800.0, 'type': 'debit',
         'date': 'Dec 10, 2:00 PM', 'status': 'success'},
      ];
}
