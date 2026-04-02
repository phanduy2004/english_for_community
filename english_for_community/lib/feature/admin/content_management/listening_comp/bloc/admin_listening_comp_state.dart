import 'package:equatable/equatable.dart';
import '../../../../../core/entity/listening_comp_entity.dart';

enum AdminListeningCompStatus { initial, loading, success, failure }

class AdminListeningCompState extends Equatable {
  final AdminListeningCompStatus status;
  final List<ListeningCompEntity> listenings;
  final ListeningCompEntity? selectedListening;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;

  const AdminListeningCompState({
    this.status = AdminListeningCompStatus.initial,
    this.listenings = const [],
    this.selectedListening,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  AdminListeningCompState copyWith({
    AdminListeningCompStatus? status,
    List<ListeningCompEntity>? listenings,
    ListeningCompEntity? selectedListening,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    bool clearSelected = false, // Cờ để ép selectedListening về null
  }) {
    return AdminListeningCompState(
      status: status ?? this.status,
      listenings: listenings ?? this.listenings,
      selectedListening: clearSelected ? null : (selectedListening ?? this.selectedListening),
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  List<Object?> get props => [
    status,
    listenings,
    selectedListening,
    errorMessage,
    currentPage,
    totalPages,
  ];
}