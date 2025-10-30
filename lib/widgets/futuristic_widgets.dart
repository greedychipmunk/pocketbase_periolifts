import 'package:flutter/material.dart';

/// A futuristic card widget with gradient background and enhanced styling
class FuturisticCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool showGradient;

  const FuturisticCard({
    Key? key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.elevation = 8,
    this.borderRadius,
    this.showGradient = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).colorScheme.primary;
    final radius = borderRadius ?? BorderRadius.circular(20);

    return Container(
      margin: margin,
      child: Card(
        elevation: elevation!,
        shadowColor: cardColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: showGradient
                ? LinearGradient(
                    colors: [
                      cardColor.withOpacity(0.1),
                      cardColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Padding(
            padding: padding!,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A futuristic button with gradient styling and enhanced animations
class FuturisticButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? primaryColor;
  final Color? secondaryColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final double? elevation;

  const FuturisticButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.primaryColor,
    this.secondaryColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    this.borderRadius,
    this.elevation = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? Theme.of(context).colorScheme.primary;
    final secondary = secondaryColor ?? Theme.of(context).colorScheme.secondary;
    final radius = borderRadius ?? BorderRadius.circular(16);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: elevation! * 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
}

/// A modern icon container with background
class FuturisticIconContainer extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final double containerSize;
  final BorderRadius? borderRadius;

  const FuturisticIconContainer({
    Key? key,
    required this.icon,
    this.color,
    this.size = 24,
    this.containerSize = 48,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.primary;
    final radius = borderRadius ?? BorderRadius.circular(12);

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        borderRadius: radius,
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: size,
      ),
    );
  }
}

/// A futuristic progress indicator with glow effect
class FuturisticProgressIndicator extends StatelessWidget {
  final double value;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;

  const FuturisticProgressIndicator({
    Key? key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? Theme.of(context).colorScheme.primary;
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: progressColor.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        ),
      ),
    );
  }
}