import 'package:cineconnect/core/core_contract/screens/contract_viewer_screen.dart';
import 'package:cineconnect/core/core_booking/screens/booking_chat_screen.dart';
import 'package:cineconnect/core/core_payment/screens/payment_proof_screen.dart';
import 'package:cineconnect/core/core_payment/screens/receipts_ledger_screen.dart';
import 'package:cineconnect/core/core_safety/screens/ratings_review_screen.dart';
import 'package:cineconnect/core/core_safety/screens/report_block_screen.dart';
import 'package:cineconnect/core/core_ui/core_routes.dart';
import 'package:cineconnect/core/core_ui/screens/notification_center_screen.dart';
import 'package:cineconnect/core/payments/payment_models.dart';
import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = ThemeController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ThemeControllerProvider(
        controller: controller,
        child: MaterialApp(theme: AppTheme.dark, home: child),
      ),
    );
  }

  test('ledger entries preserve real receipt identity', () {
    final entry = LedgerEntryDto.fromJson({
      'public_id': 'LED-001',
      'booking_id': 'BKG-001',
      'transaction_id': 'TXN-001',
      'entry_type': 'booking_payment',
      'direction': 'debit',
      'amount_minor': 250000,
      'currency': 'PKR',
      'status': 'posted',
      'occurred_at': '2026-10-10T16:30:00Z',
      'description': 'Project payment',
      'receipt_id': 'RCT-001',
      'receipt_number': 'CC-RCT-2026-001',
    });

    final row = entry.toLedgerRow();
    expect(row.receiptId, 'RCT-001');
    expect(row.receiptNumber, 'CC-RCT-2026-001');
    expect(row.transactionId, 'TXN-001');
  });

  test('contract links retain identity across browser refreshes', () {
    expect(CoreRoutes.contractDetail('CON-001'), '/contract/CON-001');
    expect(
      CoreRoutes.contractDetail('DEMO-CTR-001'),
      '/contract/DEMO-CTR-001',
    );
    expect(
      CoreRoutes.contractDetail('CON-001', addendum: true),
      '/contract/CON-001?addendum=true',
    );
  });

  testWidgets('contract viewer never substitutes a demo contract',
      (tester) async {
    await pumpScreen(tester, const ContractViewerScreen());
    await tester.pumpAndSettle();

    expect(find.text('Choose a live contract'), findsOneWidget);
    expect(find.text('Actor Booking Agreement'), findsNothing);
    expect(find.textContaining('OTP'), findsNothing);
  });

  testWidgets('ledger without a live payment scope stays honestly empty',
      (tester) async {
    await pumpScreen(tester, const ReceiptsLedgerScreen());
    await tester.pumpAndSettle();

    expect(find.text('No ledger rows'), findsOneWidget);
    expect(find.text('TVC Shoot — Lahore'), findsNothing);
    expect(find.textContaining('simulated'), findsNothing);
  });

  testWidgets('payment proof never substitutes a fake booking or payee',
      (tester) async {
    await pumpScreen(tester, const PaymentProofUploadScreen());
    await tester.pumpAndSettle();

    expect(find.text('No live milestone selected'), findsOneWidget);
    expect(find.text('TVC Shoot — Lahore'), findsNothing);
    expect(find.textContaining('Ali Khan'), findsNothing);
    expect(find.textContaining('BK-2048'), findsNothing);
  });

  testWidgets('booking chat requires a live conversation', (tester) async {
    await pumpScreen(tester, const BookingChatScreen());
    await tester.pumpAndSettle();

    expect(find.text('Choose a live booking conversation'), findsOneWidget);
    expect(find.text('TVC Shoot — Lahore'), findsNothing);
    expect(find.textContaining('Under Negotiation'), findsNothing);
  });

  testWidgets('notification center never falls back to preview records',
      (tester) async {
    await pumpScreen(tester, const NotificationCenterScreen());
    await tester.pumpAndSettle();

    expect(find.text('No notifications'), findsOneWidget);
    expect(find.textContaining('preview examples'), findsNothing);
    expect(find.text('Contract ready for signature'), findsNothing);
  });

  testWidgets('review and report routes require live context', (tester) async {
    await pumpScreen(tester, const RatingsReviewScreen());
    await tester.pumpAndSettle();
    expect(find.text('Choose a completed booking'), findsOneWidget);
    expect(find.textContaining('Ali Khan'), findsNothing);

    await pumpScreen(tester, const ReportBlockScreen());
    await tester.pumpAndSettle();
    expect(find.text('No live report target selected'), findsOneWidget);
    expect(find.textContaining('Ali Khan'), findsNothing);
    expect(find.text('Evidence attachment'), findsNothing);
  });
}
