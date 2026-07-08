import 'package:flutter/foundation.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import '../../../../../core/get_it/get_it.dart';
import '../../../../core/entity/listening_comp_entity.dart';
import '../content_widgets.dart';

import 'bloc/admin_listening_comp_bloc.dart';
import 'bloc/admin_listening_comp_event.dart';
import 'bloc/admin_listening_comp_state.dart';

class ListeningCompEditorPage extends StatelessWidget {
  final String? id; // 🔥 Biến quyết định đây là Tạo mới hay Chỉnh sửa

  const ListeningCompEditorPage({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    // create → provider tự close bloc factory khi rời editor (hết leak); instance mới
    // mỗi lần mở nên không cần ClearSelected ở dispose.
    return BlocProvider(
      create: (_) => getIt<AdminListeningCompBloc>(),
      child: _ListeningCompEditorView(id: id),
    );
  }
}

class _ListeningCompEditorView extends StatefulWidget {
  final String? id;
  const _ListeningCompEditorView({this.id});

  @override
  State<_ListeningCompEditorView> createState() => _ListeningCompEditorViewState();
}

class _ListeningCompEditorViewState extends State<_ListeningCompEditorView> {
  final _titleCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: '5'); // Mặc định 5 phút

  PlatformFile? _selectedAudioFile;
  String? _currentAudioUrl;
  bool _isSubmitting = false;
  String _difficulty = 'easy';
  List<Map<String, dynamic>> questions = [];
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    // 🔥 LOGIC TẠO MỚI HOẶC SỬA NẰM Ở ĐÂY
    if (widget.id != null) {
      // 1. Nếu có ID -> Đang mở chế độ Sửa -> Bật loading và gọi API lấy chi tiết
      _isLoadingDetail = true;
      context.read<AdminListeningCompBloc>().add(GetListeningCompDetailEvent(widget.id!));
    } else {
      // 2. Nếu không có ID -> Đang Tạo mới -> Tạo sẵn 1 form câu hỏi trống
      _addNewQuestion();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  // 🔥 HÀM NÀY SẼ ĐƯỢC GỌI ĐỂ FILL DỮ LIỆU KHI API TRẢ VỀ THÀNH CÔNG
  void _populateData(ListeningCompEntity item) {
    _titleCtrl.text = item.title;
    _timeCtrl.text = item.minutesToComplete.toString();
    _difficulty = item.difficulty;
    _currentAudioUrl = item.audioUrl;

    setState(() {
      questions = item.questions.map((q) => {
        "key": UniqueKey(),
        "id": q.id,
        "questionText": q.questionText,
        "options": List<String>.from(q.options),
        "correctAnswerIndex": q.correctAnswerIndex,
        "reasoning": q.feedback?.reasoning ?? '',
        "hintSec": q.feedback?.hintTimestampSeconds?.toString() ?? '',
      }).toList();

      // Đảm bảo đủ 4 options (phòng hờ database bị thiếu)
      for (var q in questions) {
        while ((q['options'] as List).length < 4) {
          (q['options'] as List).add("");
        }
      }
      _isLoadingDetail = false; // Tắt loading khi đã fill xong
    });
  }

  void _addNewQuestion() {
    setState(() {
      questions.add({
        "key": UniqueKey(),
        "id": "",
        "questionText": "",
        "options": ["", "", "", ""],
        "correctAnswerIndex": 0,
        "reasoning": "",
        "hintSec": "",
      });
    });
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: kIsWeb);
    if (result != null) setState(() => _selectedAudioFile = result.files.first);
  }

