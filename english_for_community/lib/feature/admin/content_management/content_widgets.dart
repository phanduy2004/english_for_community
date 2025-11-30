import 'package:flutter/material.dart';

// Colors Palette (Shadcn / Slate Theme)
const kBgPage = Color(0xFFF8FAFC); // Slate-50
const kWhite = Colors.white;
const kTextMain = Color(0xFF0F172A); // Slate-900
const kTextMuted = Color(0xFF64748B); // Slate-500
const kBorder = Color(0xFFE2E8F0); // Slate-200
const kPrimary = Color(0xFF0F172A); // Slate-900 (Primary Action)

// 1. Basic Card (Container trắng, bo góc, có bóng nhẹ)
class ShadcnCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const ShadcnCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
              color: kTextMain.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

// 2. Standard Input (Đã nâng cấp thêm onChanged)
class ShadcnInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final int maxLines;
  final bool isReadOnly;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;

  const ShadcnInput({
    super.key,
    required this.label,
    this.hint = '',
    this.controller,
    this.maxLines = 1,
    this.isReadOnly = false,
    this.suffixIcon,
    this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: kTextMain)),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: isReadOnly ? const Color(0xFFF1F5F9) : kWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: maxLines,
            readOnly: isReadOnly,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, color: kTextMain),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: kTextMuted.withOpacity(0.6)),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}

// 3. Section Header (ĐÃ SỬA LỖI OVERFLOW Ở ĐÂY)
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 👇 Thay Text thường bằng Expanded để tránh tràn lề
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: kTextMain),
              overflow: TextOverflow.ellipsis, // Thêm dấu ... nếu quá dài
              maxLines: 1,
            ),
          ),
          // 👇 Thêm khoảng cách an toàn nếu có nút Action
          if (action != null) ...[
            const SizedBox(width: 8),
            action!,
          ]
        ],
      ),
    );
  }
}

// 4. Status Badge
class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({super.key, required this.text, required this.color});

  factory StatusBadge.active({required bool isActive}) {
    return StatusBadge(
      text: isActive ? 'Published' : 'Draft',
      color: isActive ? const Color(0xFF166534) : kTextMuted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}