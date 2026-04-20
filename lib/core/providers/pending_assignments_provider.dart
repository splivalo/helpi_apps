import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/core/network/api_client.dart';
import 'package:helpi_app/core/network/api_endpoints.dart';

class ScheduleItem {
  final int orderScheduleId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  ScheduleItem({
    required this.orderScheduleId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  static const _dayNames = [
    '',
    'Pon',
    'Uto',
    'Sri',
    'Čet',
    'Pet',
    'Sub',
    'Ned',
  ];

  String get dayLabel =>
      dayOfWeek >= 1 && dayOfWeek <= 7 ? _dayNames[dayOfWeek] : '?';
}

class PendingAssignment {
  final int assignmentId;
  final int orderId;
  final String? seniorName;
  final String? address;
  final String? startDate;
  final String? endDate;
  final List<int> assignmentIds;
  final List<ScheduleItem> scheduleItems;

  PendingAssignment({
    required this.assignmentId,
    required this.orderId,
    this.seniorName,
    this.address,
    this.startDate,
    this.endDate,
    this.assignmentIds = const [],
    this.scheduleItems = const [],
  });
}

class PendingAssignmentsNotifier
    extends StateNotifier<List<PendingAssignment>> {
  PendingAssignmentsNotifier() : super([]);

  final _api = ApiClient();

  Future<void> load() async {
    try {
      final response = await _api.get(ApiEndpoints.pendingAssignments);
      final list = response.data as List<dynamic>;
      final assignments = <PendingAssignment>[];
      for (final item in list) {
        final map = item as Map<String, dynamic>;

        // Parse assignmentIds list
        final rawIds = map['assignmentIds'] as List<dynamic>? ?? [];
        final ids = rawIds.map((e) => (e as num).toInt()).toList();

        // Parse scheduleItems
        final rawSchedule = map['scheduleItems'] as List<dynamic>? ?? [];
        final schedules = rawSchedule.map((s) {
          final sm = s as Map<String, dynamic>;
          return ScheduleItem(
            orderScheduleId: (sm['orderScheduleId'] as num?)?.toInt() ?? 0,
            dayOfWeek: (sm['dayOfWeek'] as num?)?.toInt() ?? 0,
            startTime: sm['startTime'] as String? ?? '',
            endTime: sm['endTime'] as String? ?? '',
          );
        }).toList();

        assignments.add(
          PendingAssignment(
            assignmentId: (map['id'] as num).toInt(),
            orderId: (map['orderId'] as num?)?.toInt() ?? 0,
            seniorName: map['seniorName'] as String?,
            address: map['address'] as String?,
            startDate: map['startDate'] as String?,
            endDate: map['endDate'] as String?,
            assignmentIds: ids,
            scheduleItems: schedules,
          ),
        );
      }
      state = assignments;
      debugPrint('[PendingAssignments] loaded ${assignments.length} pending');
    } catch (e) {
      debugPrint('[PendingAssignments] load failed: $e');
    }
  }

  Future<bool> accept(int assignmentId) async {
    // Find the assignment — match by primary ID or any ID in the group
    final assignment = state
        .where(
          (a) =>
              a.assignmentId == assignmentId ||
              a.assignmentIds.contains(assignmentId),
        )
        .firstOrNull;
    final ids = assignment?.assignmentIds ?? [assignmentId];
    final orderId = assignment?.orderId;
    debugPrint(
      '[PendingAssignments] accept assignmentId=$assignmentId, '
      'found=${assignment != null}, ids=$ids, orderId=$orderId',
    );
    try {
      for (final id in ids) {
        debugPrint('[PendingAssignments] accepting SA id=$id');
        await _api.post(ApiEndpoints.acceptAssignment(id));
        debugPrint('[PendingAssignments] accepted SA id=$id OK');
      }
      state = [
        for (final a in state)
          if (a.assignmentId != assignmentId && a.orderId != orderId) a,
      ];
      return true;
    } catch (e) {
      debugPrint('[PendingAssignments] accept FAILED: $e');
      return false;
    }
  }

  Future<bool> decline(int assignmentId) async {
    final assignment = state
        .where(
          (a) =>
              a.assignmentId == assignmentId ||
              a.assignmentIds.contains(assignmentId),
        )
        .firstOrNull;
    final ids = assignment?.assignmentIds ?? [assignmentId];
    final orderId = assignment?.orderId;
    debugPrint(
      '[PendingAssignments] decline assignmentId=$assignmentId, '
      'found=${assignment != null}, ids=$ids, orderId=$orderId',
    );
    try {
      // Decline only the first ID — backend auto-declines all other
      // pending assignments for the same student+order
      debugPrint('[PendingAssignments] declining SA id=${ids.first}');
      await _api.post(ApiEndpoints.declineAssignment(ids.first));
      debugPrint('[PendingAssignments] declined SA id=${ids.first} OK');
      state = [
        for (final a in state)
          if (a.assignmentId != assignmentId && a.orderId != orderId) a,
      ];
      return true;
    } catch (e) {
      debugPrint('[PendingAssignments] decline FAILED: $e');
      return false;
    }
  }

  void removeAssignment(int assignmentId) {
    state = [
      for (final a in state)
        if (a.assignmentId != assignmentId) a,
    ];
  }
}

final pendingAssignmentsProvider =
    StateNotifierProvider<PendingAssignmentsNotifier, List<PendingAssignment>>(
      (ref) => PendingAssignmentsNotifier(),
    );
