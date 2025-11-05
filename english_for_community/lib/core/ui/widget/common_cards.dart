// lib/core/widgets/common_cards.dart
import 'package:flutter/material.dart';

/// Card chung với gradient header
class GradientHeaderCard extends StatelessWidget {
  const GradientHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.height = 200,
    this.icon,
    this.trailing,
    this.gradientColors,
  });

  final String title;
  final String subtitle;
  final double height;
  final Widget? icon;
  final Widget? trailing;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;
    final colors = gradientColors ?? [cs.primary, cs.secondary];

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: const Alignment(1, -1),
          end: const Alignment(-1, 1),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: txt.headlineSmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: txt.bodyMedium?.copyWith(color: cs.onPrimary),
                      ),
                    ],
                  ),
                ),
                if (icon != null) icon!,
              ],
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Section card với title và optional description
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.trailing,
    this.description,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final Widget? trailing;
  final String? description;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: txt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: txt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Info card với icon, title, và description
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.tags,
    this.leadingIcon = Icons.library_books_rounded,
    this.onTap,
  });

  final String title;
  final List<String> tags;
  final IconData leadingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(leadingIcon, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags
                          .map((t) => TagChip(
                        text: t,
                        background: cs.primary.withOpacity(.12),
                        foreground: cs.primary,
                      ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right_rounded, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tag chip nhỏ
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}