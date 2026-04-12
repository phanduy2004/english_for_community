import 'package:flutter/material.dart';
import 'data_mock/task_type_instructions.dart';
import '../../core/locale/l10n_context.dart';

class WritingTaskInstructionDialog extends StatelessWidget {
  final String taskType;

  const WritingTaskInstructionDialog({super.key, required this.taskType});

  // Màu sắc Shadcn
  static const Color zinc900 = Color(0xFF09090B);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc200 = Color(0xFFE4E4E7);
  static const Color zinc100 = Color(0xFFF4F4F5);

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    // Lấy thông tin hướng dẫn dựa trên taskType. Nếu không tìm thấy thì dùng mặc định.
    final instruction = taskInstructions[taskType] ??
        taskInstructions['Opinion']!; // Fallback về Opinion nếu lỗi

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white, // Loại bỏ tint mặc định của Material 3
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20), // Padding bên ngoài dialog
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85, // Giới hạn chiều cao
          maxWidth: 500, // Giới hạn chiều rộng trên màn hình lớn
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Dialog tự co lại theo nội dung
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: zinc100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // Thay bằng IconData hoặc SvgPicture nếu dùng asset
                    child: Icon(Icons.lightbulb_outline, color: zinc900, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.writingInstructionHowTo(instruction.title),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: zinc900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.writingInstructionSubtitle,
                          style: const TextStyle(color: zinc500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: zinc500),
                    tooltip: t.commonClose,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: zinc200),

            // --- BODY (Cuộn được) ---
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Description
                    _buildSectionTitle(t.writingInstructionWhatIsIt),
                    Text(
                      instruction.description,
                      style: const TextStyle(fontSize: 15, color: zinc900, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // 2. Structure
                    _buildSectionTitle(t.writingInstructionSuggestedStructure),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: zinc100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: zinc200),
                      ),
                      child: Text(
                        instruction.structure.trim(), // Loại bỏ khoảng trắng thừa
                        style: const TextStyle(fontSize: 14, color: zinc900, height: 1.6, fontFamily: 'monospace'), // Dùng font monospace cho cấu trúc nhìn rõ ràng hơn
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Key Tips
                    _buildSectionTitle(t.writingInstructionKeyTipsSection),
                    ...instruction.keyTips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(fontSize: 14, color: zinc900, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ),

            // --- FOOTER (Optional) ---
            const Divider(height: 1, color: zinc200),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: zinc900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    elevation: 0,
                  ),
                  child: Text(t.writingInstructionGotIt),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: zinc500,
          letterSpacing: 1,
        ),
      ),
    );
  }
}