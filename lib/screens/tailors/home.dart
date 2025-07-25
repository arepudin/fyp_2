import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/supabase.dart';
import 'package:fyp_2/screens/sign_in.dart';

// Main Screen Widget (No Changes Here)
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
    _tabController = TabController(length: 2, vsync: this);
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
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Manage Orders'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Manage Stock'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ManageOrdersView(),
          ManageStockView(),
        ],
      ),
    );
  }
}


// --- View for Managing Orders (This code is already correct) ---
class ManageOrdersView extends StatefulWidget {
  const ManageOrdersView({super.key});

  @override
  State<ManageOrdersView> createState() => _ManageOrdersViewState();
}

class _ManageOrdersViewState extends State<ManageOrdersView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await supabase
          .from('orders_with_details')
          .select()
          .order('order_date', ascending: false);
      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error fetching orders: $e"),
          backgroundColor: Colors.red,
        ));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await supabase.from('orders').update({'status': newStatus}).eq('id', orderId);
      
      final index = _orders.indexWhere((order) => order['id'] == orderId);
      if (index != -1) {
        setState(() {
          _orders[index]['status'] = newStatus;
        });
      }

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order status updated to $newStatus'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error updating status: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
  
  void _showStatusDialog(String orderId, String currentStatus) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Update Order Status'),
      content: DropdownButton<String>(
        isExpanded: true,
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

  Widget _getStatusChip(String status) {
    Color chipColor;
    Color textColor = Colors.black87;
    switch (status) {
      case 'Processing':
        chipColor = Colors.blue.shade100;
        break;
      case 'Completed':
        chipColor = Colors.green.shade100;
        break;
      case 'Cancelled':
        chipColor = Colors.red.shade100;
        break;
      case 'Pending':
      default:
        chipColor = Colors.orange.shade100;
        break;
    }
    return Chip(
      label: Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('No orders found.'));
    }
    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(8.0),
        itemCount: _orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final order = _orders[index];
          final orderDate = order['order_date'] != null
              ? DateFormat.yMMMd().format(DateTime.parse(order['order_date']))
              : 'N/A';
          final widthCm = order['width'];
          final heightCm = order['height'];
          final widthMeters = widthCm != null ? (widthCm / 100).toStringAsFixed(2) : '?';
          final heightMeters = heightCm != null ? (heightCm / 100).toStringAsFixed(2) : '?';

          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['curtain_name'] ?? 'Unknown Curtain',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(Icons.person, order['user_full_name'] ?? 'N/A'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.phone, order['phone_number'] ?? 'No phone provided'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.location_on, order['address'] ?? 'No address provided', maxLines: 2),
                  const Divider(height: 20),
                  _buildInfoRow(Icons.straighten, 'Measurements: $widthMeters m (W) x $heightMeters m (H)'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today, 'Ordered on: $orderDate'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _getStatusChip(order['status'] ?? 'Pending'),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showStatusDialog(order['id'], order['status']),
                        tooltip: 'Update Status',
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


// --- View for Managing Stock (This code is already correct) ---
class ManageStockView extends StatefulWidget {
  const ManageStockView({super.key});

  @override
  State<ManageStockView> createState() => _ManageStockViewState();
}

class _ManageStockViewState extends State<ManageStockView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allCurtains = [];
  List<Map<String, dynamic>> _displayedCurtains = [];
  
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchCurtains();
    _searchController.addListener(() {
      _filterCurtains();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurtains() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await supabase.from('curtains').select().order('name');
      _allCurtains = List<Map<String, dynamic>>.from(response);
      _filterCurtains();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching data: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterCurtains() {
    List<Map<String, dynamic>> filteredList = List.from(_allCurtains);
    if (_activeFilter == 'In Stock') {
      filteredList = filteredList.where((c) => c['in_stock'] == true).toList();
    } else if (_activeFilter == 'Out of Stock') {
      filteredList = filteredList.where((c) => c['in_stock'] == false).toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filteredList = filteredList.where((c) {
        return c['name'].toLowerCase().contains(query);
      }).toList();
    }
    setState(() {
      _displayedCurtains = filteredList;
    });
  }
  
  Future<void> _updateStockStatus(String curtainId, bool newStockStatus) async {
    await supabase.from('curtains').update({'in_stock': newStockStatus}).eq('id', curtainId);
    await _fetchCurtains(); 
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by curtain name',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            children: ['All', 'In Stock', 'Out of Stock'].map((filter) {
              return FilterChip(
                label: Text(filter),
                selected: _activeFilter == filter,
                onSelected: (isSelected) {
                  if (isSelected) {
                    setState(() {
                      _activeFilter = filter;
                    });
                    _filterCurtains();
                  }
                },
                selectedColor: Theme.of(context).primaryColor.withAlpha(50),
              );
            }).toList(),
          ),
          const Divider(height: 20, thickness: 1),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_displayedCurtains.isEmpty)
            const Expanded(
              child: Center(child: Text('No curtains match your criteria.')),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _displayedCurtains.length,
                itemBuilder: (context, index) {
                  final curtain = _displayedCurtains[index];
                  return SwitchListTile(
                    title: Text(curtain['name']),
                    subtitle: Text(
                      curtain['in_stock'] ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        color: curtain['in_stock'] ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: curtain['in_stock'],
                    onChanged: (newValue) {
                      _updateStockStatus(curtain['id'], newValue);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}