import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Import các entity và bloc của dự án
import '../../../../../core/entity/reading/reading_entity.dart';
import '../../../../../core/entity/reading/reading_feedback_entity.dart';
import '../../../../../core/entity/reading/translation_entity.dart';
import '../../../../../core/get_it/get_it.dart';
import '../content_widgets.dart'; // Chứa ShadcnCard, ShadcnInput, v.v.
import 'bloc/admin_reading_bloc.dart';
import 'bloc/admin_reading_event.dart';
import 'bloc/admin_reading_state.dart';

class ReadingEditorPage extends StatelessWidget {
  final String? id;
  const ReadingEditorPage({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    // Cung cấp Bloc cho màn hình này
    return BlocProvider.value(
      value: getIt<AdminReadingBloc>(),
      child: _ReadingEditorView(id: id),
    );
  }
}

class _ReadingEditorView extends StatefulWidget {
  final String? id;
  const _ReadingEditorView({this.id});

  @override
  State<_ReadingEditorView> createState() => _ReadingEditorViewState();
}

class _ReadingEditorViewState extends State<_ReadingEditorView> {
  // Biến kiểm tra xem có phải đang chỉnh sửa không (để hiện nút Edit/Save nếu cần)
  bool _isEditingMode = true;

  // --- CONTROLLERS ---
  // Phần thông tin chung
  final _titleCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController();
  String _difficulty = 'medium';

  // Phần nội dung & Dịch
  final _contentCtrl = TextEditingController();
  final _transTitleCtrl = TextEditingController();
  final _transContentCtrl = TextEditingController();

  // Dữ liệu câu hỏi (Lưu dạng List Map để dễ thao tác trên UI)
  List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();

    if (widget.id != null) {
      // 🟢 TRƯỜNG HỢP EDIT: Gọi API lấy chi tiết bài đọc
      context.read<AdminReadingBloc>().add(GetReadingDetailEvent(widget.id!));
      _isEditingMode = false; // Mặc định vào xem trước, bấm Edit mới sửa (tùy logic UX của bạn)
    } else {
      // 🟢 TRƯỜNG HỢP CREATE: Tạo mới
      _isEditingMode = true;
      _addNewQuestion(); // Thêm sẵn 1 câu hỏi rỗng
    }
  }

  @override
  void dispose() {
    // 🟢 DỌN DẸP: Reset state selectedReading để lần sau vào không hiện bài cũ
    getIt<AdminReadingBloc>().add(ClearSelectedReadingEvent());

    // Dispose controllers
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _imageUrlCtrl.dispose();
    _minutesCtrl.dispose();
    _contentCtrl.dispose();
    _transTitleCtrl.dispose();
    _transContentCtrl.dispose();
    super.dispose();
  }

  /// Hàm đổ dữ liệu từ Entity vào UI (Controllers)
  void _populateData(ReadingEntity reading) {
    _titleCtrl.text = reading.title;
    _summaryCtrl.text = reading.summary ?? '';
    _imageUrlCtrl.text = reading.imageUrl ?? '';
    _minutesCtrl.text = reading.minutesToRead.toString();
    _difficulty = reading.difficulty?.name ?? 'medium';

    _contentCtrl.text = reading.content;
    _transTitleCtrl.text = reading.translation?.title ?? '';
    _transContentCtrl.text = reading.translation?.content ?? '';

    // Map danh sách câu hỏi từ Entity sang cấu trúc Map của UI
    setState(() {
      questions = reading.questions.map((q) {
        return {
          "questionText": q.questionText,
          "options": List<String>.from(q.options), // Copy list để tránh tham chiếu
          "correctAnswerIndex": q.correctAnswerIndex,
          "feedback": {
            "reasoning": q.feedback?.reasoning ?? "",
            "paragraphIndex": q.feedback?.paragraphIndex,
            "keySentence": q.feedback?.keySentence ?? ""
          },
          "translation": {
            "questionText": q.translation?.questionText ?? "",
            "options": q.translation?.options != null
                ? List<String>.from(q.translation!.options)
                : ["", "", "", ""]
          }
        };
      }).toList();

      // Nếu vào chế độ xem, cho phép sửa luôn (hoặc bạn có thể set = false tùy ý)
      _isEditingMode = true;
    });
  }

  /// Helper chuyển đổi string sang Enum Difficulty
  ReadingDifficulty _parseDifficulty(String value) {
    switch (value) {
      case 'easy': return ReadingDifficulty.easy;
      case 'hard': return ReadingDifficulty.hard;
      default: return ReadingDifficulty.medium;
    }
  }

