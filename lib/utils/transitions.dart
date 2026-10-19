import 'package:flutter/material.dart';

/// Sayfalar arası geçiş animasyonları.
///
/// Ani geçişler yerine yumuşak geçişler kullanılır; çocuk hangi ekrana
/// geçtiğini takip edebilir.

/// Yeni sayfa hafifçe büyüyerek ve belirerek açılır (ana menüden açılan ekranlar).
Route<T> fadeScaleRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Yeni sayfa aşağıdan yukarı kayarak açılır (alışveriş adımları, ebeveyn paneli).
Route<T> slideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

/// Ana sayfaya kadar bütün ekranları kapatır.
void goHome(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}
