import 'package:flutter/material.dart';
import '../../constants/supabase.dart';
import 'package:fyp_2/screens/sign_in.dart';

class TailorDashboardScreen extends StatefulWidget {
  const TailorDashboardScreen({super.key});

  @override
  State<TailorDashboardScreen> createState() => _TailorDashboardScreenState();
}

class _TailorDashboardScreenState extends State<TailorDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // --- MODIFICATION START ---
    // The length is now 2 since we removed the "Customer Chats" tab.
    _tabController = TabController(length: 2, vsync: this);
    // --- MODIFICATION END ---
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if(mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GoogleSignInScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tailor Dashboard'),
        actions: [IconButton(onPressed: _signOut, icon: const Icon(Icons.logout))],
        bottom: TabBar(
          controller: _tabController,
          // --- MODIFICATION START ---
          // Removed the "Customer Chats" tab.
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Manage Orders'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Manage Stock'),
          ],
          // --- MODIFICATION END ---
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // The children now correctly correspond to the 2 tabs.
        children: const [
          ManageOrdersView(),
          ManageStockView(),
        ],
      ),
    );
  }
}


// --- View for Managing Orders ---
class ManageOrdersView extends StatefulWidget {
  const ManageOrdersView({super.key});

  @override
  State<ManageOrdersView> createState() => _ManageOrdersViewState();
}

class _ManageOrdersViewState extends State<ManageOrdersView> {
  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    // This now works because the 'orders_with_details' view exists.
    final response = await supabase
        .from('orders_with_details') // Query the view
        .select() // Select all columns from the view
        .order('order_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    // This remains unchanged, as we update the original 'orders' table.
    await supabase.from('orders').update({'status': newStatus}).eq('id', orderId);
    setState(() {}); // Refresh the list by re-fetching from the view
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order status updated to $newStatus'), backgroundColor: Colors.green));
    }
  }
  
  void _showStatusDialog(String orderId, String currentStatus) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Update Order Status'),
      content: DropdownButton<String>(
        value: currentStatus,
        items: ['Pending', 'Processing', 'Completed', 'Cancelled'].map((status) => 
          DropdownMenuItem(value: status, child: Text(status))).toList(),
        onChanged: (newStatus) {
          if (newStatus != null) {
            Navigator.of(context).pop();
            _updateOrderStatus(orderId, newStatus);
          }
        },
      ),
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // The error from the image will now be gone.
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            // Access the data directly from the "flat" structure of the view.
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(order['curtain_name'] ?? 'N/A'),
                subtitle: Text(
                  'By: ${order['user_full_name'] ?? 'N/A'}\nStatus: ${order['status']}'
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _showStatusDialog(order['id'], order['status']),
              ),
            );
          },
        );
      },
    );
  }
}


// --- View for Managing Stock (This widget remains unchanged) ---
class ManageStockView extends StatefulWidget {
  const ManageStockView({super.key});

  @override
  State<ManageStockView> createState() => _ManageStockViewState();
}

class _ManageStockViewState extends State<ManageStockView> {
  Future<List<Map<String, dynamic>>> _fetchCurtains() async {
    final response = await supabase.from('curtains').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<void> _updateStockStatus(String curtainId, bool newStockStatus) async {
    await supabase.from('curtains').update({'in_stock': newStockStatus}).eq('id', curtainId);
    setState(() {}); // Refresh the list
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchCurtains(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final curtains = snapshot.data!;
        return ListView.builder(
          itemCount: curtains.length,
          itemBuilder: (context, index) {
            final curtain = curtains[index];
            return SwitchListTile(
              title: Text(curtain['name']),
              subtitle: Text(curtain['in_stock'] ? 'In Stock' : 'Out of Stock', style: TextStyle(color: curtain['in_stock'] ? Colors.green : Colors.red)),
              value: curtain['in_stock'],
              onChanged: (newValue) {
                _updateStockStatus(curtain['id'], newValue);
              },
            );
          },
        );
      },
    );
  }
}