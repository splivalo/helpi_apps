import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/features/schedule/data/job_model.dart';

/// Student jobs state.
class JobsState {
  const JobsState({this.jobs = const [], this.isLoading = true});

  final List<Job> jobs;
  final bool isLoading;

  JobsState copyWith({List<Job>? jobs, bool? isLoading}) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class JobsNotifier extends StateNotifier<JobsState> {
  JobsNotifier() : super(const JobsState());

  final _api = AppApiService();
  final _tokenStorage = TokenStorage();

  /// Učitaj poslove s API-ja za trenutnog studenta.
  Future<void> loadJobs() async {
    final userId = await _tokenStorage.getUserId();
    if (userId == null) return;

    final result = await _api.getSessionsByStudent(userId);
    if (result.success && result.data != null) {
      // Također osvježi MockJobs za kompatibilnost
      MockJobs.all
        ..clear()
        ..addAll(result.data!);
      state = JobsState(jobs: result.data!, isLoading: false);
      debugPrint('[JobsNotifier] loaded ${result.data!.length} jobs');
    } else {
      // Koristi MockJobs kao fallback
      state = JobsState(jobs: List.of(MockJobs.all), isLoading: false);
    }
  }

  /// Replace all jobs (called by RealTimeSyncService).
  void replaceAll(List<Job> jobs) {
    MockJobs.all
      ..clear()
      ..addAll(jobs);
    state = JobsState(jobs: jobs, isLoading: false);
  }
}

final jobsProvider = StateNotifierProvider<JobsNotifier, JobsState>((ref) {
  return JobsNotifier();
});
