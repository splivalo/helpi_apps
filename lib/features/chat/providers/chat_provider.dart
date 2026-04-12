import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/providers/signalr_provider.dart';
import 'package:helpi_app/features/chat/data/chat_api_service.dart';
import 'package:helpi_app/features/chat/data/chat_models.dart';

// ── State ────────────────────────────────────────────

class ChatRoomsState {
  const ChatRoomsState({this.rooms = const [], this.isLoading = true});
  final List<ChatRoom> rooms;
  final bool isLoading;

  ChatRoomsState copyWith({List<ChatRoom>? rooms, bool? isLoading}) {
    return ChatRoomsState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatMessagesState {
  const ChatMessagesState({
    this.messages = const [],
    this.isLoading = true,
    this.hasMore = true,
    this.page = 1,
  });
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool hasMore;
  final int page;

  ChatMessagesState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? hasMore,
    int? page,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

// ── Chat Rooms Notifier ──────────────────────────────

class ChatRoomsNotifier extends StateNotifier<ChatRoomsState> {
  ChatRoomsNotifier() : super(const ChatRoomsState());

  final _api = ChatApiService();

  Future<void> loadRooms() async {
    state = state.copyWith(isLoading: true);
    final result = await _api.getRooms();
    if (result.success && result.data != null) {
      state = ChatRoomsState(rooms: result.data!, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Kreiraj ili dohvati sobu s drugim korisnikom, vrati room.
  Future<ChatRoom?> getOrCreateRoom(int otherUserId) async {
    final result = await _api.getOrCreateRoom(otherUserId);
    if (result.success && result.data != null) {
      // Dodaj u listu ako ne postoji
      final exists = state.rooms.any((r) => r.id == result.data!.id);
      if (!exists) {
        state = state.copyWith(rooms: [result.data!, ...state.rooms]);
      }
      return result.data;
    }
    return null;
  }

  /// Ažuriraj sobu kad stigne nova poruka (za badge/preview update).
  void onNewMessage(ChatMessage msg) {
    final rooms = [...state.rooms];
    final index = rooms.indexWhere((r) => r.id == msg.chatRoomId);
    if (index >= 0) {
      final room = rooms[index];
      room.lastMessageText = msg.content;
      room.lastMessageAt = msg.sentAt;
      room.lastMessageSenderUserId = msg.senderUserId;
      room.unreadCount++;
      // Stavi na vrh liste
      rooms.removeAt(index);
      rooms.insert(0, room);
      state = state.copyWith(rooms: rooms);
    }
  }

  /// Reset unread za određenu sobu.
  void clearUnread(int roomId) {
    final rooms = [...state.rooms];
    final index = rooms.indexWhere((r) => r.id == roomId);
    if (index >= 0) {
      rooms[index].unreadCount = 0;
      state = state.copyWith(rooms: rooms);
    }
  }
}

// ── Chat Messages Notifier ───────────────────────────

class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  ChatMessagesNotifier() : super(const ChatMessagesState());

  final _api = ChatApiService();
  int? _currentRoomId;

  int? get currentRoomId => _currentRoomId;

  Future<void> loadMessages(int roomId) async {
    _currentRoomId = roomId;
    state = const ChatMessagesState();
    final result = await _api.getMessages(roomId);
    if (result.success && result.data != null) {
      state = ChatMessagesState(
        messages: result.data!,
        isLoading: false,
        hasMore: result.data!.length >= 50,
        page: 1,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Učitaj starije poruke (paginacija).
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || _currentRoomId == null) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoading: true);
    final result = await _api.getMessages(_currentRoomId!, page: nextPage);
    if (result.success && result.data != null) {
      state = state.copyWith(
        messages: [...state.messages, ...result.data!],
        isLoading: false,
        hasMore: result.data!.length >= 50,
        page: nextPage,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Pošalji poruku (REST).
  Future<ChatMessage?> sendMessage(String content) async {
    if (_currentRoomId == null) return null;
    final result = await _api.sendMessage(_currentRoomId!, content);
    if (result.success && result.data != null) {
      // Dodaj na kraj liste (najnovije zadnje)
      state = state.copyWith(messages: [...state.messages, result.data!]);
      return result.data;
    }
    return null;
  }

  /// Označi sve kao pročitano.
  Future<void> markAsRead() async {
    if (_currentRoomId == null) return;
    await _api.markAsRead(_currentRoomId!);
  }

  /// Dodaj primljenu poruku iz SignalR-a.
  void onReceiveMessage(ChatMessage msg) {
    if (msg.chatRoomId != _currentRoomId) return;
    // Izbjegni duplikate
    if (state.messages.any((m) => m.id == msg.id)) return;
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  void clear() {
    _currentRoomId = null;
    state = const ChatMessagesState();
  }
}

// ── Providers ────────────────────────────────────────

final chatRoomsProvider =
    StateNotifierProvider<ChatRoomsNotifier, ChatRoomsState>((ref) {
      return ChatRoomsNotifier();
    });

final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, ChatMessagesState>((ref) {
      return ChatMessagesNotifier();
    });

/// Total unread chat badge count.
final chatUnreadCountProvider = StateProvider<int>((ref) => 0);

/// Helper: učitaj unread count iz API-ja.
Future<void> refreshChatUnreadCount(WidgetRef ref) async {
  final result = await ChatApiService().getUnreadCount();
  if (result.success && result.data != null) {
    ref.read(chatUnreadCountProvider.notifier).state = result.data!;
  }
}

/// Inicijalizacija SignalR chat event-ova.
void setupChatSignalR(WidgetRef ref) {
  final signalR = ref.read(signalRProvider);
  final tokenStorage = TokenStorage();

  signalR.on('ReceiveChatMessage', (args) async {
    if (args == null || args.isEmpty) return;
    try {
      final data = args[0] as Map<String, dynamic>;
      final msg = ChatMessage.fromJson(data);

      final myUserId = await tokenStorage.getUserId();
      if (myUserId == null) return;

      // Ako ja nisam sender → ažuriraj
      if (msg.senderUserId != myUserId) {
        ref.read(chatMessagesProvider.notifier).onReceiveMessage(msg);
        ref.read(chatRoomsProvider.notifier).onNewMessage(msg);
        // Refresh global unread count
        final result = await ChatApiService().getUnreadCount();
        if (result.success && result.data != null) {
          ref.read(chatUnreadCountProvider.notifier).state = result.data!;
        }
      }
    } catch (e) {
      debugPrint('[ChatSignalR] ReceiveChatMessage error: $e');
    }
  });

  signalR.on('ChatUnreadUpdate', (args) async {
    // Refresh unread count
    final result = await ChatApiService().getUnreadCount();
    if (result.success && result.data != null) {
      ref.read(chatUnreadCountProvider.notifier).state = result.data!;
    }
  });

  signalR.on('ChatMessagesRead', (args) {
    //Можemo dodati read receipt UI later
    debugPrint('[ChatSignalR] ChatMessagesRead: $args');
  });
}
