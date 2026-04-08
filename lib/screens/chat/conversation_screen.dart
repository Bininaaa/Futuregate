import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/ai_message_service.dart';
import '../../services/public_profile_service.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/chat/chat_formatters.dart';
import '../../widgets/chat/chat_confirmation_dialog.dart';
import '../../widgets/chat/chat_input_bar.dart';
import '../../widgets/chat/chat_message_bubble.dart';
import '../../widgets/chat/chat_theme.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_feedback.dart';
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

  final AiMessageService _aiService = AiMessageService();
  bool _isAiProcessing = false;

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
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

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
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (!mounted) return;

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
      if (text.isEmpty) return;

      await provider.editMessage(
        conversationId: widget.conversationId,
        messageId: _editingMessageId!,
        newText: text,
      );

      if (!mounted || provider.error != null) return;

      setState(() {
        _editingMessageId = null;
        _messageController.clear();
      });
      return;
    }

    if (auth == null || (text.isEmpty && attachment == null)) return;

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

    if (!mounted || provider.error == null) return;

    setState(() => _pendingAttachment = draftAttachment);
    _messageController.text = draftText;
    _messageController.selection = TextSelection.collapsed(
      offset: _messageController.text.length,
    );
  }

  Future<void> _handleAiTask(String task, {String? targetLanguage}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      context.showAppSnackBar(
        'Write a message before using AI tools.',
        title: 'Message required',
        type: AppFeedbackType.warning,
      );
      return;
    }

    setState(() => _isAiProcessing = true);
    try {
      final result = await _aiService.processMessage(
        task: task,
        text: text,
        targetLanguage: targetLanguage,
      );
      if (!mounted) return;
      _messageController.text = result;
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(
        _readableError(e.toString()),
        title: 'AI action unavailable',
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) setState(() => _isAiProcessing = false);
    }
  }

  void _showTranslateSheet() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      context.showAppSnackBar(
        'Write a message before choosing a translation.',
        title: 'Message required',
        type: AppFeedbackType.warning,
      );
      return;
    }

    showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Translate to',
                style: ChatThemeStyles.cardTitle().copyWith(fontSize: 16),
              ),
              const SizedBox(height: 14),
              _TranslateOption(
                label: 'Arabic',
                flag: '\u{1F1E9}\u{1F1FF}',
                onTap: () => Navigator.pop(ctx, 'Arabic'),
              ),
              _TranslateOption(
                label: 'French',
                flag: '\u{1F1EB}\u{1F1F7}',
                onTap: () => Navigator.pop(ctx, 'French'),
              ),
              _TranslateOption(
                label: 'English',
                flag: '\u{1F1EC}\u{1F1E7}',
                onTap: () => Navigator.pop(ctx, 'English'),
              ),
            ],
          ),
        ),
      ),
    ).then((language) {
      if (language != null) {
        _handleAiTask('translate', targetLanguage: language);
      }
    });
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

    if (confirm != true || !mounted) return;

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

    if (_lastHandledError == error) return;

    _lastHandledError = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.showAppSnackBar(
        _readableError(error),
        title: 'Message unavailable',
        type: AppFeedbackType.error,
      );
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
    if (userId.trim().isEmpty) return;

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
    if (auth == null) return;

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

      if (confirmed != true || !mounted) return;
    }

    await provider.archiveConversation(
      conversationId: widget.conversationId,
      userId: auth.uid,
      archived: archived,
    );

    if (!mounted || provider.error != null) return;

    context.showAppSnackBar(
      archived
          ? 'This conversation has been moved to Archived.'
          : 'This conversation is back in your inbox.',
      title: archived ? 'Conversation archived' : 'Conversation restored',
      type: AppFeedbackType.success,
    );

    if (archived) Navigator.pop(context);
  }

  Future<void> _toggleMute(ConversationModel conversation) async {
    final auth = context.read<AuthProvider>().userModel;
    final provider = context.read<ChatProvider>();
    if (auth == null) return;

    final muted = !provider.isConversationMutedFor(conversation, auth.uid);
    await provider.muteConversation(
      conversationId: widget.conversationId,
      userId: auth.uid,
      muted: muted,
    );

    if (!mounted || provider.error != null) return;

    context.showAppSnackBar(
      muted
          ? 'Notifications for this chat are now muted.'
          : 'Chat notifications are active again.',
      title: muted ? 'Chat muted' : 'Chat unmuted',
      type: AppFeedbackType.info,
    );
  }

  Future<void> _deleteConversation(ConversationModel conversation) async {
    final auth = context.read<AuthProvider>().userModel;
    final provider = context.read<ChatProvider>();
    if (auth == null) return;

    final confirmed = await showChatConfirmationDialog(
      context,
      title: 'Delete conversation?',
      message:
          'Are you sure you want to delete this conversation? This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (confirmed != true || !mounted) return;

    await provider.deleteConversation(
      conversationId: widget.conversationId,
      userId: auth.uid,
    );
    if (!mounted || provider.error != null) return;

    context.showAppSnackBar(
      'The conversation has been deleted.',
      title: 'Conversation deleted',
      type: AppFeedbackType.success,
    );
    Navigator.pop(context);
  }

  String _resolveOtherRole(ConversationModel? conversation, UserModel? auth) {
    final currentUserId = auth?.uid ?? '';
    final fromConversation =
        conversation?.otherParticipantRole(currentUserId).trim() ?? '';
    if (fromConversation.isNotEmpty) return fromConversation;
    if (widget.otherRole.trim().isNotEmpty) return widget.otherRole.trim();
    return auth?.role == 'company' ? 'student' : 'company';
  }

  String _resolveContextLabel(ConversationModel? conversation) {
    final fromConversation = conversation?.contextLabel.trim() ?? '';
    if (fromConversation.isNotEmpty) return fromConversation;
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

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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

                final isOnline = otherUser?.isOnline ?? false;

                return SafeArea(
                  child: Column(
                    children: [
                      _ConversationHeader(
                        title: otherName,
                        otherUser: otherUser,
                        otherUserId: otherUserId,
                        otherRole: otherRole,
                        fallbackName: otherName,
                        isOnline: isOnline,
                        contextLabel: contextLabel,
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
                          if (value == 'archive' && conversation != null) {
                            _toggleArchive(conversation);
                            return;
                          }
                          if (value == 'delete' && conversation != null) {
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
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF8FAFC),
                          child: messages.isEmpty
                              ? _EmptyConversationState(
                                  contextLabel: contextLabel,
                                  otherName: otherName,
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    8,
                                    0,
                                    8,
                                  ),
                                  itemCount:
                                      messages.length +
                                      _dateDividerCount(messages),
                                  itemBuilder: (context, index) {
                                    final mapped = _mapIndexToMessage(
                                      messages,
                                      index,
                                    );
                                    if (mapped.isDivider) {
                                      return _DateDivider(
                                        label: mapped.dividerLabel!,
                                      );
                                    }

                                    final message = mapped.message!;
                                    final messageIndex = mapped.messageIndex!;
                                    final isMe =
                                        message.senderId == currentUserId;
                                    final isFirstInGroup =
                                        messageIndex == 0 ||
                                        messages[messageIndex - 1].senderId !=
                                            message.senderId;
                                    final isLastInGroup =
                                        messageIndex == messages.length - 1 ||
                                        messages[messageIndex + 1].senderId !=
                                            message.senderId;
                                    final showAvatar = isLastInGroup;

                                    return ChatMessageBubble(
                                      conversationId: widget.conversationId,
                                      message: message,
                                      isMe: isMe,
                                      isFirstInGroup: isFirstInGroup,
                                      isLastInGroup: isLastInGroup,
                                      showAvatar: showAvatar,
                                      otherUser: otherUser,
                                      otherUserId: otherUserId,
                                      otherRole: otherRole,
                                      fallbackName: otherName,
                                      onEdit: () => _startEdit(message),
                                      onDelete: () =>
                                          _deleteMessage(message.id),
                                    );
                                  },
                                ),
                        ),
                      ),
                      ChatInputBar(
                        controller: _messageController,
                        isSending: chatProvider.isSending,
                        isEditing: _editingMessageId != null,
                        isAiProcessing: _isAiProcessing,
                        showAiTools: auth?.role == 'student',
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
                        onEmojiTap: () {},
                        onAiFormalize: () => _handleAiTask('formal'),
                        onAiCorrect: () => _handleAiTask('correct'),
                        onAiTranslate: _showTranslateSheet,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  int _dateDividerCount(List<MessageModel> messages) {
    if (messages.isEmpty) return 0;
    int count = 1;
    for (int i = 1; i < messages.length; i++) {
      if (!ChatFormatters.isSameMessageDay(
        messages[i - 1].sentAt,
        messages[i].sentAt,
      )) {
        count++;
      }
    }
    return count;
  }

  _MappedItem _mapIndexToMessage(List<MessageModel> messages, int index) {
    int currentIndex = 0;
    String? lastDateLabel;

    for (int i = 0; i < messages.length; i++) {
      final dateLabel = messages[i].sentAt != null
          ? ChatFormatters.dayDividerLabel(messages[i].sentAt!.toDate())
          : '';
      if (dateLabel != lastDateLabel) {
        if (currentIndex == index) {
          return _MappedItem.divider(dateLabel);
        }
        lastDateLabel = dateLabel;
        currentIndex++;
      }

      if (currentIndex == index) {
        return _MappedItem.message(messages[i], i);
      }
      currentIndex++;
    }

    return _MappedItem.divider('');
  }

  String _inferMimeType(String fileName, {String fallback = ''}) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return fallback;
  }

  bool _isImageFile(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }
}

class _MappedItem {
  final bool isDivider;
  final String? dividerLabel;
  final MessageModel? message;
  final int? messageIndex;

  _MappedItem.divider(this.dividerLabel)
    : isDivider = true,
      message = null,
      messageIndex = null;

  _MappedItem.message(this.message, this.messageIndex)
    : isDivider = false,
      dividerLabel = null;
}

class _ConversationHeader extends StatelessWidget {
  final String title;
  final UserModel? otherUser;
  final String otherUserId;
  final String otherRole;
  final String fallbackName;
  final bool isOnline;
  final String contextLabel;
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
    required this.isOnline,
    required this.contextLabel,
    required this.onBack,
    required this.onOpenProfile,
    required this.onMenuSelected,
    required this.muted,
    required this.archived,
  });

  @override
  Widget build(BuildContext context) {
    final presenceColor = isOnline
        ? ChatThemePalette.success
        : ChatThemePalette.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: ChatThemePalette.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              color: ChatThemePalette.textPrimary,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onOpenProfile,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(
                    user: otherUser,
                    userId: otherUserId,
                    radius: 19,
                    fallbackName: fallbackName,
                    role: otherRole,
                  ),
                  if (isOnline)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: ChatThemePalette.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onOpenProfile,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: ChatThemeStyles.cardTitle().copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
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
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            ChatFormatters.presenceLabel(
                              otherUser?.lastSeenAt,
                              isOnline: isOnline,
                            ),
                            style: ChatThemeStyles.meta(presenceColor).copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (muted)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.notifications_off_outlined,
                              size: 13,
                              color: ChatThemePalette.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              color: ChatThemePalette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: ChatThemePalette.textSecondary,
                ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE8ECF4),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: ChatThemeStyles.meta(
              ChatThemePalette.textSecondary,
            ).copyWith(fontSize: 10.5, fontWeight: FontWeight.w600),
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
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ChatThemePalette.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: ChatThemePalette.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Say hello to $otherName',
              textAlign: TextAlign.center,
              style: ChatThemeStyles.cardTitle().copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send your first message to start the conversation.',
              textAlign: TextAlign.center,
              style: ChatThemeStyles.body(
                ChatThemePalette.textSecondary,
              ).copyWith(fontSize: 13, height: 1.5),
            ),
            if (contextLabel.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ChatThemePalette.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  contextLabel.trim(),
                  textAlign: TextAlign.center,
                  style: ChatThemeStyles.meta(
                    ChatThemePalette.primary,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TranslateOption extends StatelessWidget {
  final String label;
  final String flag;
  final VoidCallback onTap;

  const _TranslateOption({
    required this.label,
    required this.flag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              label,
              style: ChatThemeStyles.body().copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
