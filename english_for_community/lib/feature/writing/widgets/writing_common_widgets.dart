import 'package:flutter/material.dart';

import '../../../core/locale/l10n_context.dart';
import '../../../core/theme/app_color.dart';

// --- Header ---
class WritingHeader extends StatelessWidget {
  const WritingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.writingHeaderEssayTitle,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.writingHeaderEssaySubtitle,
                  style: TextStyle(
                    color: AppColors.onPrimary.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    context.l10n.writingAiFeedbackBadge,
                    style: const TextStyle(color: AppColors.onPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_note_rounded, color: AppColors.onPrimary, size: 32),
          ),
        ],
      ),
    );
  }
}

// --- Search Box ---
class WritingSearchBox extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onTap;

  const WritingSearchBox({super.key, required this.primaryColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        readOnly: true,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: context.l10n.writingSearchTopicsTasksHint,
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          isDense: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// --- Filter Row ---
class WritingFilterRow extends StatelessWidget {
  const WritingFilterRow({
    super.key,
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
    required this.primaryColor,
  });

  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: List.generate(filters.length, (i) {
          final selected = i == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: i == filters.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? primaryColor : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? primaryColor : AppColors.outline,
                  ),
                  boxShadow: selected ? [
                    BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
                  ] : [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.03), blurRadius: 2, offset: const Offset(0, 1))
                  ],
                ),
                child: Text(
                  filters[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? AppColors.onPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// --- Status Views ---
class WritingEmptyView extends StatelessWidget {
  const WritingEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline),
            ),
            child: const Icon(Icons.edit_off_outlined, size: 40, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(context.l10n.writingNoTopicsFound, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class WritingErrorView extends StatelessWidget {
  final String message;
  const WritingErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: AppColors.danger),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
