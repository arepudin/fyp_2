import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fyp_2/config/app_sizes.dart';
import 'package:fyp_2/config/app_strings.dart';
import 'package:fyp_2/constants/supabase.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw AppStrings.errorMustBeLoggedIn;

      final response = await supabase
          .from('orders')
          .select('*, curtains(*), measurements(*)')
          .eq('user_id', user.id)
          .order('order_date', ascending: false);

      if (mounted) setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = '${AppStrings.errorFailedToLoadOrders}$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myOrdersTitle)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)));
    }
    if (_orders.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey),
          gapH16,
          Text(AppStrings.noOrdersYet, style: TextStyle(fontSize: 18, color: Colors.grey)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: theme.colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.p16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          return _OrderCard(orderData: _orders[index]);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  const _OrderCard({required this.orderData});
  
  Color _getStatusColor(String status) {
    switch (status) {
      case AppStrings.statusProcessing: return Colors.blue.shade700;
      case AppStrings.statusCompleted: return Colors.green.shade700;
      case AppStrings.statusCancelled: return Colors.red.shade700;
      case AppStrings.statusPending:
      default: return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final curtain = orderData['curtains'] ?? {};
    final measurement = orderData['measurements'] ?? {};
    final orderStatus = orderData['status'] ?? AppStrings.statusPending;
    final orderDate = DateTime.parse(orderData['order_date']);

    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppStrings.orderPrefix}${(orderData['id'] as String).substring(0, 8)}',
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p5),
                  decoration: BoxDecoration(color: _getStatusColor(orderStatus), borderRadius: BorderRadius.circular(AppSizes.p12)),
                  child: Text(orderStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: AppSizes.p24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.p12),
                  child: Image.network(
                    curtain['image_url'] ?? 'https://placehold.co/400/ccc/ccc?text=N/A',
                    width: 90, height: 90, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 90),
                  ),
                ),
                gapW16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(curtain['name'] ?? AppStrings.curtainNotFound, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      gapH8,
                      Text('${AppStrings.labelSize}${measurement['window_width']} x ${measurement['window_height']} cm', style: textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                      gapH4,
                      Text('${AppStrings.labelPlacedOn}${DateFormat.yMMMd().format(orderDate)}', style: textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}