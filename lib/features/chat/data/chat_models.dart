/// Model za chat sobu između dva korisnika.
class ChatRoom {
  ChatRoom({
    required this.id,
    required this.participant1UserId,
    required this.participant1Name,
    required this.participant1Role,
    required this.participant2UserId,
    required this.participant2Name,
    required this.participant2Role,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastMessageSenderUserId,
    this.unreadCount = 0,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as int,
      participant1UserId: json['participant1UserId'] as int,
      participant1Name: json['participant1Name'] as String,
      participant1Role: json['participant1Role'] as String,
      participant2UserId: json['participant2UserId'] as int,
      participant2Name: json['participant2Name'] as String,
      participant2Role: json['participant2Role'] as String,
      lastMessageText: json['lastMessageText'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      lastMessageSenderUserId: json['lastMessageSenderUserId'] as int?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final int id;
  final int participant1UserId;
  final String participant1Name;
  final String participant1Role;
  final int participant2UserId;
  final String participant2Name;
  final String participant2Role;
  String? lastMessageText;
  DateTime? lastMessageAt;
  int? lastMessageSenderUserId;
  int unreadCount;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Ime drugog sudionika (ne ja).
  String otherName(int myUserId) =>
      participant1UserId == myUserId ? participant2Name : participant1Name;

  /// Role drugog sudionika.
  String otherRole(int myUserId) =>
      participant1UserId == myUserId ? participant2Role : participant1Role;

  /// UserId drugog sudionika.
  int otherUserId(int myUserId) =>
      participant1UserId == myUserId ? participant2UserId : participant1UserId;
}

/// Model za jednu chat poruku.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderUserId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.readAt,
    this.isDeleted = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      chatRoomId: json['chatRoomId'] as int,
      senderUserId: json['senderUserId'] as int,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  final int id;
  final int chatRoomId;
  final int senderUserId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  DateTime? readAt;
  final bool isDeleted;

  /// Je li ova poruka moja?
  bool isMine(int myUserId) => senderUserId == myUserId;

  /// Formatirani sat (HH:mm).
  String get timeFormatted {
    final local = sentAt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
