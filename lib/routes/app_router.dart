import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/phone_login_screen.dart';
import '../features/auth/screens/register_customer_screen.dart';
import '../features/auth/screens/register_business_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/customer/screens/home_screen.dart';
import '../features/customer/screens/search_filter_screen.dart';
import '../features/customer/screens/map_view_screen.dart';
import '../features/customer/screens/business_profile_screen.dart';
import '../features/customer/screens/service_selection_screen.dart';
import '../features/customer/screens/datetime_picker_screen.dart';
import '../features/customer/screens/booking_confirmation_screen.dart';
import '../features/customer/screens/active_queue_screen.dart';
import '../features/customer/screens/my_appointments_screen.dart';
import '../features/customer/screens/appointment_detail_screen.dart';
import '../features/customer/screens/notifications_screen.dart';
import '../features/customer/screens/customer_profile_screen.dart';
import '../features/customer/screens/reviews_ratings_screen.dart';
import '../features/customer/screens/wallet_payment_screen.dart';
import '../features/customer/screens/help_faq_screen.dart';
import '../features/business/screens/business_registration_screen.dart';
import '../features/business/screens/business_dashboard_screen.dart';
import '../features/business/screens/live_queue_manager_screen.dart';
import '../features/business/screens/appointment_list_screen.dart';
import '../features/business/screens/appointment_detail_business_screen.dart';
import '../features/business/screens/staff_management_screen.dart';
import '../features/business/screens/service_pricing_screen.dart';
import '../features/business/screens/business_analytics_screen.dart';
import '../features/business/screens/business_settings_screen.dart';
import '../features/business/screens/notification_settings_screen.dart';
import '../features/business/screens/subscription_plan_screen.dart';
import '../features/business/screens/business_profile_edit_screen.dart';
import '../features/business/screens/review_management_screen.dart';
import '../features/ai/screens/ai_chatbot_screen.dart';
import '../features/ai/screens/wait_time_predictor_screen.dart';
import '../features/ai/screens/smart_slot_recommendation_screen.dart';
import '../features/ai/screens/voice_booking_screen.dart';
import '../features/admin/screens/admin_super_panel_screen.dart';
import '../features/admin/screens/reports_export_screen.dart';
import '../features/customer/screens/razorpay_payment_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final bool isLoggedIn = user != null;
      
      final isSplash = state.matchedLocation == '/';
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/role-selection' ||
          state.matchedLocation == '/otp' ||
          state.matchedLocation == '/phone-login' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/reset-password';

      // If we are on Splash, let the Splash screen handle the initial navigation logic
      if (isSplash) return null;

      // If not logged in and trying to access a protected route, go to role-selection
      if (!isLoggedIn && !isAuthRoute) return '/role-selection';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (ctx, state) => _slide(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (ctx, state) => _slide(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/role-selection',
        pageBuilder: (ctx, state) => _slide(state, const RoleSelectionScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, state) {
          final role = state.uri.queryParameters['role'];
          return _slide(state, LoginScreen(initialRole: role));
        },
      ),
      GoRoute(
        path: '/phone-login',
        pageBuilder: (ctx, state) => _slide(state, const PhoneLoginScreen()),
      ),
      GoRoute(
        path: '/register',
        redirect: (context, state) {
          final role = state.uri.queryParameters['role'];
          if (role == 'business') return '/register/business';
          return '/register/customer';
        },
      ),
      GoRoute(
        path: '/register/customer',
        pageBuilder: (ctx, state) => _slide(state, const RegisterCustomerScreen()),
      ),
      GoRoute(
        path: '/register/business',
        pageBuilder: (ctx, state) => _slide(state, const RegisterBusinessScreen()),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _slide(
            state,
            OTPVerificationScreen(
              verificationId: extra?['verificationId'] ?? '',
              phone: extra?['phone'] ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (ctx, state) => _slide(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (ctx, state) => _slide(state, const ResetPasswordScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (ctx, state) => _slide(state, const CustomerHomeScreen()),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (ctx, state) => _slide(state, const SearchFilterScreen()),
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (ctx, state) => _slide(state, const MapViewScreen()),
      ),
      GoRoute(
        path: '/business/:id',
        pageBuilder: (ctx, state) => _slide(
          state,
          BusinessProfileScreen(businessId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/service-selection',
        pageBuilder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _slide(
            state,
            ServiceSelectionScreen(
              businessId: extra['businessId'] ?? '',
              businessName: extra['businessName'] ?? 'Business',
            ),
          );
        },
      ),
      GoRoute(
        path: '/datetime-picker',
        pageBuilder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _slide(state, DateTimePickerScreen(bookingData: extra));
        },
      ),
      GoRoute(
        path: '/booking-confirmation',
        pageBuilder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _slide(state, BookingConfirmationScreen(bookingData: extra));
        },
      ),
      GoRoute(
        path: '/queue',
        pageBuilder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _slide(
            state,
            ActiveQueueScreen(
              businessId: extra['businessId'] ?? '',
              businessName: extra['businessName'] ?? 'Business',
              tokenNumber: extra['tokenNumber'] ?? '-',
              serviceName: extra['serviceName'] ?? '',
              bookingId: extra['bookingId'] ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: '/chatbot',
        pageBuilder: (ctx, state) => _slide(state, const AIChatbotScreen()),
      ),
      GoRoute(
        path: '/appointments',
        pageBuilder: (ctx, state) => _slide(state, const MyAppointmentsScreen()),
      ),
      GoRoute(
        path: '/appointment/:id',
        pageBuilder: (ctx, state) => _slide(
          state,
          AppointmentDetailScreen(bookingId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (ctx, state) => _slide(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (ctx, state) => _slide(state, const CustomerProfileScreen()),
      ),
      GoRoute(
        path: '/reviews',
        pageBuilder: (ctx, state) => _slide(state, const ReviewsRatingsScreen()),
      ),
      GoRoute(
        path: '/wallet',
        pageBuilder: (ctx, state) => _slide(state, const WalletPaymentScreen()),
      ),
      GoRoute(
        path: '/payment',
        pageBuilder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _slide(
            state,
            RazorpayPaymentScreen(
              amount: (extra['amount'] as num?)?.toDouble() ?? 0.0,
              description: extra['description'] as String? ?? 'Service payment',
              businessName: extra['businessName'] as String? ?? 'Business',
              bookingId: extra['bookingId'] as String?,
            ),
          );
        },
      ),
      GoRoute(
        path: '/help',
        pageBuilder: (ctx, state) => _slide(state, const HelpFAQScreen()),
      ),
      GoRoute(
        path: '/business-register',
        pageBuilder: (ctx, state) => _slide(state, const BusinessRegistrationScreen()),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (ctx, state) => _slide(state, const BusinessDashboardScreen()),
      ),
      GoRoute(
        path: '/queue-manager',
        pageBuilder: (ctx, state) => _slide(state, const LiveQueueManagerScreen()),
      ),
      GoRoute(
        path: '/appointment-list',
        pageBuilder: (ctx, state) => _slide(state, const AppointmentListScreen()),
      ),
      GoRoute(
        path: '/appointment-business/:id',
        pageBuilder: (ctx, state) => _slide(
          state,
          AppointmentDetailBusinessScreen(bookingId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/staff',
        pageBuilder: (ctx, state) => _slide(state, const StaffManagementScreen()),
      ),
      GoRoute(
        path: '/services',
        pageBuilder: (ctx, state) => _slide(state, const ServicePricingScreen()),
      ),
      GoRoute(
        path: '/analytics',
        pageBuilder: (ctx, state) => _slide(state, const BusinessAnalyticsScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (ctx, state) => _slide(state, const BusinessSettingsScreen()),
      ),
      GoRoute(
        path: '/notification-settings',
        pageBuilder: (ctx, state) => _slide(state, const NotificationSettingsScreen()),
      ),
      GoRoute(
        path: '/subscription',
        pageBuilder: (ctx, state) => _slide(state, const SubscriptionPlanScreen()),
      ),
      GoRoute(
        path: '/profile-edit',
        pageBuilder: (ctx, state) => _slide(state, const BusinessProfileEditScreen()),
      ),
      GoRoute(
        path: '/reviews-manage',
        pageBuilder: (ctx, state) => _slide(state, const ReviewManagementScreen()),
      ),
      GoRoute(
        path: '/wait-predictor',
        pageBuilder: (ctx, state) => _slide(state, const WaitTimePredictorScreen()),
      ),
      GoRoute(
        path: '/smart-slots',
        pageBuilder: (ctx, state) => _slide(state, const SmartSlotRecommendationScreen()),
      ),
      GoRoute(
        path: '/voice-booking',
        pageBuilder: (ctx, state) => _slide(state, const VoiceBookingScreen()),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (ctx, state) => _slide(state, const AdminSuperPanelScreen()),
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (ctx, state) => _slide(state, const ReportsExportScreen()),
      ),
    ],
  );

  static CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
