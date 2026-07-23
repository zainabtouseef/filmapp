part of '../super_admin_screens.dart';

class ListingsReviewQueueScreen extends StatelessWidget {
  const ListingsReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminListingsControlView(reviewOnly: true);
  }
}
