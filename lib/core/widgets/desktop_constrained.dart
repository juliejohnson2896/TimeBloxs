import 'package:flutter/material.dart';
import '../router/app_router.dart';

class DesktopConstrained extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const DesktopConstrained({
    super.key,
    required this.child,
    this.maxWidth = 900,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}