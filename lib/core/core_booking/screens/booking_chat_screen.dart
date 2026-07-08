import 'package:flutter/material.dart';

import '../../core_ui/core_routes.dart';
import '../../core_ui/mock_data/shared_mock_data.dart';
import '../../core_ui/models/shared_models.dart';
import '../../core_ui/widgets/core_widgets.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';

class BookingChatScreen extends StatefulWidget {
  const BookingChatScreen({super.key});

  @override
  State<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends State<BookingChatScreen> {
  final _composer = TextEditingController();
  late final List<ChatMessage> _messages = List.of(SharedMockData.chatMessages);
  bool _securedBooking = false;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  String _maskPhoneNumbers(String value) {
    if (_securedBooking) return value;
    return value.replaceAllMapped(
      RegExp(r'(\+?92|0)?3\d{9}'),
      (match) => '03XX-XXXXXXX',
    );
  }

  void _send() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          sender: 'You',
          message: _maskPhoneNumbers(text),
          time: 'Now',
          mine: true,
        ),
      );
      _composer.clear();
    });
  }

  void _messageActions(ChatMessage message) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageActionsSheet(
        onPin: () {
          Navigator.pop(context);
          showCoreSnack(context, 'Decision pinned');
        },
        onAddendum: () {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            CoreRoutes.contract,
            arguments: {'addendum': true},
          );
        },
        onReport: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, CoreRoutes.report);
        },
        onCopy: () {
          Navigator.pop(context);
          showCoreSnack(context, 'Copied: ${message.message}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      scrollable: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          _contextHeader(context),
          const SizedBox(height: 12),
          _pinnedSection(),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
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

  Widget _contextHeader(BuildContext context) {
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
                      'TVC Shoot — Lahore',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: colors.textPrimary,
                        fontSize: 21,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booking ID: BK-2048',
                      style: AppTextStyles.caption
                          .copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _securedBooking,
                activeThumbColor: colors.goldMid,
                onChanged: (value) => setState(() => _securedBooking = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              StatusBadge(
                  label: 'Under Negotiation', tone: CoreStatusTone.warning),
              StatusBadge(label: 'Contract: Draft', tone: CoreStatusTone.info),
              StatusBadge(
                  label: 'Payment: Not Paid', tone: CoreStatusTone.neutral),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.description_outlined,
                  label: 'View Contract',
                  compact: true,
                  onTap: () =>
                      Navigator.pushNamed(context, CoreRoutes.contract),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.payments_outlined,
                  label: 'View Payment',
                  compact: true,
                  onTap: () =>
                      Navigator.pushNamed(context, CoreRoutes.paymentProof),
                ),
              ),
              const SizedBox(width: 8),
              CoreIconButton(
                icon: Icons.flag_outlined,
                tooltip: 'Report',
                onTap: () => Navigator.pushNamed(context, CoreRoutes.report),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pinnedSection() {
    final pinned = _messages.where((message) => message.pinned).toList();
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
              pinned.first.message.replaceFirst('Pinned: ', ''),
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
          CoreIconButton(
            icon: Icons.attach_file_rounded,
            tooltip: 'Attach',
            onTap: () => showCoreSnack(context, 'Attachment picker simulated'),
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
            onTap: () => setState(() {
              _messages.add(
                const ChatMessage(
                  sender: 'You',
                  message: 'Voice note · 0:08',
                  time: 'Now',
                  mine: true,
                  type: ChatMessageType.voice,
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          CoreIconButton(
            icon: Icons.send_rounded,
            tooltip: 'Send',
            onTap: _send,
          ),
        ],
      ),
    );
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
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
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
