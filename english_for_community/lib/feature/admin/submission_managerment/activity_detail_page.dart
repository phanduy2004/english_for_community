import 'package:english_for_community/feature/admin/submission_managerment/reading_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/history_event.dart';
import 'bloc_detail/activity_detail_bloc.dart';
import 'bloc_detail/activity_detail_state.dart';
import 'model/activity_model.dart';

// Import your detailed views
import 'writing_detail_view.dart';
import 'speaking_detail_view.dart';
import 'listening_detail_view.dart'; // Ensure this file exists

const Color kBgPage = Color(0xFFF1F5F9);
const Color kWhite = Colors.white;
const Color kTextMain = Color(0xFF0F172A);

class ActivityDetailPage extends StatelessWidget {
  final String id;
  final ActivityType type;
  final String? summaryTitle; // Added
  final DateTime? summaryDate; // Added

  const ActivityDetailPage({
    super.key,
    required this.id,
    required this.type,
    this.summaryTitle,
    this.summaryDate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ActivityDetailBloc()..add(FetchActivityDetailEvent(id: id, type: type)),
      child: Scaffold(
        backgroundColor: kBgPage,
        appBar: AppBar(
          title: const Text('Detail Review', style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain)),
          backgroundColor: kWhite,
          elevation: 0,
          leading: const BackButton(color: kTextMain),
        ),
        body: BlocBuilder<ActivityDetailBloc, ActivityDetailState>(
          builder: (context, state) {
            if (state.status == DetailStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == DetailStatus.error) {
              return Center(child: Text("Error: ${state.errorMessage}"));
            }
            if (state.status == DetailStatus.success) {
              switch (type) {
                case ActivityType.writing:
                  if (state.writingData != null) {
                    return WritingDetailView(data: state.writingData!);
                  }
                  break;
                case ActivityType.reading:
                  if (state.readingData != null) {
                    return ReadingDetailView(data: state.readingData!);
                  }
                  break;
                case ActivityType.speaking:
                  if (state.speakingData != null) {
                    // Fix: Pass 'data' directly, matching SpeakingDetailView constructor
                    return SpeakingDetailView(data: state.speakingData!);
                  }
                  break;
                case ActivityType.listening:
                  if (state.listeningData != null) {
                    // Fix: Pass 'data' directly, matching ListeningDetailView constructor
                    return ListeningDetailView(data: state.listeningData!);
                  }
                  break;
                default:
                  return const SizedBox.shrink();
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}