import 'package:flutter/material.dart';

import 'package:helpi_app/core/network/api_client.dart';
import 'package:helpi_app/core/network/api_endpoints.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/features/chat/data/chat_models.dart';

/// API servis za chat operacije.
class ChatApiService {
  final ApiClient _client = ApiClient();

  /// Dohvati sve sobe za trenutnog korisnika.
  Future<ApiResult<List<ChatRoom>>> getRooms() async {
    try {
      final response = await _client.get(ApiEndpoints.chatRooms);
      final list = response.data as List<dynamic>;
      final rooms = list
          .map((e) => ChatRoom.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(rooms);
    } catch (e) {
      debugPrint('[ChatApi] getRooms error: $e');
      return ApiResult.failure(AppApiService.friendlyError(e));
    }
  }

  /// Kreiraj ili dohvati sobu s drugim korisnikom.
  Future<ApiResult<ChatRoom>> getOrCreateRoom(int otherUserId) async {
    try {
      final response = await _client.post(
        ApiEndpoints.chatRooms,
        data: {'otherUserId': otherUserId},
      );
      final room = ChatRoom.fromJson(response.data as Map<String, dynamic>);
      return ApiResult.success(room);
    } catch (e) {
      debugPrint('[ChatApi] getOrCreateRoom error: $e');
      return ApiResult.failure(AppApiService.friendlyError(e));
    }
  }

  /// Dohvati poruke za sobu (paginirano).
  Future<ApiResult<List<ChatMessage>>> getMessages(
    int roomId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _client.get(
        ApiEndpoints.chatMessages(roomId),
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final list = response.data as List<dynamic>;
      final messages = list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(messages);
    } catch (e) {
      debugPrint('[ChatApi] getMessages error: $e');
      return ApiResult.failure(AppApiService.friendlyError(e));
    }
  }

  /// Pošalji poruku (REST fallback).
  Future<ApiResult<ChatMessage>> sendMessage(int roomId, String content) async {
    try {
      final response = await _client.post(
        ApiEndpoints.chatMessages(roomId),
        data: {'content': content},
      );
      final msg = ChatMessage.fromJson(response.data as Map<String, dynamic>);
      return ApiResult.success(msg);
    } catch (e) {
      debugPrint('[ChatApi] sendMessage error: $e');
      return ApiResult.failure(AppApiService.friendlyError(e));
    }
  }

  /// Označi poruke u sobi kao pročitane.
  Future<ApiResult<int>> markAsRead(int roomId) async {
    try {
      final response = await _client.put(ApiEndpoints.chatMarkRead(roomId));
      final data = response.data as Map<String, dynamic>;
      final count = data['markedAsRead'] as int? ?? 0;
      return ApiResult.success(count);
    } catch (e) {
      debugPrint('[ChatApi] markAsRead error: $e');
      return ApiResult.failure(AppApiService.friendlyError(e));
    }
  }

  /// Dohvati ukupan broj nepročitanih poruka.
  Future<ApiResult<int>> getUnreadCount() async {
    try {
      final response = await _client.get(ApiEndpoints.chatUnreadCount);
      final data = response.data as Map<String, dynamic>;
      final count = data['unreadCount'] as int? ?? 0;
      return ApiResult.success(count);
    } catch (e) {
      debugPrint('[ChatApi] getUnreadCount error: $e');
      return ApiResult.failure(AppApiService.friendlyError(e));
    }
  }
}
