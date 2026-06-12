import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation helper that safely handles back navigation
extension NavHelper on BuildContext {
  /// Pops if possible, otherwise navigates to fallback route
  void safePop({String fallback = '/home'}) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }

  /// Standard back button widget for AppBar
  static Widget backButton(BuildContext context, {String fallback = '/home', Color color = const Color(0xFF1A1830)}) {
    return IconButton(
      key: const Key('back_button'),
      icon: Icon(Icons.arrow_back_ios_new_rounded, color: color, size: 20),
      onPressed: () => context.safePop(fallback: fallback),
    );
  }
}

/// Standard AppBar back button widget
class AppBackButton extends StatelessWidget {
  final String fallback;
  final Color? color;
  const AppBackButton({super.key, this.fallback = '/home', this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('back_button'),
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: color ?? Theme.of(context).appBarTheme.iconTheme?.color ?? const Color(0xFF1A1830),
        size: 20,
      ),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallback);
        }
      },
    );
  }
}
