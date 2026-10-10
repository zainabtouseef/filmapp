import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import '../../auth/auth_controller.dart';
import '../../bookings/booking_models.dart' as booking_models;
import '../../bookings/bookings_controller.dart';
import '../../core_ui/core_routes.dart';
import '../../core_ui/models/shared_models.dart';
import '../../core_ui/widgets/core_widgets.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../../uploads/upload_repository.dart';

class BookingChatScreen extends StatefulWidget {
  final String? conversationId;

  const BookingChatScreen({super.key, this.conversationId});

  @override
  State<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends State<BookingChatScreen> {
  final _composer = TextEditingController();
  Future<booking_models.BookingConversation>? _conversationFuture;
  bool _contactUnlocked = false;
  bool _attaching = false;
  bool _sending = false;

  bool get _live => widget.conversationId?.trim().isNotEmpty ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_live) {
      final bookings = BookingsScope.maybeOf(context);
      if (bookings != null) {
        _conversationFuture ??=
            bookings.conversation(widget.conversationId!.trim());
      }
    }
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  String _maskPhoneNumbers(String value) {
    if (_contactUnlocked) return value;
    return value.replaceAllMapped(
      RegExp(r'(\+?92|0)?3\d{9}'),
      (match) => '03XX-XXXXXXX',
    );
  }

