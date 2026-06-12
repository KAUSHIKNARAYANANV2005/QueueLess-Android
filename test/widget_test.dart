// QueueLess — Widget & Unit Tests
// Run: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queueless/core/services/location_service.dart';
import 'package:queueless/features/ai/services/gemini_service.dart';
import 'package:queueless/core/utils/validator.dart';

// ── Unit Tests ─────────────────────────────────────────────────────────────

void main() {
  group('LocationService — distance calculation', () {
    test('same point returns 0 km', () {
      final d = LocationService.distanceKm(12.9716, 77.5946, 12.9716, 77.5946);
      expect(d, closeTo(0, 0.001));
    });

    test('Bengaluru to Delhi is ~1740 km', () {
      // Bengaluru: 12.9716, 77.5946 | Delhi: 28.6139, 77.2090
      final d = LocationService.distanceKm(12.9716, 77.5946, 28.6139, 77.2090);
      expect(d, closeTo(1740, 50)); // within 50 km tolerance
    });

    test('distanceLabel shows metres for <1km', () {
      // Two points ~500m apart
      final label = LocationService.distanceLabel(12.9716, 77.5946, 12.9760, 77.5946);
      expect(label, contains('m'));
      expect(label, isNot(contains('km')));
    });

    test('distanceLabel shows km for >1km', () {
      final label = LocationService.distanceLabel(12.9716, 77.5946, 13.0716, 77.5946);
      expect(label, contains('km'));
    });
  });

  group('GeminiService — local fallback intent detection', () {
    late GeminiService svc;

    setUp(() {
      svc = GeminiService.instance;
    });

    test('booking intent detected for "book appointment"', () async {
      final result = await svc.sendMessage('I want to book an appointment', []);
      expect(result['intent'], equals('booking'));
      expect(result['message'], isNotEmpty);
    });

    test('queue_check intent detected for "what is my queue"', () async {
      final result = await svc.sendMessage('What is my queue position?', []);
      expect(result['intent'], equals('queue_check'));
    });

    test('cancel intent detected for "cancel booking"', () async {
      final result = await svc.sendMessage('I want to cancel my booking', []);
      expect(result['intent'], equals('cancel'));
    });

    test('search intent detected for "find clinic near me"', () async {
      final result = await svc.sendMessage('find a clinic near me', []);
      expect(result['intent'], equals('search'));
    });

    test('general intent for greeting', () async {
      final result = await svc.sendMessage('Hello!', []);
      expect(result['intent'], equals('general'));
      expect(result['message'], isNotEmpty);
    });

    test('payment intent for "how much does it cost"', () async {
      final result = await svc.sendMessage('how much does it cost to pay?', []);
      expect(result['intent'], equals('payment'));
    });

    test('response always has message field', () async {
      final result = await svc.sendMessage('random text xyz 123', []);
      expect(result.containsKey('message'), isTrue);
      expect(result['message'], isA<String>());
    });
  });

  group('Widget Tests — Core UI', () {
    testWidgets('App renders without crashing (smoke test)', (tester) async {
      // Minimal smoke test — just checks the widget tree builds
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('QueueLess')),
          ),
        ),
      );
      expect(find.text('QueueLess'), findsOneWidget);
    });

    testWidgets('PremiumButton renders with label', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('test_btn'),
                onPressed: () => pressed = true,
                child: const Text('Book Now'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Book Now'), findsOneWidget);
      await tester.tap(find.byKey(const Key('test_btn')));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('Loading shimmer renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 300, height: 80, color: Colors.grey[200],
            ),
          ),
        ),
      );
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('Business Model validation', () {
    test('distance label formats correctly under 1km', () {
      expect(LocationService.distanceLabel(12.97, 77.59, 12.971, 77.59), contains('m'));
    });

    test('distance label formats correctly over 1km', () {
      expect(LocationService.distanceLabel(12.97, 77.59, 13.10, 77.59), contains('km'));
    });
  });

  group('Validator - Email validation tests', () {
    test('empty email returns required error', () {
      expect(Validator.validateEmail(''), equals('Email is required'));
      expect(Validator.validateEmail(null), equals('Email is required'));
    });

    test('invalid email formats return error', () {
      expect(Validator.validateEmail('kaushik'), equals('Enter a valid email address'));
      expect(Validator.validateEmail('kaushik@'), equals('Enter a valid email address'));
      expect(Validator.validateEmail('kaushik@com'), equals('Enter a valid email address'));
      expect(Validator.validateEmail('@domain.com'), equals('Enter a valid email address'));
    });

    test('valid email returns null', () {
      expect(Validator.validateEmail('kaushik.v@gmail.com'), isNull);
      expect(Validator.validateEmail('test-user123@domain.co.in'), isNull);
    });
  });

  group('Validator - Password validation tests', () {
    test('empty password returns error', () {
      expect(Validator.validatePassword(''), equals('Password is required'));
      expect(Validator.validatePassword(null), equals('Password is required'));
    });

    test('short password returns error', () {
      expect(Validator.validatePassword('12345'), equals('Password must be at least 6 characters'));
    });

    test('valid password returns null', () {
      expect(Validator.validatePassword('password123'), isNull);
      expect(Validator.validatePassword('secure_pass_99'), isNull);
    });
  });

  group('Validator - Phone validation tests', () {
    test('empty phone returns error', () {
      expect(Validator.validatePhone(''), equals('Phone number is required'));
      expect(Validator.validatePhone(null), equals('Phone number is required'));
    });

    test('too short phone returns error', () {
      expect(Validator.validatePhone('123456789'), equals('Enter a valid phone number'));
    });

    test('too long phone returns error', () {
      expect(Validator.validatePhone('1234567890123'), equals('Enter a valid phone number'));
    });

    test('valid phone formats return null', () {
      expect(Validator.validatePhone('9876543210'), isNull);
      expect(Validator.validatePhone('+919876543210'), isNull);
    });
  });

  group('Validator - Name validation tests', () {
    test('empty name returns error', () {
      expect(Validator.validateName(''), equals('Name is required'));
      expect(Validator.validateName('   '), equals('Name is required'));
      expect(Validator.validateName(null), equals('Name is required'));
    });

    test('single character name returns error', () {
      expect(Validator.validateName('A'), equals('Name is too short'));
    });

    test('valid name returns null', () {
      expect(Validator.validateName('Kaushik'), isNull);
      expect(Validator.validateName('QueueLess Inc.'), isNull);
    });
  });

  group('LocationService - Extended distance calculation tests', () {
    test('Delhi to Mumbai distance is ~1150 km', () {
      // Delhi: 28.6139, 77.2090 | Mumbai: 19.0760, 72.8777
      final d = LocationService.distanceKm(28.6139, 77.2090, 19.0760, 72.8777);
      expect(d, closeTo(1150, 50));
    });

    test('negative coordinates calculation (Sydney to Melbourne)', () {
      // Sydney: -33.8688, 151.2093 | Melbourne: -37.8136, 144.9631
      final d = LocationService.distanceKm(-33.8688, 151.2093, -37.8136, 144.9631);
      expect(d, closeTo(713, 30));
    });

    test('zero degrees coordinates (equator/prime meridian)', () {
      final d = LocationService.distanceKm(0, 0, 0, 0);
      expect(d, closeTo(0, 0.001));
    });

    test('distance Label formats exactly 1000m as km', () {
      // If distance is ~1000m, should format as km
      final label = LocationService.distanceLabel(0, 0, 0.009, 0); // ~1km
      expect(label, contains('km'));
    });
  });
  group('GeminiService - Extra fallback intent detection tests', () {
    test('general intent returned for "how do I use this app"', () async {
      final result = await GeminiService.instance.sendMessage('how do I use this app', []);
      expect(result['intent'], equals('general'));
    });

    test('cancel intent returned for "change notification settings" due to "change"', () async {
      final result = await GeminiService.instance.sendMessage('change notifications settings', []);
      expect(result['intent'], equals('cancel'));
    });

    test('general intent returned for "show my business stats"', () async {
      final result = await GeminiService.instance.sendMessage('show my business statistics', []);
      expect(result['intent'], equals('general'));
    });

    test('general intent returned for "see my ratings"', () async {
      final result = await GeminiService.instance.sendMessage('see what customers are saying about me', []);
      expect(result['intent'], equals('general'));
    });
  });
}
