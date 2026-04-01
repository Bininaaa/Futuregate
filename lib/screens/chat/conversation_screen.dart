import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/public_profile_service.dart';
import '../../widgets/chat/chat_formatters.dart';
import '../../widgets/chat/chat_confirmation_dialog.dart';
import '../../widgets/chat/chat_input_bar.dart';
import '../../widgets/chat/chat_message_bubble.dart';
import '../../widgets/chat/chat_theme.dart';
import '../../widgets/profile_avatar.dart';
import 'user_profile_preview_screen.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String otherName;
  final String recipientId;
  final String otherRole;
  final String contextLabel;
  final String fallbackProfileHeadline;
  final String fallbackProfileAbout;
  final String fallbackProfileLocation;
  final String fallbackProfileWebsite;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.otherName,
    this.recipientId = '',
    this.otherRole = '',
    this.contextLabel = '',
    this.fallbackProfileHeadline = '',
    this.fallbackProfileAbout = '',
    this.fallbackProfileLocation = '',
    this.fallbackProfileWebsite = '',
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  PendingChatAttachment? _pendingAttachment;
  String? _editingMessageId;
  String? _lastHandledError;
  Future<UserModel?>? _profileFuture;
  String _profileUserId = '';
  late final Stream<ConversationModel?> _conversationStream;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _conversationStream = context.read<ChatProvider>().watchConversation(
      widget.conversationId,
    );

    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid != null) {
      context.read<ChatProvider>().listenToMessages(widget.conversationId, uid);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<ChatProvider>().stopListeningToMessages();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_editingMessageId != null) {
      setState(() => _editingMessageId = null);
    }

    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _pendingAttachment = PendingChatAttachment(
        fileName: file.name,
        filePath: file.path,
        bytes: bytes,
        fileSize: bytes.length,
        mimeType: _inferMimeType(file.name, fallback: 'image/jpeg'),
        messageType: 'image',
      );
    });
  }

  Future<void> _pickFile() async {
    if (_editingMessageId != null) {
      setState(() => _editingMessageId = null);
    }

    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    if (!mounted) {
      return;
    }

    setState(() {
      _pendingAttachment = PendingChatAttachment(
        fileName: file.name,
        filePath: file.path ?? '',
        bytes: file.bytes,
        fileSize: file.size,
        mimeType: file.extension == null
            ? 'application/octet-stream'
            : _inferMimeType(file.name, fallback: 'application/octet-stream'),
        messageType: _isImageFile(file.name) ? 'image' : 'file',
      );
    });
  }

  Future<void> _sendMessage(ConversationModel? conversation) async {
    final auth = context.read<AuthProvider>().userModel;
    final provider = context.read<ChatProvider>();
    final text = _messageController.text.trim();
    final attachment = _pendingAttachment;

    if (_editingMessageId != null && attachment == null) {
      if (text.isEmpty) {
        return;
      }

      await provider.editMessage(
        conversationId: widget.conversationId,
        messageId: _editingMessageId!,
        newText: text,
      );

      if (!mounted || provider.error != null) {
        return;
      }

      setState(() {
        _editingMessageId = null;
        _messageController.clear();
      });
      return;
    }

    if (auth == null || (text.isEmpty && attachment == null)) {
      return;
    }

    final draftText = text;
    final draftAttachment = attachment;

    _messageController.clear();
    setState(() {
      _pendingAttachment = null;
      _editingMessageId = null;
    });

    await provider.sendMessage(
      conversationId: widget.conversationId,
      senderId: auth.uid,
      senderRole: auth.role,
      text: text,
      recipientId:
          conversation?.otherParticipantId(auth.uid) ?? widget.recipientId,
      messageType: attachment?.messageType ?? 'text',
      attachmentFileName: attachment?.fileName ?? '',
      attachmentFilePath: attachment?.filePath ?? '',
      attachmentFileBytes: attachment?.bytes,
      attachmentFileSize: attachment?.fileSize ?? 0,
      attachmentMimeType: attachment?.mimeType ?? '',
    );

    if (!mounted || provider.error == null) {
      return;
    }

    setState(() => _pendingAttachment = draftAttachment);
    _messageController.text = draftText;
    _messageController.selection = TextSelection.collapsed(
      offset: _messageController.text.length,
    );
  }

  void _startEdit(MessageModel message) {
    setState(() {
      _editingMessageId = message.id;
      _messageController.text = message.text;
      _pendingAttachment = null;
    });
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showChatConfirmationDialog(
      context,
      title: 'Delete message?',
      message: 'Delete this message for everyone?',
      confirmLabel: 'Delete',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirm != true || !mounted) {
      return;
    }

    await context.read<ChatProvider>().deleteMessage(
      conversationId: widget.conversationId,
      messageId: messageId,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleProviderError(ChatProvider chatProvider) {
    final error = chatProvider.error;
    if (error == null || error.isEmpty) {
      _lastHandledError = null;
      return;
    }

    if (_lastHandledError == error) {
      return;
    }

    _lastHandledError = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_readableError(error))));
      context.read<ChatProvider>().clearError();
    });
  }

  String _readableError(String value) {
    final trimmed = value.trim();
    return trimmed.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  void _openProfile({
    required String userId,
    required String fallbackName,
    required String fallbackRole,
    String fallbackHeadline = '',
    String fallbackAbout = '',
    String fallbackLocation = '',
    String fallbackWebsite = '',
    String contextLabel = '',
  }) {
    if (userId.trim().isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePreviewScreen(
          userId: userId,
          fallbackName: fallbackName,
          fallbackRole: fallbackRole,
          fallbackHeadline: fallbackHeadline,
          fallbackAbout: fallbackAbout,
          fallbackLocation: fallbackLocation,
          fallbackWebsite: fallbackWebsite,
          contextLabel: contextLabel,
        ),
      ),
    );
  }

  Future<void> _toggleArchive(ConversationModel conversation) async {
    final auth = context.read<AuthProvider>().userModel;
    final provider = context.read<ChatProvider>();
    if (auth == null) {
      return;
    }

    final archived = !provider.isConversationArchivedFor(
      conversation,
      auth.uid,
    );
    if (archived) {
      final confirmed = await showChatConfirmationDialog(
        context,
        title: 'Archive conversation?',
        message: 'Are you sure you want to archive this conversation?',
        confirmLabel: 'Archive',
        icon: Icons.archive_outlined,
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    await provider.archiveConversation(
      conversationId: widget.conversationId,
      userId: auth.uid,
      archived: archived,
    );

    if (!mounted || provider.error != null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          archived ? 'Conversation moved to Archived' : 'Conversation restored to Inbox',
        ),
      ),
    );

    if (archived) {
      Navigator.pop(context);
    }
  }

  Future<void> _toggleMute(ConversationModel conversation) async {
    final auth = context.read<AuthProvider>().userModel;
    final provider = context.read<ChatProvider>();
    if (auth == null) {
      return;
    }

    final muted = !provider.isConversationMutedFor(conversation, auth.uid);
    await provider.muteConversation(
      conversationId: widget.conversationId,
      userId: auth.uid,
      muted: muted,
    );

    if (!mounted || provider.error != null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(muted ? 'Chat muted' : 'Chat unmuted')),
    );
  }

  Future<void> _deleteConversation(ConversationModel conversation) async {
    final auth = context.read<AuthProvider>().userModel;
    final provider = context.read<ChatProvider>();
    if (auth == null) {
      return;
    }

    final confirmed = await showChatConfirmationDialog(
      context,
      title: 'Delete conversation?',
      message:
          'Are you sure you want to delete this conversation? This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await provider.deleteConversation(
      conversationId: widget.conversationId,
      userId: auth.uid,
    );
    if (!mounted || provider.error != null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conversation deleted')),
    );
    Navigator.pop(context);
  }

  String _resolveOtherRole(ConversationModel? conversation, UserModel? auth) {
    final currentUserId = auth?.uid ?? '';
    final fromConversation =
        conversation?.otherParticipantRole(currentUserId).trim() ?? '';
    if (fromConversation.isNotEmpty) {
      return fromConversation;
    }

    if (widget.otherRole.trim().isNotEmpty) {
      return widget.otherRole.trim();
    }

    return auth?.role == 'company' ? 'student' : 'company';
  }

  String _resolveContextLabel(ConversationModel? conversation) {
    final fromConversation = conversation?.contextLabel.trim() ?? '';
    if (fromConversation.isNotEmpty) {
      return fromConversation;
    }

    return widget.contextLabel.trim();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final messages = List<MessageModel>.of(chatProvider.messages);
    final auth = context.watch<AuthProvider>().userModel;

    _handleProviderError(chatProvider);

    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: ChatThemePalette.background,
      body: StreamBuilder<ConversationModel?>(
        stream: _conversationStream,
        builder: (context, snapshot) {
          final conversation = snapshot.data;
          final currentUserId = auth?.uid ?? '';
          final otherUserId =
              conversation?.otherParticipantId(currentUserId) ??
              widget.recipientId;
          final otherRole = _resolveOtherRole(conversation, auth);
          final otherName =
              conversation?.displayNameFor(currentUserId) ?? widget.otherName;
          final contextLabel = _resolveContextLabel(conversation);
          final normalizedOtherUserId = otherUserId.trim();

          if (_profileUserId != normalizedOtherUserId ||
              _profileFuture == null) {
            _profileUserId = normalizedOtherUserId;
            _profileFuture = normalizedOtherUserId.isEmpty
                ? Future<UserModel?>.value(null)
                : PublicProfileService.instance.fetchPublicProfile(
                    normalizedOtherUserId,
                  );
          }

          return FutureBuilder<UserModel?>(
            future: _profileFuture,
            builder: (context, profileSnapshot) {
              final otherUser = profileSnapshot.data;
              final fallbackHeadline =
                  widget.fallbackProfileHeadline.trim().isNotEmpty
                  ? widget.fallbackProfileHeadline.trim()
                  : otherRole == 'company'
                  ? (otherUser?.sector ?? '').trim()
                  : [
                      (otherUser?.fieldOfStudy ?? '').trim(),
                      (otherUser?.university ?? '').trim(),
                    ].where((value) => value.isNotEmpty).join(' - ');
              final fallbackAbout =
                  widget.fallbackProfileAbout.trim().isNotEmpty
                  ? widget.fallbackProfileAbout.trim()
                  : otherRole == 'company'
                  ? (otherUser?.description ?? '').trim()
                  : (otherUser?.bio ?? '').trim();
              final fallbackLocation =
                  widget.fallbackProfileLocation.trim().isNotEmpty
                  ? widget.fallbackProfileLocation.trim()
                  : (otherUser?.location ?? '').trim();
              final fallbackWebsite =
                  widget.fallbackProfileWebsite.trim().isNotEmpty
                  ? widget.fallbackProfileWebsite.trim()
                  : (otherUser?.website ?? '').trim();

              return DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFFFFF),
                      ChatThemePalette.background,
                      Color(0xFFF3F6FF),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.38, 1],
                  ),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      top: -80,
                      right: -34,
                      child: _BackgroundOrb(
                        size: 240,
                        color: ChatThemePalette.primary,
                        opacity: 0.06,
                      ),
                    ),
                    const Positioned(
                      top: 156,
                      left: -72,
                      child: _BackgroundOrb(
                        size: 180,
                        color: ChatThemePalette.secondary,
                        opacity: 0.05,
                      ),
                    ),
                    const Positioned(
                      bottom: 132,
                      right: -54,
                      child: _BackgroundOrb(
                        size: 170,
                        color: ChatThemePalette.accent,
                        opacity: 0.05,
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                            child: _ConversationHeader(
                              title: otherName,
                              otherUser: otherUser,
                              otherUserId: otherUserId,
                              otherRole: otherRole,
                              fallbackName: otherName,
                              onBack: () => Navigator.pop(context),
                              onOpenProfile: () => _openProfile(
                                userId: otherUserId,
                                fallbackName: otherName,
                                fallbackRole: otherRole,
                                fallbackHeadline: fallbackHeadline,
                                fallbackAbout: fallbackAbout,
                                fallbackLocation: fallbackLocation,
                                fallbackWebsite: fallbackWebsite,
                                contextLabel: contextLabel,
                              ),
                              onMenuSelected: (value) {
                                if (value == 'profile') {
                                  _openProfile(
                                    userId: otherUserId,
                                    fallbackName: otherName,
                                    fallbackRole: otherRole,
                                    fallbackHeadline: fallbackHeadline,
                                    fallbackAbout: fallbackAbout,
                                    fallbackLocation: fallbackLocation,
                                    fallbackWebsite: fallbackWebsite,
                                    contextLabel: contextLabel,
                                  );
                                  return;
                                }
                                if (value == 'mute' && conversation != null) {
                                  _toggleMute(conversation);
                                  return;
                                }
                                if (value == 'archive' &&
                                    conversation != null) {
                                  _toggleArchive(conversation);
                                  return;
                                }
                                if (value == 'delete' &&
                                    conversation != null) {
                                  _deleteConversation(conversation);
                                }
                              },
                              muted: auth == null || conversation == null
                                  ? false
                                  : chatProvider.isConversationMutedFor(
                                      conversation,
                                      auth.uid,
                                    ),
                              archived: auth == null || conversation == null
                                  ? false
                                  : chatProvider.isConversationArchivedFor(
                                      conversation,
                                      auth.uid,
                                    ),
                            ),
                          ),
                          if (contextLabel.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: ChatThemePalette.headerGradient,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: ChatThemePalette.primary
                                          .withValues(alpha: 0.14),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.workspaces_outline,
                                        size: 15,
                                        color: ChatThemePalette.primaryDark,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          contextLabel,
                                          style:
                                              ChatThemeStyles.meta(
                                                ChatThemePalette.primaryDark,
                                              ).copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: ChatThemePalette.canvasGradient,
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  boxShadow: ChatThemeStyles.softShadow(0.06),
                                ),
                                child: messages.isEmpty
                                    ? _EmptyConversationState(
                                        contextLabel: contextLabel,
                                        otherName: otherName,
                                      )
                                    : LayoutBuilder(
                                        builder: (context, constraints) {
                                          return SingleChildScrollView(
                                            controller: _scrollController,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            padding: const EdgeInsets.fromLTRB(
                                              0,
                                              10,
                                              0,
                                              20,
                                            ),
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minHeight:
                                                    constraints.maxHeight,
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: List.generate(messages.length, (
                                                  index,
                                                ) {
                                                  final message =
                                                      messages[index];
                                                  final previous = index > 0
                                                      ? messages[index - 1]
                                                      : null;
                                                  final next =
                                                      index <
                                                          messages.length - 1
                                                      ? messages[index + 1]
                                                      : null;
                                                  final isMe =
                                                      message.senderId ==
                                                      currentUserId;
                                                  final startsNewDay =
                                                      previous == null ||
                                                      !ChatFormatters.isSameMessageDay(
                                                        previous.sentAt,
                                                        message.sentAt,
                                                      );
                                                  final isFirstInGroup =
                                                      startsNewDay ||
                                                      previous.senderId !=
                                                          message.senderId;
                                                  final isLastInGroup =
                                                      next == null ||
                                                      !ChatFormatters.isSameMessageDay(
                                                        message.sentAt,
                                                        next.sentAt,
                                                      ) ||
                                                      next.senderId !=
                                                          message.senderId;

                                                  return Column(
                                                    children: [
                                                      if (startsNewDay)
                                                        _DateDivider(
                                                          label: ChatFormatters.dayDividerLabel(
                                                            message.sentAt
                                                                    ?.toDate() ??
                                                                DateTime.now(),
                                                          ),
                                                        ),
                                                      ChatMessageBubble(
                                                        conversationId: widget
                                                            .conversationId,
                                                        message: message,
                                                        isMe: isMe,
                                                        isFirstInGroup:
                                                            isFirstInGroup,
                                                        isLastInGroup:
                                                            isLastInGroup,
                                                        showAvatar:
                                                            !isMe &&
                                                            isLastInGroup,
                                                        otherUser: otherUser,
                                                        otherUserId:
                                                            otherUserId,
                                                        otherRole: otherRole,
                                                        fallbackName: otherName,
                                                        onEdit:
                                                            isMe &&
                                                                message
                                                                    .isTextMessage &&
                                                                !message
                                                                    .isDeleted
                                                            ? () => _startEdit(
                                                                message,
                                                              )
                                                            : null,
                                                        onDelete:
                                                            isMe &&
                                                                !message
                                                                    .isDeleted
                                                            ? () =>
                                                                  _deleteMessage(
                                                                    message.id,
                                                                  )
                                                            : null,
                                                      ),
                                                    ],
                                                  );
                                                }),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                          ChatInputBar(
                            controller: _messageController,
                            isSending: chatProvider.isSending,
                            isEditing: _editingMessageId != null,
                            pendingAttachment: _pendingAttachment,
                            onSend: () => _sendMessage(conversation),
                            onPickImage: _pickImage,
                            onPickFile: _pickFile,
                            onCancelEdit: () {
                              setState(() {
                                _editingMessageId = null;
                                _messageController.clear();
                              });
                            },
                            onRemoveAttachment: () {
                              setState(() => _pendingAttachment = null);
                            },
                            onEmojiTap: () {
                              const emoji = '\u{1F60A}';
                              final selection = _messageController.selection;
                              final value = _messageController.text;
                              final safeOffset = selection.isValid
                                  ? selection.start
                                  : value.length;
                              final nextValue = value.replaceRange(
                                safeOffset,
                                safeOffset,
                                emoji,
                              );
                              _messageController.value = TextEditingValue(
                                text: nextValue,
                                selection: TextSelection.collapsed(
                                  offset: safeOffset + emoji.length,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _isImageFile(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    return normalized.endsWith('.png') ||
        normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.webp');
  }

  String _inferMimeType(String fileName, {required String fallback}) {
    final normalized = fileName.trim().toLowerCase();
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    if (normalized.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (normalized.endsWith('.doc')) {
      return 'application/msword';
    }
    if (normalized.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (normalized.endsWith('.xls')) {
      return 'application/vnd.ms-excel';
    }
    if (normalized.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (normalized.endsWith('.ppt')) {
      return 'application/vnd.ms-powerpoint';
    }
    if (normalized.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (normalized.endsWith('.zip')) {
      return 'application/zip';
    }
    return fallback;
  }
}

class _ConversationHeader extends StatelessWidget {
  final String title;
  final UserModel? otherUser;
  final String otherUserId;
  final String otherRole;
  final String fallbackName;
  final VoidCallback onBack;
  final VoidCallback onOpenProfile;
  final ValueChanged<String> onMenuSelected;
  final bool muted;
  final bool archived;

  const _ConversationHeader({
    required this.title,
    required this.otherUser,
    required this.otherUserId,
    required this.otherRole,
    required this.fallbackName,
    required this.onBack,
    required this.onOpenProfile,
    required this.onMenuSelected,
    required this.muted,
    required this.archived,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = otherUser?.isOnline ?? false;
    final presenceColor = isOnline
        ? ChatThemePalette.success
        : ChatThemePalette.textSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        gradient: ChatThemePalette.headerGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
        boxShadow: ChatThemeStyles.softShadow(0.08),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    ChatThemePalette.primaryDark,
                    ChatThemePalette.primary,
                    ChatThemePalette.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ToolbarButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: onOpenProfile,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ProfileAvatar(
                              user: otherUser,
                              userId: otherUserId,
                              radius: 22,
                              fallbackName: fallbackName,
                              role: otherRole,
                            ),
                            if (isOnline)
                              Positioned(
                                right: -1,
                                bottom: -1,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: ChatThemePalette.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: ChatThemeStyles.cardTitle(
                                  ChatThemePalette.primaryDark,
                                ).copyWith(fontSize: 16.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: presenceColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      ChatFormatters.presenceLabel(
                                        otherUser?.lastSeenAt,
                                        isOnline: isOnline,
                                      ),
                                      style: ChatThemeStyles.meta(
                                        presenceColor,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (muted) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.notifications_off_outlined,
                                      size: 14,
                                      color: ChatThemePalette.textSecondary,
                                    ),
                                  ],
                                  if (archived) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.archive_outlined,
                                      size: 14,
                                      color: ChatThemePalette.textSecondary,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                color: ChatThemePalette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: onMenuSelected,
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Text('View Profile', style: ChatThemeStyles.body()),
                  ),
                  PopupMenuItem<String>(
                    value: 'mute',
                    child: Text(
                      muted ? 'Unmute Chat' : 'Mute Chat',
                      style: ChatThemeStyles.body(),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'archive',
                    child: Text(
                      archived ? 'Unarchive Chat' : 'Archive Chat',
                      style: ChatThemeStyles.body(),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Delete Chat',
                      style: ChatThemeStyles.body(ChatThemePalette.error),
                    ),
                  ),
                ],
                child: const _ToolbarButton(icon: Icons.more_vert_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final String label;

  const _DateDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: ChatThemePalette.headerGradient,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: ChatThemePalette.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Text(
            label,
            style: ChatThemeStyles.meta(
              ChatThemePalette.primary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ToolbarButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ChatThemePalette.border),
            boxShadow: ChatThemeStyles.softShadow(0.04),
          ),
          child: Icon(icon, color: ChatThemePalette.primaryDark, size: 18),
        ),
      ),
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _BackgroundOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyConversationState extends StatelessWidget {
  final String contextLabel;
  final String otherName;

  const _EmptyConversationState({
    required this.contextLabel,
    required this.otherName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ChatThemePalette.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: ChatThemePalette.border),
            boxShadow: ChatThemeStyles.softShadow(0.04),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: ChatThemePalette.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: ChatThemePalette.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Say hello to $otherName',
                textAlign: TextAlign.center,
                style: ChatThemeStyles.cardTitle().copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Your next message will appear here instantly once it is sent.',
                textAlign: TextAlign.center,
                style: ChatThemeStyles.body(ChatThemePalette.textSecondary),
              ),
              if (contextLabel.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ChatThemePalette.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    contextLabel.trim(),
                    textAlign: TextAlign.center,
                    style: ChatThemeStyles.meta(
                      ChatThemePalette.primary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
