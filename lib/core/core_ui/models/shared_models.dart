import 'package:flutter/material.dart';

enum VerificationStatus { pending, needsResubmission, approved }

enum CoreNotificationCategory { bookings, payments, contracts, system }

enum LedgerDirection { incoming, outgoing }

enum LedgerStatus {
  notPaid,
  pendingVerification,
  verified,
  partiallyPaid,
  released,
  refunded,
  disputed,
  closed,
}

enum ChatMessageType { text, image, pdf, voice, decision }

class CineRole {
  final IconData icon;
  final String name;
  final String description;

  const CineRole({
    required this.icon,
    required this.name,
    required this.description,
  });
}

class CoreNotification {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final CoreNotificationCategory category;
  final String routeName;
  final bool unread;

  const CoreNotification({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.category,
    required this.routeName,
    required this.unread,
  });
}

class ChatMessage {
  final String? id;
  final String sender;
  final String message;
  final String time;
  final bool mine;
  final ChatMessageType type;
  final bool pinned;

  const ChatMessage({
    this.id,
    required this.sender,
    required this.message,
    required this.time,
    required this.mine,
    this.type = ChatMessageType.text,
    this.pinned = false,
  });
}

class ContractClause {
  final String title;
  final String value;
  final bool highlighted;

  const ContractClause({
    required this.title,
    required this.value,
    this.highlighted = true,
  });
}

class PaymentMilestone {
  final String name;
  final int amount;

  const PaymentMilestone({
    required this.name,
    required this.amount,
  });
}

class LedgerRowData {
  final String projectName;
  final String bookingId;
  final String milestone;
  final int amount;
  final LedgerDirection direction;
  final LedgerStatus status;
  final String date;
  final String receiptId;
  final String transactionId;

  const LedgerRowData({
    required this.projectName,
    required this.bookingId,
    required this.milestone,
    required this.amount,
    required this.direction,
    required this.status,
    required this.date,
    required this.receiptId,
    required this.transactionId,
  });
}

class SettingsToggleData {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;

  const SettingsToggleData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
  });
}
