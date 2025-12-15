import 'package:flutter/material.dart';

class VocabularyTutorialDialog extends StatefulWidget {
  const VocabularyTutorialDialog({super.key});

  @override
  State<VocabularyTutorialDialog> createState() => _VocabularyTutorialDialogState();
}

class _VocabularyTutorialDialogState extends State<VocabularyTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Dữ liệu cho các slide hướng dẫn
  final List<Map<String, dynamic>> _steps = [
    {
      "title": "Welcome to Vocabulary",
      "desc": [
        const TextSpan(text: "Xây dựng vốn từ vựng vững chắc với phương pháp "),
        const TextSpan(text: "Lặp lại ngắt quãng", style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: " (Spaced Repetition)."),
      ],
      "icon": Icons.auto_stories_rounded,
      "color": const Color(0xFF3B82F6) // Blue 500
    },
    {
      "title": "Tra cứu & Lưu trữ",
      "desc": [
        const TextSpan(text: "Tra từ nhanh chóng. Nhấn "),
        WidgetSpan(child: Icon(Icons.bookmark, size: 16, color: Colors.amber[700])),
        TextSpan(text: " Save", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[700])),
        const TextSpan(text: " để lưu lại, hoặc nhấn "),
        const WidgetSpan(child: Icon(Icons.school, size: 16, color: Color(0xFF10B981))),
        const TextSpan(text: " Learn", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
        const TextSpan(text: " để học ngay."),
      ],
      "icon": Icons.search_rounded,
      "color": const Color(0xFFF59E0B) // Amber 500
    },
    {
      "title": "Thuật toán thông minh",
      "desc": [
        const TextSpan(text: "Dựa trên lịch sử học của bạn, "),
        const TextSpan(text: "Hệ thống Server", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
        const TextSpan(text: " sẽ tự động tính toán "),
        const TextSpan(text: "điểm rơi trí nhớ", style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: " để nhắc nhở ngay trước khi bạn sắp quên từ đó."),
      ],
      "icon": Icons.psychology_rounded, // Đổi icon thành bộ não/xử lý
      "color": const Color(0xFF10B981) // Emerald 500
    },
    {
      "title": "Ôn tập mỗi ngày",
      "desc": [
        const TextSpan(text: "Khi đến hạn, nhấn "),
        const TextSpan(text: "Review Now", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
        const TextSpan(text: ". Đánh giá mức độ nhớ (Hard/Good/Easy) để tối ưu lịch học."),
      ],
      "icon": Icons.history_edu_rounded,
      "color": const Color(0xFFA855F7) // Purple 500
    },
  ];

  void _nextPage() {
    if (_currentIndex < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);

    // Lấy màu hiện tại
    final currentColor = _steps[_currentIndex]['color'] as Color;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 480),
        child: Column(
          children: [
            // 1. HEADER (ANIMATED BACKGROUND + ICON)
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Gradient Animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          currentColor.withOpacity(0.15),
                          currentColor.withOpacity(0.02),
                        ],
                      ),
                    ),
                  ),

                  // Floating Icon
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Container(
                      key: ValueKey<int>(_currentIndex), // Key để trigger animation
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _steps[_currentIndex]['icon'],
                        size: 64,
                        color: currentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. TEXT CONTENT
            Expanded(
              flex: 4,
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          step['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textMain,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 15,
                              color: textMuted,
                              height: 1.6,
                              fontFamily: 'Inter', // Hoặc font mặc định của bạn
                            ),
                            children: step['desc'],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. FOOTER (DOTS + BUTTON)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots Indicator
                  Row(
                    children: List.generate(_steps.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: _currentIndex == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? currentColor // Dot active theo màu chủ đạo
                              : const Color(0xFFE4E4E7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  // Next Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textMain,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Bo tròn nhiều hơn
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _currentIndex == _steps.length - 1 ? "Let's go" : "Next",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (_currentIndex != _steps.length - 1) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}