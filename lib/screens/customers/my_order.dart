// lib/screens/my_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add 'intl' package to pubspec.yaml for date formatting
import '../../constants/supabase.dart';
import '../../config/theme_config.dart';

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
      if (user == null) {
        throw 'You must be logged in to see your orders.';
      }

      // This is the key: A single query to fetch orders and JOIN related data.
      // Supabase magically fetches the full objects from 'curtains' and 'measurements'
      // because of the foreign key relationships you created.
      final response = await supabase
          .from('orders')
          .select('*, curtains(*), measurements(*)')
          .eq('user_id', user.id)
          .order('order_date', ascending: false); // Show most recent orders first

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load orders: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryRed = ThemeConfig.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _buildBody(primaryRed),
    );
  }

  Widget _buildBody(Color primaryRed) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryRed));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: primaryRed)));
    }
    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "You haven't placed any orders yet.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: primaryRed,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          return _OrderCard(orderData: _orders[index]);
        },
      ),
    );
  }
}

// Custom widget for displaying a single order card
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const _OrderCard({required this.orderData});
  
  // Helper to get a color based on status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Processing':
        return Colors.blue.shade700;
      case 'Completed':
        return Colors.green.shade700;
      case 'Cancelled':
        return Colors.red.shade700;
      case 'Pending':
      default:
        return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final curtain = orderData['curtains'] ?? {};
    final measurement = orderData['measurements'] ?? {};
    final orderStatus = orderData['status'] ?? 'Pending';
    final orderDate = DateTime.parse(orderData['order_date']);

    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Order ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${(orderData['id'] as String).substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getStatusColor(orderStatus),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    orderStatus,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Main Content: Image and Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    curtain['image_url'] ?? 'https://placehold.co/400/ccc/ccc?text=N/A',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image, size: 90),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curtain['name'] ?? 'Curtain Not Found',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Size: ${measurement['window_width']} x ${measurement['window_height']} cm',
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                       Text(
                        'Placed on: ${DateFormat.yMMMd().format(orderDate)}',
                         style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
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