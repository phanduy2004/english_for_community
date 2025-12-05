import 'package:flutter/material.dart';
import '../../../../core/entity/report_entity.dart';

class ReportDetailDialog extends StatelessWidget {
  final ReportEntity report;
  const ReportDetailDialog({super.key, required this.report});

  // Hàm mở trình xem ảnh toàn màn hình
  void _openImageViewer(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (ctx) => _FullScreenImageViewer(images: images, initialIndex: initialIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
    const borderCol = Color(0xFFE4E4E7);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 750), // Tăng maxHeight xíu vì layout dài hơn
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text('Report Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textMain)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: textMuted),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
            const Divider(height: 1, color: borderCol),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. SUBJECT ---
                    const _Label('SUBJECT'),
                    Text(report.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain)),
                    const SizedBox(height: 20),

                    // --- 2. DESCRIPTION ---
                    const _Label('DESCRIPTION'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderCol)
                      ),
                      child: Text(report.description, style: const TextStyle(color: textMain, height: 1.5, fontSize: 14)),
                    ),
                    const SizedBox(height: 24),

                    // --- 3. ATTACHMENTS ---
                    if (report.images != null && report.images!.isNotEmpty) ...[
                      const _Label('ATTACHMENTS'),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: report.images!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final imageUrl = report.images![index];
                            return GestureDetector(
                              onTap: () => _openImageViewer(context, report.images!, index),
                              child: Hero(
                                tag: 'report_img_$index',
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderCol),
                                    image: DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- 4. SENDER INFO (Đã chuyển sang Column) ---
                    // Giờ đây email dài bao nhiêu cũng không sợ bị che
                    const _Label('SENDER'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(icon: Icons.person_outline, text: report.user?.fullName ?? 'Unknown'),
                          const SizedBox(height: 8),
                          _InfoRow(icon: Icons.email_outlined, text: report.user?.email ?? 'No email provided'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- 5. DEVICE INFO (Đã chuyển sang Column) ---
                    const _Label('DEVICE INFO'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(icon: Icons.phone_android_outlined, text: report.deviceInfo?.device ?? 'Unknown Device'),
                          const SizedBox(height: 8),
                          _InfoRow(icon: Icons.system_update_alt_outlined, text: '${report.deviceInfo?.platform ?? ""} ${report.deviceInfo?.version ?? ""}'),
                        ],
                      ),
                    ),

                    // Khoảng trống dưới cùng để scroll không bị sát mép
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Widget xem ảnh Fullscreen (Giữ nguyên logic cũ) ---
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({required this.images, required this.initialIndex});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Hero(
                  tag: 'report_img_$index',
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    },
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          top: 40, right: 20,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
              child: Text('${_currentIndex + 1} / ${widget.images.length}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Widgets Label & InfoRow ---
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF64748B)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500))),
    ]);
  }
}