import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPProjectRoomScreen extends StatelessWidget {
  const DPProjectRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feedItems = DirectorProducerDemoData.roomItems.take(6).toList();
    final fileItems = DirectorProducerDemoData.roomItems.skip(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.campaign_outlined,
          label: 'Broadcast',
          onTap: () => dpSnack(context, 'Broadcast composer simulated'),
        ),
        const SizedBox(height: 8),
        DPTwoColumn(
          left: DPSectionCard(
            title: 'Team Feed',
            icon: Icons.chat_bubble_outline_rounded,
            child: Column(
              children: [
                for (var i = 0; i < feedItems.length; i++)
                  _RoomFeedItem(
                    author: feedItems[i][0],
                    text: feedItems[i][1],
                    time: feedItems[i][2],
                    showDivider: i != feedItems.length - 1,
                  ),
              ],
            ),
          ),
          right: DPSectionCard(
            title: 'Files & Decisions',
            icon: Icons.folder_copy_outlined,
            child: Column(
              children: [
                for (var i = 0; i < fileItems.length; i++)
                  _RoomFileItem(
                    kind: fileItems[i][0],
                    title: fileItems[i][1],
                    status: fileItems[i][2],
                    showDivider: i != fileItems.length - 1,
                  ),
                const SizedBox(height: 8),
                DPHolographicButton(
                  label: 'Upload File',
                  icon: Icons.upload_file_rounded,
                  onTap: () => dpSnack(context, 'File upload queued'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomFeedItem extends StatelessWidget {
  final String author;
  final String text;
  final String time;
  final bool showDivider;

  const _RoomFeedItem({
    required this.author,
    required this.text,
    required this.time,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: colors.goldGlow.withValues(alpha: 0.18),
            child: Text(
              author.isEmpty ? '?' : author[0].toUpperCase(),
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dpText(context, author, strong: true),
                const SizedBox(height: 3),
                dpText(context, text),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RoomFileItem extends StatelessWidget {
  final String kind;
  final String title;
  final String status;
  final bool showDivider;

  const _RoomFileItem({
    required this.kind,
    required this.title,
    required this.status,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_outlined,
              size: 18, color: colors.textSecondary),
          const SizedBox(width: 9),
          Expanded(child: dpText(context, title, strong: true)),
          const SizedBox(width: 10),
          DPStatusChip(
            label: status,
            tone: kind == 'Decision' ? DpTone.success : DpTone.info,
          ),
        ],
      ),
    );
  }
}
