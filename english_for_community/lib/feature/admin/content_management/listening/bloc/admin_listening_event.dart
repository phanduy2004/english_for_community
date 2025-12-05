// lib/feature/admin/content_management/listening/bloc/admin_listening_event.dart

import 'dart:io'; // 🔥 Import IO
import 'package:equatable/equatable.dart';
import '../../../../../core/entity/cue_entity.dart';
import '../../../../../core/entity/listening_entity.dart';
import 'package:file_picker/file_picker.dart'; // 🔥 Dùng thư viện này
abstract class AdminListeningEvent extends Equatable {
  const AdminListeningEvent();
  @override
  List<Object?> get props => [];
}

// 1. Get List
class GetAdminListeningListEvent extends AdminListeningEvent {
  final int page;
  final int limit;
  final String difficulty;

  const GetAdminListeningListEvent({
    this.page = 1,
    this.limit = 20,
    this.difficulty = 'all',
  });

  @override
  List<Object?> get props => [page, limit, difficulty];
}

// 2. Get Detail
class GetListeningDetailEvent extends AdminListeningEvent {
  final String id;
  const GetListeningDetailEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// 3. Create (Thêm audioFile)
class CreateListeningEvent extends AdminListeningEvent {
  final ListeningEntity listening;
  final List<CueEntity> cues;
  final PlatformFile? audioFile; // 🔥 Đổi thành PlatformFile
  const CreateListeningEvent({
    required this.listening,
    required this.cues,
    this.audioFile,  });

  @override
  List<Object?> get props => [listening, cues, audioFile];
}

// 4. Update (Thêm audioFile)
class UpdateListeningEvent extends AdminListeningEvent {
  final String id;
  final ListeningEntity listening;
  final List<CueEntity> cues;
  final PlatformFile? audioFile; // 🔥 Đổi thành PlatformFile
  const UpdateListeningEvent({
    required this.id,
    required this.listening,
    required this.cues,
    this.audioFile,
  });

  @override
  List<Object?> get props => [id, listening, cues, audioFile];
}

// 5. Delete
class DeleteListeningEvent extends AdminListeningEvent {
  final String id;
  const DeleteListeningEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// 6. Clear Selection
class ClearSelectedListeningEvent extends AdminListeningEvent {}