  /// Xử lý sự kiện Lưu (Submit)
  void _onSubmit() {
    FocusManager.instance.primaryFocus?.unfocus(); // Ẩn bàn phím

    // Validate cơ bản
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tiêu đề và nội dung chính"), backgroundColor: Colors.orange),
      );
      return;
    }

    // Convert UI Questions -> Entity Questions
    List<ReadingQuestionEntity> questionEntities = [];
    try {
      for (var q in questions) {
        final qText = q['questionText']?.toString().trim() ?? '';
        if (qText.isEmpty) continue; // Bỏ qua câu hỏi rỗng

        final fbMap = q['feedback'] as Map<String, dynamic>? ?? {};
        final transMap = q['translation'] as Map<String, dynamic>? ?? {};

        // Xử lý Options (English)
        List<String> options = [];
        if (q['options'] is List) {
          options = (q['options'] as List).map((e) => e.toString()).toList();
        }
        while (options.length < 4) options.add(""); // Đảm bảo đủ 4 đáp án

        // Xử lý Options (Vietnamese)
        List<String> transOptions = [];
        if (transMap['options'] is List) {
          transOptions = (transMap['options'] as List).map((e) => e.toString()).toList();
        }
        while (transOptions.length < 4) transOptions.add("");

        questionEntities.add(ReadingQuestionEntity(
          id: '', // Backend tự sinh ID
          questionText: qText,
          options: options,
          correctAnswerIndex: (q['correctAnswerIndex'] as int?) ?? 0,
          feedback: ReadingFeedbackEntity(
            reasoning: fbMap['reasoning']?.toString() ?? '',
            paragraphIndex: int.tryParse(fbMap['paragraphIndex']?.toString() ?? ''),
            keySentence: fbMap['keySentence']?.toString(),
          ),
          translation: QuestionTranslationEntity(
            questionText: transMap['questionText']?.toString() ?? '',
            options: transOptions,
          ),
        ));
      }

      // Tạo object ReadingEntity
      final newReading = ReadingEntity(
        id: widget.id ?? '', // Nếu có ID là update, không có là create
        title: _titleCtrl.text,
        summary: _summaryCtrl.text,
        content: _contentCtrl.text,
        imageUrl: _imageUrlCtrl.text.isNotEmpty ? _imageUrlCtrl.text : null,
        difficulty: _parseDifficulty(_difficulty),
        minutesToRead: int.tryParse(_minutesCtrl.text) ?? 5,
        questions: questionEntities,
        translation: TranslationEntity(
          title: _transTitleCtrl.text,
          content: _transContentCtrl.text,
        ),
      );

      // Gửi event lên Bloc
      context.read<AdminReadingBloc>().add(CreateReadingEvent(newReading));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi xử lý dữ liệu: $e"), backgroundColor: Colors.red));
    }
  }

  // Thêm câu hỏi mới vào UI
  void _addNewQuestion() {
    setState(() {
      questions.add({
        "questionText": "",
        "options": ["", "", "", ""],
        "correctAnswerIndex": 0,
        "feedback": {"reasoning": "", "paragraphIndex": "", "keySentence": ""},
        "translation": {"questionText": "", "options": ["", "", "", ""]}
      });
    });
  }

  // Xóa câu hỏi
  void _deleteQuestion(int index) {
    setState(() {
      questions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminReadingBloc, AdminReadingState>(
      listener: (context, state) {
        // 1. Xử lý Lỗi
        if (state.status == AdminReadingStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: ${state.errorMessage}"), backgroundColor: Colors.red),
          );
        }

        // 2. Xử lý khi Load chi tiết thành công
        if (state.selectedReading != null && widget.id != null) {
          // Chỉ populate nếu ID khớp
          if (state.selectedReading!.id == widget.id) {
            _populateData(state.selectedReading!);
            // Clear ngay lập tức để tránh loop
            context.read<AdminReadingBloc>().add(ClearSelectedReadingEvent());
          }
        }

        // 3. Xử lý khi Save thành công (Tạm thời check status success chung)
        // Lưu ý: Logic này nên được cải thiện bằng cách tách state SaveSuccess riêng
        // Hiện tại: Nếu không phải loading, không lỗi, và không có selectedReading (tức là action save) -> Pop
        // (Đây là logic tạm, bạn nên điều chỉnh tùy theo luồng Bloc của bạn)
        if (state.status == AdminReadingStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lưu thành công!"), backgroundColor: Colors.green),
          );
          context.pop(); // Chỉ thoát khi đã lưu xong
        }
      },
      child: Scaffold(
        backgroundColor: kBgPage,
        appBar: AppBar(
          backgroundColor: kWhite,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: kTextMain),
              onPressed: () => context.pop()),
          title: Text(widget.id == null ? 'New Reading' : 'Edit Reading',
              style: const TextStyle(color: kTextMain, fontWeight: FontWeight.w700, fontSize: 16)),
          actions: [
            // Nút Save / Edit
            BlocBuilder<AdminReadingBloc, AdminReadingState>(
              builder: (context, state) {
                if (state.status == AdminReadingStatus.loading) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ));
                }
                return TextButton(
                  onPressed: () {
                    // Logic: Luôn cho save nếu đang edit mode
                    _onSubmit();
                  },
                  child: const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                );
              },
            )
          ],
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: kBorder, height: 1)),
        ),

        // BlocBuilder bọc Body để hiện Loading khi fetch detail
        body: BlocBuilder<AdminReadingBloc, AdminReadingState>(
          builder: (context, state) {
            // Đang loading VÀ form chưa có dữ liệu (lần đầu vào Edit)
            if (state.status == AdminReadingStatus.loading && widget.id != null && questions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- CARD 1: GENERAL INFORMATION ---
                  ShadcnCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: "General Information"),

                        // Image Preview Box
                        if (_imageUrlCtrl.text.isNotEmpty)
                          Container(
                            height: 160,
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kBorder),
                                color: const Color(0xFFF1F5F9),
                                image: DecorationImage(
                                  image: NetworkImage(_imageUrlCtrl.text),
                                  fit: BoxFit.cover,
                                  onError: (_,__) => const SizedBox(), // Tránh crash nếu ảnh lỗi
                                )
                            ),
                          ),

                        ShadcnInput(
                          label: "Image URL",
                          controller: _imageUrlCtrl,
                          isReadOnly: !_isEditingMode,
                          hint: "https://example.com/image.png",
                          onChanged: (val) => setState((){}), // Refresh UI để hiện ảnh
                        ),
                        const SizedBox(height: 16),

                        ShadcnInput(label: "Title (English) *", controller: _titleCtrl, isReadOnly: !_isEditingMode),
                        const SizedBox(height: 16),

                        ShadcnInput(label: "Summary", controller: _summaryCtrl, maxLines: 2, isReadOnly: !_isEditingMode),
                        const SizedBox(height: 16),

                        // Row: Mins + Difficulty
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // 1. Ô Time: Cho chiếm 2 phần (nhỏ hơn)
                            Expanded(
                              flex: 2,
                              child: ShadcnInput(
                                  label: "Time (mins)",
                                  controller: _minutesCtrl,
                                  isReadOnly: !_isEditingMode,
                                  keyboardType: TextInputType.number
                              ),
                            ),
                            const SizedBox(width: 16),

                            // 2. Ô Difficulty: Cho chiếm 3 phần (rộng hơn)
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Difficulty", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextMain)),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 48,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _isEditingMode ? kWhite : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: kBorder),
                                    ),
                                    child: Row(
                                      children: ['easy', 'medium', 'hard'].map((level) {
                                        final isSelected = _difficulty == level;
                                        return Expanded(
                                          child: GestureDetector(
                                            onTap: _isEditingMode ? () => setState(() => _difficulty = level) : null,
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 2), // Tạo khe hở nhỏ giữa các nút
                                              decoration: BoxDecoration(
                                                color: isSelected ? kTextMain : Colors.transparent,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              alignment: Alignment.center,
                                              // 👇 Dùng FittedBox để chữ tự co lại nếu vẫn thiếu chỗ
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  level.toUpperCase(),
                                                  maxLines: 1, // Bắt buộc 1 dòng
                                                  style: TextStyle(
                                                      fontSize: 11, // Tăng nhẹ size chữ cho dễ đọc
                                                      fontWeight: FontWeight.bold,
                                                      color: isSelected ? Colors.white : kTextMuted
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- CARD 2: CONTENT & TRANSLATION ---
                  ShadcnCard(
                    child: Column(
                      children: [
                        const SectionHeader(title: "Content & Translation"),
                        // English Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF), // Blue-50
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("🇬🇧 English Original", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                              const SizedBox(height: 8),
                              ShadcnInput(label: "", controller: _contentCtrl, maxLines: 8, isReadOnly: !_isEditingMode, hint: "Paste English text here..."),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Vietnamese Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED), // Orange-50
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("🇻🇳 Vietnamese Translation", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                              const SizedBox(height: 8),
                              ShadcnInput(label: "Translated Title", controller: _transTitleCtrl, isReadOnly: !_isEditingMode),
                              const SizedBox(height: 8),
                              ShadcnInput(label: "Translated Content", controller: _transContentCtrl, maxLines: 8, isReadOnly: !_isEditingMode),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- CARD 3: QUESTIONS ---
                  ShadcnCard(
                    child: Column(
                      children: [
                        SectionHeader(
                          title: "Quiz Questions (${questions.length})",
                          action: _isEditingMode
                              ? OutlinedButton.icon(
                            onPressed: _addNewQuestion,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Add Question"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kTextMain,
                              side: const BorderSide(color: kBorder),
                            ),
                          )
                              : null,
                        ),
                        const SizedBox(height: 8),

                        // Render Question List
                        if (questions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("Chưa có câu hỏi nào.", style: TextStyle(color: kTextMuted)),
                          )
                        else
                          ...questions.asMap().entries.map((entry) {
                            return _buildQuestionEditor(entry.key, entry.value);
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60), // Bottom padding
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget render từng câu hỏi (Giữ nguyên style Shadcn của bạn)
  Widget _buildQuestionEditor(int index, Map<String, dynamic> q) {
    // Helper lấy data an toàn
    final options = List<String>.from(q['options'] ?? []);
    final transMap = q['translation'] as Map<String, dynamic>? ?? {};
    final transOptions = List<String>.from(transMap['options'] ?? []);
    final feedback = q['feedback'] as Map<String, dynamic>? ?? {};

    // Fill data if empty
    while (options.length < 4) options.add("");
    while (transOptions.length < 4) transOptions.add("");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(8),
        color: kWhite,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: index == 0, // Mở câu đầu tiên theo mặc định
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: const Color(0xFFFAFAFA),
          collapsedBackgroundColor: kWhite,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: kTextMain, borderRadius: BorderRadius.circular(6)),
                child: Text("Q${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  q['questionText']?.toString().isEmpty ?? true ? "(New Question)" : q['questionText'],
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: _isEditingMode
              ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteQuestion(index))
              : null,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: kBorder)),
                color: kWhite,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Text
                  ShadcnInput(
                    label: "Question (English)",
                    controller: TextEditingController(text: q['questionText']),
                    isReadOnly: !_isEditingMode,
                    // Cập nhật trực tiếp vào Map khi gõ (quan trọng)
                    onChanged: (val) => q['questionText'] = val,
                  ),
                  const SizedBox(height: 12),
                  ShadcnInput(
                    label: "Question (Vietnamese)",
                    controller: TextEditingController(text: transMap['questionText']),
                    isReadOnly: !_isEditingMode,
                    onChanged: (val) => transMap['questionText'] = val,
                  ),
                  const SizedBox(height: 20),

                  const Text("Options & Correct Answer", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextMuted)),
                  const SizedBox(height: 8),

                  ...List.generate(4, (optIdx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Transform.scale(
                              scale: 1.1,
                              child: Radio<int>(
                                value: optIdx,
                                groupValue: q['correctAnswerIndex'],
                                activeColor: Colors.green,
                                onChanged: _isEditingMode ? (val) => setState(() => q['correctAnswerIndex'] = val) : null,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                ShadcnInput(
                                  label: "",
                                  hint: "Option ${optIdx + 1} (EN)",
                                  controller: TextEditingController(text: options[optIdx]),
                                  isReadOnly: !_isEditingMode,
                                  onChanged: (val) => (q['options'] as List)[optIdx] = val,
                                ),
                                const SizedBox(height: 6),
                                ShadcnInput(
                                  label: "",
                                  hint: "Option ${optIdx + 1} (VN)",
                                  controller: TextEditingController(text: transOptions[optIdx]),
                                  isReadOnly: !_isEditingMode,
                                  onChanged: (val) => (transMap['options'] as List)[optIdx] = val,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Feedback Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4), // Green-50
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Column(
                      children: [
                        Row(children: [
                          const Icon(Icons.lightbulb, size: 18, color: Color(0xFF15803D)),
                          const SizedBox(width: 8),
                          const Text("Explanation / Feedback", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D)))
                        ]),
                        const SizedBox(height: 12),
                        ShadcnInput(
                          label: "Reasoning",
                          controller: TextEditingController(text: feedback['reasoning']),
                          isReadOnly: !_isEditingMode,
                          maxLines: 2,
                          onChanged: (val) => feedback['reasoning'] = val,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: ShadcnInput(
                                label: "Para Index",
                                hint: "1",
                                controller: TextEditingController(text: feedback['paragraphIndex']?.toString()),
                                isReadOnly: !_isEditingMode,
                                keyboardType: TextInputType.number,
                                onChanged: (val) => feedback['paragraphIndex'] = val,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: ShadcnInput(
                                label: "Key Sentence",
                                controller: TextEditingController(text: feedback['keySentence']),
                                isReadOnly: !_isEditingMode,
                                onChanged: (val) => feedback['keySentence'] = val,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}