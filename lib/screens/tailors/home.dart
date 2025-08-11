import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fyp_2/config/app_sizes.dart';
import 'package:fyp_2/config/app_strings.dart';
import 'package:fyp_2/constants/supabase.dart';
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
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GoogleSignInScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tailorDashboardTitle),
        actions: [IconButton(onPressed: _signOut, icon: const Icon(Icons.logout))],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: AppStrings.manageOrdersTab),
            Tab(icon: Icon(Icons.inventory_2), text: AppStrings.manageStockTab),
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

// --- View for Managing Orders ---
class ManageOrdersView extends StatefulWidget {
  const ManageOrdersView({super.key});

  @override
  State<ManageOrdersView> createState() => _ManageOrdersViewState();
}

class _ManageOrdersViewState extends State<ManageOrdersView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  // Define order statuses in one place
  final List<String> _orderStatuses = [
    AppStrings.statusPending,
    AppStrings.statusProcessing,
    AppStrings.statusCompleted,
    AppStrings.statusCancelled,
  ];

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await supabase.from('orders_with_details').select().order('order_date', ascending: false);
      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppStrings.errorFetchingOrders}$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await supabase.from('orders').update({'status': newStatus}).eq('id', orderId);
      final index = _orders.indexWhere((order) => order['id'] == orderId);
      if (index != -1) {
        setState(() => _orders[index]['status'] = newStatus);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppStrings.orderStatusUpdated}$newStatus'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppStrings.errorUpdatingStatus}$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  void _showStatusDialog(String orderId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.updateOrderStatusTitle),
        content: DropdownButton<String>(
          isExpanded: true,
          value: currentStatus,
          items: _orderStatuses.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
          onChanged: (newStatus) {
            if (newStatus != null) {
              Navigator.of(context).pop();
              _updateOrderStatus(orderId, newStatus);
            }
          },
        ),
      ),
    );
  }

  Widget _getStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case AppStrings.statusProcessing: chipColor = Colors.blue.shade100; break;
      case AppStrings.statusCompleted: chipColor = Colors.green.shade100; break;
      case AppStrings.statusCancelled: chipColor = Colors.red.shade100; break;
      case AppStrings.statusPending:
      default: chipColor = Colors.orange.shade100; break;
    }
    return Chip(
      label: Text(status, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_orders.isEmpty) return const Center(child: Text(AppStrings.noOrdersFound));

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.p8),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => gapH8,
        itemBuilder: (_, index) {
          final order = _orders[index];
          final orderDate = order['order_date'] != null
              ? DateFormat.yMMMd().format(DateTime.parse(order['order_date']))
              : AppStrings.statusNotAvailable;
          final widthCm = order['width'];
          final heightCm = order['height'];
          final widthMeters = widthCm != null ? (widthCm / 100).toStringAsFixed(2) : '?';
          final heightMeters = heightCm != null ? (heightCm / 100).toStringAsFixed(2) : '?';
          final measurements = '${AppStrings.measurementsLabel}$widthMeters${AppStrings.widthUnit}$heightMeters${AppStrings.heightUnit}';

          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p12)),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order['curtain_name'] ?? AppStrings.statusNotAvailable, style: Theme.of(context).textTheme.titleLarge),
                  const Divider(height: AppSizes.p20),
                  _buildInfoRow(Icons.person, order['user_full_name'] ?? AppStrings.statusNotAvailable),
                  gapH8,
                  _buildInfoRow(Icons.phone, order['phone_number'] ?? AppStrings.noPhoneProvided),
                  gapH8,
                  _buildInfoRow(Icons.location_on, order['address'] ?? AppStrings.noAddressProvided, maxLines: 2),
                  const Divider(height: AppSizes.p20),
                  _buildInfoRow(Icons.straighten, measurements),
                  gapH8,
                  _buildInfoRow(Icons.calendar_today, '${AppStrings.orderedOnLabel}$orderDate'),
                  gapH16,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _getStatusChip(order['status'] ?? AppStrings.statusPending),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showStatusDialog(order['id'], order['status']),
                        tooltip: AppStrings.updateStatusTooltip,
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
        gapW12,
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium, maxLines: maxLines, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// --- View for Managing Stock ---
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
  String _activeFilter = AppStrings.filterAll;
  late final List<String> _filters;

  @override
  void initState() {
    super.initState();
    _filters = [AppStrings.filterAll, AppStrings.filterInStock, AppStrings.filterOutOfStock];
    _fetchCurtains();
    _searchController.addListener(_filterCurtains);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurtains() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase.from('curtains').select().order('name');
      _allCurtains = List<Map<String, dynamic>>.from(response);
      _filterCurtains();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppStrings.errorFetchingData}$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterCurtains() {
    List<Map<String, dynamic>> filteredList = List.from(_allCurtains);
    if (_activeFilter == AppStrings.filterInStock) {
      filteredList = filteredList.where((c) => c['in_stock'] == true).toList();
    } else if (_activeFilter == AppStrings.filterOutOfStock) {
      filteredList = filteredList.where((c) => c['in_stock'] == false).toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filteredList = filteredList.where((c) => c['name'].toLowerCase().contains(query)).toList();
    }
    setState(() => _displayedCurtains = filteredList);
  }

  Future<void> _updateStockStatus(String curtainId, bool newStockStatus) async {
    await supabase.from('curtains').update({'in_stock': newStockStatus}).eq('id', curtainId);
    await _fetchCurtains();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSizes.p8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: AppStrings.searchByCurtainName,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.p12)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: _searchController.clear)
                  : null,
            ),
          ),
          gapH10,
          Wrap(
            spacing: AppSizes.p8,
            children: _filters.map((filter) {
              return FilterChip(
                label: Text(filter),
                selected: _activeFilter == filter,
                onSelected: (isSelected) {
                  if (isSelected) {
                    setState(() => _activeFilter = filter);
                    _filterCurtains();
                  }
                },
                selectedColor: theme.colorScheme.primary.withAlpha(50),
              );
            }).toList(),
          ),
          const Divider(height: AppSizes.p20, thickness: 1),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_displayedCurtains.isEmpty)
            const Expanded(child: Center(child: Text(AppStrings.noCurtainsFound)))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _displayedCurtains.length,
                itemBuilder: (_, index) {
                  final curtain = _displayedCurtains[index];
                  final bool isInStock = curtain['in_stock'];
                  return SwitchListTile(
                    title: Text(curtain['name']),
                    subtitle: Text(
                      isInStock ? AppStrings.inStock : AppStrings.outOfStock,
                      style: TextStyle(
                        color: isInStock ? Colors.green.shade700 : theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: isInStock,
                    onChanged: (newValue) => _updateStockStatus(curtain['id'], newValue),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}