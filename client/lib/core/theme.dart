import 'package:flutter/material.dart';

/// Единая палитра и скругления, чтобы экраны выглядели одинаково.
const Color kSeed = Color(0xFF6C4DF6);
const Color kBackground = Color(0xFFF6F4FF);
const Color kSurface = Colors.white;
const Color kMuted = Color(0xFF7B7592);
const Color kBorder = Color(0xFFE7E2F7);
const double kRadius = 22;

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kSeed).copyWith(primary: kSeed);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBackground,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kSeed,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kSeed.withValues(alpha: 0.4),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: scheme.primary),
  );
}

/// Карточка с мягкой тенью — используется на всех экранах.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