  void _onSubmit() {
    if (_isSubmitting) return; // chặn double-submit tạo bản trùng
    FocusManager.instance.primaryFocus?.unfocus();

    if (_titleCtrl.text.isEmpty) {
      AppCornerToast.show(context, "Vui lòng nhập Title", error: true);
      return;
    }

    // Ràng buộc Audio: Nếu tạo mới BẮT BUỘC phải chọn audio. Nếu sửa thì có thể giữ nguyên (ko chọn thêm)
    if (widget.id == null && _selectedAudioFile == null && _currentAudioUrl == null) {
      AppCornerToast.show(context, "Vui lòng chọn file Audio", error: true);
      return;
    }

    // Đóng gói dữ liệu câu hỏi
    List<ListeningCompQuestionEntity> questionEntities = questions.map((q) {
      return ListeningCompQuestionEntity(
        id: q['id'] ?? '',
        questionText: q['questionText'],
        options: List<String>.from(q['options']),
        correctAnswerIndex: q['correctAnswerIndex'],
        feedback: ListeningCompFeedbackEntity(
          reasoning: q['reasoning'],
          hintTimestampSeconds: int.tryParse(q['hintSec'] ?? ''),
        ),
      );
    }).toList();

    final newEntity = ListeningCompEntity(
      id: widget.id ?? '',
      title: _titleCtrl.text,
      audioUrl: _currentAudioUrl ?? '', // Sẽ được BLoC update nếu có gửi file mới
      transcript: '',
      difficulty: _difficulty,
      minutesToComplete: int.tryParse(_timeCtrl.text) ?? 5,
      totalQuestions: questionEntities.length,
      questions: questionEntities,
    );

    setState(() => _isSubmitting = true);

    // 🔥 GỌI EVENT TƯƠNG ỨNG VỚI CHẾ ĐỘ
    if (widget.id != null) {
      context.read<AdminListeningCompBloc>().add(UpdateListeningCompEvent(id: widget.id!, entity: newEntity, audioFile: _selectedAudioFile));
    } else {
      context.read<AdminListeningCompBloc>().add(CreateListeningCompEvent(entity: newEntity, audioFile: _selectedAudioFile));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminListeningCompBloc, AdminListeningCompState>(
      listener: (context, state) {
        if (state.status == AdminListeningCompStatus.failure) {
          setState(() => _isSubmitting = false);
          AppCornerToast.show(context, state.errorMessage ?? "Error", error: true);
        }

        // Lắng nghe khi API lấy chi tiết trả về Thành Công -> Gọi _populateData
        if (state.status == AdminListeningCompStatus.success && state.selectedListening != null && widget.id != null) {
          if (state.selectedListening!.id == widget.id && _isLoadingDetail) {
            _populateData(state.selectedListening!);
          }
        }

        if (state.status == AdminListeningCompStatus.success && _isSubmitting) {
          AppCornerToast.show(context, "Thao tác thành công!");
          context.pop(); // Quay lại trang List
        }
      },
      child: Scaffold(
        backgroundColor: kBgPage,
        appBar: AppBar(
          // Đổi Text AppBar tùy theo chế độ
          title: Text(widget.id == null ? 'Tạo Bài Trắc Nghiệm' : 'Sửa Bài Trắc Nghiệm', style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: kWhite,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextMain), onPressed: () => context.pop()),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: kBorder, height: 1)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FilledButton(
                onPressed: _onSubmit,
                style: FilledButton.styleFrom(
                    backgroundColor: kTextMain,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10)
                ),
                child: Text(widget.id == null ? "Create" : "Update"),
              ),
            )
          ],
        ),
        body: BlocBuilder<AdminListeningCompBloc, AdminListeningCompState>(
          builder: (context, state) {
            if (state.status == AdminListeningCompStatus.loading && (_isLoadingDetail || (questions.isEmpty && widget.id != null))) {
              return AdminSkeleton.page(AdminSkeleton.cardList());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Thông tin chung", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextMain)),
                  const SizedBox(height: 12),
                  _buildGeneralInfo(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Câu hỏi (${questions.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextMain)),
                      OutlinedButton.icon(
                        onPressed: _addNewQuestion,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: kTextMain,
                            side: const BorderSide(color: kBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Thêm Câu Hỏi"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...questions.asMap().entries.map((e) => _buildQuestionCard(e.key, e.value)),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGeneralInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadcnInput(label: "Tiêu đề bài nghe", controller: _titleCtrl, hint: "Ví dụ: TOEIC Part 3 - Meeting"),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ShadcnInput(label: "Thời gian (phút)", controller: _timeCtrl, hint: "5")),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Độ khó", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextMain)),
                    const SizedBox(height: 8),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.input), border: Border.all(color: kBorder), color: AppColors.surfaceSubtle),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _difficulty,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: const [
                            DropdownMenuItem(value: 'easy', child: Text("Easy", style: TextStyle(fontSize: 14))),
                            DropdownMenuItem(value: 'medium', child: Text("Medium", style: TextStyle(fontSize: 14))),
                            DropdownMenuItem(value: 'hard', child: Text("Hard", style: TextStyle(fontSize: 14))),
                          ],
                          onChanged: (val) => setState(() => _difficulty = val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAudioUploader(),
        ],
      ),
    );
  }

  Widget _buildAudioUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Audio Source", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextMain)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickAudio,
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(AppRadius.input), border: Border.all(color: kBorder)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.surfaceSubtle, borderRadius: BorderRadius.circular(AppRadius.chip)),
                  child: const Icon(Icons.audio_file_outlined, size: 20, color: kTextMain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedAudioFile != null
                            ? _selectedAudioFile!.name
                            : (_currentAudioUrl != null && _currentAudioUrl!.isNotEmpty
                            ? "Audio hiện tại đã có trên server"
                            : "Click để chọn file âm thanh mới"),
                        style: TextStyle(fontSize: 14, fontWeight: _selectedAudioFile != null ? FontWeight.w600 : FontWeight.normal, color: kTextMain),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedAudioFile == null && _currentAudioUrl == null)
                        const Text("Hỗ trợ định dạng MP3, WAV, M4A", style: TextStyle(fontSize: 12, color: kTextMuted)),
                    ],
                  ),
                ),
                if (_selectedAudioFile != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () => setState(() => _selectedAudioFile = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  const Icon(Icons.upload_file_rounded, size: 18, color: kTextMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: kBorder)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(color: AppColors.surfaceSubtle, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)), border: Border(bottom: BorderSide(color: kBorder))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: kTextMain, borderRadius: BorderRadius.circular(AppRadius.xs)),
                  child: Text("#${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => setState(() => questions.removeAt(index)), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Câu hỏi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMuted)),
                const SizedBox(height: 6),
                _CompactInput(hint: "Nội dung câu hỏi...", value: q['questionText'], onChanged: (v) => q['questionText'] = v),
                const SizedBox(height: 16),

                const Text("Các lựa chọn (Tick vào đáp án đúng)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMuted)),
                const SizedBox(height: 8),
                RadioGroup<int>(
                  groupValue: q['correctAnswerIndex'] as int?,
                  onChanged: (val) => setState(() => q['correctAnswerIndex'] = val),
                  child: Column(
                    children: List.generate(4, (optIdx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: optIdx,
                              fillColor: const WidgetStatePropertyAll(AppColors.success),
                            ),
                            Expanded(
                              child: _CompactInput(
                                hint: "Lựa chọn ${String.fromCharCode(65 + optIdx)}",
                                value: q['options'][optIdx],
                                onChanged: (v) => q['options'][optIdx] = v,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const Divider(height: 24, color: kBorder),

                const Text("Giải thích & Gợi ý Audio", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMuted)),
                const SizedBox(height: 8),
                _CompactInput(hint: "Vì sao chọn đáp án này?", value: q['reasoning'], onChanged: (v) => q['reasoning'] = v, maxLines: 2),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: kTextMuted),
                    const SizedBox(width: 8),
                    Expanded(child: _CompactInput(hint: "Giây chứa đáp án (vd: 45)", value: q['hintSec'], onChanged: (v) => q['hintSec'] = v, isNumber: true)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// Widget Input tối giản cho bảng/danh sách
class _CompactInput extends StatefulWidget {
  final String? value; final String hint; final Function(String) onChanged; final bool isNumber; final int maxLines;
  const _CompactInput({required this.hint, required this.onChanged, this.value, this.isNumber = false, this.maxLines = 1});
  @override State<_CompactInput> createState() => _CompactInputState();
}

class _CompactInputState extends State<_CompactInput> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _CompactInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _ctrl.text) {
      _ctrl.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      keyboardType: widget.isNumber ? TextInputType.number : TextInputType.multiline,
      maxLines: widget.maxLines,
      minLines: 1,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintText: widget.hint,
        hintStyle: const TextStyle(color: kTextMuted),
        filled: true,
        fillColor: kWhite,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: const BorderSide(color: kTextMain)),
      ),
    );
  }
}


