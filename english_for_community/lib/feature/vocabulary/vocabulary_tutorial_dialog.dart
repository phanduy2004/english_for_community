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
      "desc": "Xây dựng vốn từ vựng vững chắc với phương pháp Lặp lại ngắt quãng (Spaced Repetition).",
      "icon": Icons.auto_stories,
      "color": Colors.blue
    },
    {
      "title": "Tra cứu & Lưu trữ",
      "desc": "Tra từ nhanh chóng. Nhấn biểu tượng 'Bookmark' 🔖 để lưu từ, hoặc 'Mũ cử nhân' 🎓 để bắt đầu học ngay.",
      "icon": Icons.search,
      "color": Colors.orange
    },
    {
      "title": "Lộ trình học thông minh",
      "desc": "Các từ đang học (Learning) sẽ được tự động tính toán thời gian ôn tập dựa trên thuật toán Ebbinghaus.",
      "icon": Icons.school,
      "color": Colors.green
    },
    {
      "title": "Ôn tập mỗi ngày",
      "desc": "Khi đến hạn, hãy nhấn 'Review Now'. Đánh giá mức độ nhớ (Hard/Good/Easy) để hệ thống sắp xếp lịch học tối ưu nhất.",
      "icon": Icons.history_edu,
      "color": Colors.purple
    },
  ];

  void _nextPage() {
    if (_currentIndex < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent, // Loại bỏ tint mặc định của M3
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE4E4E7), width: 1), // Viền Shadcn
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 420),
        child: Column(
          children: [
            // 1. PAGE VIEW CONTENT
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: (step['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            step['icon'],
                            size: 48,
                            color: step['color'],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          step['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textMain,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step['desc'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: textMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 2. INDICATOR & BUTTONS
            Container(
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
                        height: 8,
                        width: _currentIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? textMain // Active dot màu đen/đậm
                              : const Color(0xFFE4E4E7), // Inactive dot màu xám nhạt
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next Button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textMain, // Nền đen theo style Shadcn
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _currentIndex == _steps.length - 1 ? "Get Started" : "Next",
                      style: const TextStyle(fontWeight: FontWeight.w600),
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