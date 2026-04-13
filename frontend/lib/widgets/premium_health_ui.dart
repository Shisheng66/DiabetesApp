import 'dart:ui';

import 'package:flutter/material.dart';

class HealthPageBackground extends StatelessWidget {
  const HealthPageBackground({
    super.key,
    required this.child,
    this.topTint = const Color(0xFFD7F0EC),
    this.bottomTint = const Color(0xFFF4F8F7),
    this.accent = const Color(0xFFFFE9D8),
  });

  final Widget child;
  final Color topTint;
  final Color bottomTint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topTint, bottomTint, accent],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -50,
            child: _GlowOrb(
              size: 220,
              color: Colors.white.withValues(alpha: 0.34),
            ),
          ),
          Positioned(
            top: 160,
            left: -70,
            child: _GlowOrb(
              size: 180,
              color: const Color(0xFFBFE7E0).withValues(alpha: 0.46),
            ),
          ),
          Positioned(
            bottom: -40,
            right: 10,
            child: _GlowOrb(
              size: 180,
              color: const Color(0xFFFFE1CC).withValues(alpha: 0.42),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class FrostPanel extends StatelessWidget {
  const FrostPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final base = tint ?? Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base.withValues(alpha: 0.72),
                base.withValues(alpha: 0.44),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class HeroMetric extends StatelessWidget {
  const HeroMetric({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
    this.labelColor = Colors.white70,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF163836),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xFF5A7673),
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class SoftStatPill extends StatelessWidget {
  const SoftStatPill({
    super.key,
    required this.text,
    this.bg = const Color(0xFFEAF5F2),
    this.fg = const Color(0xFF1F5E59),
  });

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class SurfaceButton extends StatelessWidget {
  const SurfaceButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.78),
              Colors.white.withValues(alpha: 0.54),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0B8A7D)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E4744),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassActionButton extends StatelessWidget {
  const GlassActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: enabled
                      ? [
                          Colors.white.withValues(alpha: 0.30),
                          Colors.white.withValues(alpha: 0.10),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.16),
                          Colors.white.withValues(alpha: 0.06),
                        ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: enabled ? 0.24 : 0.12),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0x11000000,
                    ).withValues(alpha: enabled ? 0.10 : 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: enabled
                        ? const Color(0xFF0B8A7D)
                        : const Color(0xFF7E9693),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: enabled
                          ? const Color(0xFF173836)
                          : const Color(0xFF7E9693),
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