  void _send() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    if (!_live) {
      showCoreSnack(context, 'Open a live booking conversation first.');
      return;
    }
    _sendLive(text);
  }

  Future<void> _sendLive(String text) async {
    setState(() => _sending = true);
    try {
      await BookingsScope.of(context).sendMessage(
        conversationId: widget.conversationId!,
        body: _maskPhoneNumbers(text),
      );
      if (!mounted) return;
      _composer.clear();
      _refreshConversation();
    } catch (error) {
      if (mounted) showCoreSnack(context, 'Message not sent: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _refreshConversation() {
    setState(() {
      _conversationFuture =
          BookingsScope.of(context).conversation(widget.conversationId!);
    });
  }

  Future<void> _pickAttachment() async {
    if (!_live) {
      showCoreSnack(
          context, 'Attachments require a live booking conversation.');
      return;
    }
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      showCoreSnack(context, 'Sign in to attach a file.');
      return;
    }
    setState(() => _attaching = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'pdf',
          'mp3',
          'm4a',
          'aac',
          'wav',
        ],
        withData: true,
      );
      final file = picked?.files.single;
      final bytes = file?.bytes;
      if (file == null || bytes == null) return;
      if (bytes.length > 25 * 1024 * 1024) {
        throw StateError('Chat attachments must be 25 MB or smaller.');
      }
      final mimeType = _mimeFor(file.extension);
      final uploaded = await UploadRepository(auth.apiClient).uploadFile(
        purpose: 'project_document',
        file: PickedFileData(
          name: file.name,
          mimeType: mimeType,
          bytes: bytes,
        ),
      );
      if (!mounted) return;
      await BookingsScope.of(context).sendMessage(
        conversationId: widget.conversationId!,
        body: '',
        attachments: [
          booking_models.ConversationAttachmentInput(
            fileId: uploaded.publicId,
            attachmentType: mimeType.startsWith('image/')
                ? 'image'
                : mimeType.startsWith('audio/')
                    ? 'audio'
                    : 'file',
            caption: file.name,
          ),
        ],
      );
      if (!mounted) return;
      _refreshConversation();
      showCoreSnack(context, '${file.name} attached');
    } catch (error) {
      if (mounted) showCoreSnack(context, 'Attachment not sent: $error');
    } finally {
      if (mounted) setState(() => _attaching = false);
    }
  }

  void _messageActions(ChatMessage message) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageActionsSheet(
        onPin: () async {
          Navigator.pop(context);
          final id = message.id;
          if (id == null) return;
          try {
            await BookingsScope.of(this.context).pinMessage(id);
            if (!mounted) return;
            _refreshConversation();
            showCoreSnack(this.context, 'Decision pinned');
          } catch (error) {
            if (mounted) {
              showCoreSnack(this.context, 'Decision not pinned: $error');
            }
          }
        },
        onAddendum: () {
          Navigator.pop(context);
          showCoreSnack(
            this.context,
            'Open the related agreement from Contracts to request an addendum.',
          );
        },
        onReport: () {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            CoreRoutes.report,
            arguments: {
              'entity_type': 'conversation',
              'entity_id': widget.conversationId,
            },
          );
        },
        onCopy: () {
          Navigator.pop(context);
          Clipboard.setData(ClipboardData(text: message.message));
          showCoreSnack(context, 'Message copied');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_live) {
      if (_conversationFuture == null) {
        return const CoreScreenScaffold(
          child: CoreEmptyState(
            icon: Icons.forum_outlined,
            title: 'Conversation unavailable',
            message: 'Sign in again and reopen this chat from a live booking.',
          ),
        );
      }
      return FutureBuilder<booking_models.BookingConversation>(
        future: _conversationFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return CoreScreenScaffold(
              child: CoreEmptyState(
                icon: Icons.forum_outlined,
                title: 'Conversation could not be loaded',
                message: 'Check your connection and reopen the booking chat.',
                actionLabel: 'Retry',
                onAction: _refreshConversation,
              ),
            );
          }
          final conversation = snapshot.data;
          _contactUnlocked = conversation?.contactUnlocked ?? false;
          final currentUserId = AuthScope.maybeOf(context)?.user?.publicId;
          final messages = conversation == null
              ? const <ChatMessage>[]
              : conversation.messages.map(
                  (item) {
                    final attachments = item.attachments;
                    final attachment =
                        attachments.isEmpty ? null : attachments.first;
                    final attachmentLabel = attachments.isEmpty
                        ? ''
                        : attachments.length == 1
                            ? attachment!.file.originalName
                            : '${attachment!.file.originalName} +${attachments.length - 1} more';
                    final body = item.body?.trim() ?? '';
                    final displayText = [body, attachmentLabel]
                        .where((part) => part.isNotEmpty)
                        .join('\n');
                    final mime = attachment?.file.mimeType ?? '';
                    return ChatMessage(
                      id: item.publicId,
                      sender: item.sender.displayName,
                      message: displayText,
                      time: _relative(item.createdAt),
                      mine: item.sender.publicId == currentUserId,
                      pinned: item.pinned,
                      type: item.decisionType != null
                          ? ChatMessageType.decision
                          : mime.startsWith('image/')
                              ? ChatMessageType.image
                              : mime.startsWith('audio/')
                                  ? ChatMessageType.voice
                                  : attachments.isNotEmpty
                                      ? ChatMessageType.pdf
                                      : ChatMessageType.text,
                    );
                  },
                ).toList();
          return _chatScaffold(
            title: conversation?.title ?? 'Booking chat',
            bookingId: conversation?.bookingId ?? 'Live booking',
            messages: messages,
            bookingStatus: conversation?.bookingStatus,
            projectTitle: conversation?.projectTitle,
            contactUnlocked: conversation?.contactUnlocked ?? false,
            loading: snapshot.connectionState == ConnectionState.waiting,
          );
        },
      );
    }
    return const CoreScreenScaffold(
      child: CoreEmptyState(
        icon: Icons.forum_outlined,
        title: 'Choose a live booking conversation',
        message: 'Open chat from a booking or negotiation workspace.',
      ),
    );
  }

  Widget _chatScaffold({
    required String title,
    required String bookingId,
    required List<ChatMessage> messages,
    String? bookingStatus,
    String? projectTitle,
    bool contactUnlocked = false,
    bool loading = false,
  }) {
    return CoreScreenScaffold(
      scrollable: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          _contextHeader(
            context,
            title: title,
            bookingId: bookingId,
            bookingStatus: bookingStatus,
            projectTitle: projectTitle,
            contactUnlocked: contactUnlocked,
          ),
          const SizedBox(height: 12),
          _pinnedSection(messages),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: loading ? 1 : messages.length,
              itemBuilder: (context, index) {
                if (loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final message = messages[index];
                return GestureDetector(
                  onLongPress: () => _messageActions(message),
                  child: ChatBubble(message: message),
                );
              },
            ),
          ),
          _composerBar(context),
        ],
      ),
    );
  }

  Widget _contextHeader(
    BuildContext context, {
    required String title,
    required String bookingId,
    String? bookingStatus,
    String? projectTitle,
    required bool contactUnlocked,
  }) {
    final colors = context.appColors;
    return CoreGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: colors.textPrimary,
                        fontSize: 21,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        'Booking ID: $bookingId',
                        if (projectTitle?.trim().isNotEmpty ?? false)
                          projectTitle!.trim(),
                      ].join(' · '),
                      style: AppTextStyles.caption
                          .copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label:
                    contactUnlocked ? 'Contact unlocked' : 'Contact protected',
                tone: contactUnlocked
                    ? CoreStatusTone.success
                    : CoreStatusTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                label:
                    (bookingStatus ?? 'Live conversation').replaceAll('_', ' '),
                tone: bookingStatus == 'secured'
                    ? CoreStatusTone.success
                    : CoreStatusTone.info,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: CoreSecondaryButton(
              icon: Icons.flag_outlined,
              label: 'Report booking',
              compact: true,
              onTap: () => Navigator.pushNamed(
                context,
                CoreRoutes.report,
                arguments: {
                  'entity_type': 'booking',
                  'entity_id': bookingId,
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinnedSection(List<ChatMessage> messages) {
    final pinned = messages.where((message) => message.pinned).toList();
    if (pinned.isEmpty) return const SizedBox.shrink();
    return CoreGlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const StatusBadge(
            label: 'Pinned Decisions',
            icon: Icons.push_pin_outlined,
            tone: CoreStatusTone.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pinned.length > 1
                  ? '${pinned.first.message.replaceFirst('Pinned: ', '')}  ·  +${pinned.length - 1} more'
                  : pinned.first.message.replaceFirst('Pinned: ', ''),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composerBar(BuildContext context) {
    final colors = context.appColors;
    return CoreGlassCard(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        children: [
          if (_attaching)
            const SizedBox(
              width: 42,
              height: 42,
              child: Padding(
                padding: EdgeInsets.all(11),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            CoreIconButton(
              icon: Icons.attach_file_rounded,
              tooltip: 'Attach a file',
              onTap: _pickAttachment,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _composer,
              minLines: 1,
              maxLines: 4,
              style: AppTextStyles.body.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Message inside booking record',
                hintStyle:
                    AppTextStyles.caption.copyWith(color: colors.textTertiary),
                border: InputBorder.none,
              ),
            ),
          ),
          CoreIconButton(
            icon: Icons.mic_none_rounded,
            tooltip: 'Voice note',
            onTap: () => showCoreSnack(
              context,
              'Microphone recording is not available yet. Attach an audio file instead.',
            ),
          ),
          const SizedBox(width: 8),
          CoreIconButton(
            icon: Icons.send_rounded,
            tooltip: 'Send',
            onTap: _sending ? null : _send,
          ),
        ],
      ),
    );
  }

  String _relative(DateTime? date) {
    if (date == null) return 'now';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  String _mimeFor(String? extension) {
    return switch (extension?.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      'wav' => 'audio/wav',
      _ => 'application/octet-stream',
    };
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final align = message.mine ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = message.mine
        ? colors.goldMid.withValues(alpha: colors.isLight ? 0.18 : 0.22)
        : colors.surface.withValues(alpha: colors.isLight ? 0.72 : 0.38);
    return Align(
      alignment: align,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width * 0.78)
              .clamp(0, 460)
              .toDouble(),
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft: Radius.circular(message.mine ? 18 : 6),
            bottomRight: Radius.circular(message.mine ? 6 : 18),
          ),
          border: Border.all(
            color: message.type == ChatMessageType.decision
                ? colors.goldMid
                : colors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              message.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.sender,
              style: AppTextStyles.micro.copyWith(
                color: colors.goldDark,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            _MessageContent(message: message),
            const SizedBox(height: 6),
            Text(
              message.time,
              style: AppTextStyles.micro.copyWith(
                color: colors.textTertiary,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  final ChatMessage message;

  const _MessageContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final icon = switch (message.type) {
      ChatMessageType.image => Icons.image_outlined,
      ChatMessageType.pdf => Icons.picture_as_pdf_outlined,
      ChatMessageType.voice => Icons.graphic_eq_rounded,
      ChatMessageType.decision => Icons.push_pin_outlined,
      ChatMessageType.text => null,
    };
    if (icon == null) {
      return Text(
        message.message,
        style: AppTextStyles.body.copyWith(
          color: colors.textPrimary,
          height: 1.35,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        color: colors.background.withValues(alpha: 0.18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.goldDark),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message.message,
              style: AppTextStyles.label.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageActionsSheet extends StatelessWidget {
  final VoidCallback onPin;
  final VoidCallback onAddendum;
  final VoidCallback onReport;
  final VoidCallback onCopy;

  const _MessageActionsSheet({
    required this.onPin,
    required this.onAddendum,
    required this.onReport,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      decoration: BoxDecoration(
        gradient: colors.cardGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _action(context, Icons.push_pin_outlined, 'Pin Decision', onPin),
            _action(context, Icons.note_add_outlined,
                'Convert to Addendum Request', onAddendum),
            _action(context, Icons.flag_outlined, 'Report Message', onReport),
            _action(context, Icons.copy_rounded, 'Copy Text', onCopy),
          ],
        ),
      ),
    );
  }

  Widget _action(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final colors = context.appColors;
    return ListTile(
      leading: Icon(icon, color: colors.goldDark),
      title: Text(label,
          style: AppTextStyles.label.copyWith(color: colors.textPrimary)),
      onTap: onTap,
    );
  }
}
