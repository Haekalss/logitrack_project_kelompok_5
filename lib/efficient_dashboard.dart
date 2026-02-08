import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kirimtrack/providers/offline_first_delivery_provider.dart';
import 'package:kirimtrack/providers/offline_user_profile_provider.dart';
import 'package:kirimtrack/widgets/connectivity_indicator.dart';
import 'package:kirimtrack/delivery_detail_page.dart';
import 'package:kirimtrack/delivery_task_model.dart';
import 'package:kirimtrack/theme.dart';

class EfficientDashboard extends StatefulWidget {
  const EfficientDashboard({super.key});

  @override
  State<EfficientDashboard> createState() => _EfficientDashboardState();
}

class _EfficientDashboardState extends State<EfficientDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize offline-first providers
      Provider.of<OfflineFirstDeliveryProvider>(context, listen: false).fetchTasks();
      Provider.of<OfflineUserProfileProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        toolbarHeight: 60,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 40,
                  child: Image.asset(
                    'assets/images/kirimtrack_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const ConnectivityIndicator(),
              ],
            ),
          ),
        ),
      ),
      body: Consumer2<OfflineFirstDeliveryProvider, OfflineUserProfileProvider>(
        builder: (context, deliveryProvider, profileProvider, child) {
          return _buildContent(context, deliveryProvider, theme);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, OfflineFirstDeliveryProvider provider, ThemeData theme) {
    if (provider.isLoading && provider.tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data pengiriman...'),
          ],
        ),
      );
    }

    if (provider.error != null && provider.tasks.isEmpty) {
      return _buildErrorView(provider, theme);
    }
    
    if (provider.tasks.isEmpty) {
      return _buildEmptyView(theme);
    }

    return _buildTaskList(provider, theme);
  }

  Widget _buildErrorView(OfflineFirstDeliveryProvider provider, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, 
                 size: 64, 
                 color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Koneksi Bermasalah',
                 style: theme.textTheme.titleLarge?.copyWith(
                   fontWeight: FontWeight.bold,
                 )),
            const SizedBox(height: 8),
            Text(provider.error ?? 'Terjadi kesalahan tidak diketahui',
                 textAlign: TextAlign.center,
                 style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.fetchTasks(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(OfflineFirstDeliveryProvider provider, ThemeData theme) {
    final allTasks = provider.tasks;
    
    if (allTasks.isEmpty) {
      return _buildEmptyView(theme);
    }

    // Filter tasks efficiently
    final filteredTasks = _getFilteredTasks(allTasks);
    
    return RefreshIndicator(
      onRefresh: () => provider.fetchTasks(),
      child: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: _buildSearchBar(theme),
          ),
          // Filter Chips
          SliverToBoxAdapter(
            child: _buildFilterChips(theme),
          ),
          // Tasks List
          SliverList.builder(
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              return _buildTaskItem(filteredTasks[index], theme);
            },
          ),
          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  List<DeliveryTask> _getFilteredTasks(List<DeliveryTask> allTasks) {
    var filtered = allTasks.where((task) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return task.title.toLowerCase().contains(query) ||
             task.id.toString().toLowerCase().contains(query);
    }).toList();

    switch (_selectedFilter) {
      case 'Selesai':
        return filtered.where((t) => t.isCompleted).toList();
      case 'Pending':
        return filtered.where((t) => !t.isCompleted).toList();
      default:
        return filtered;
    }
  }



  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Cari berdasarkan ID atau Judul...',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          icon: Icon(Icons.search, color: AppTheme.primaryBlue),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFilterChip('Semua', Icons.all_inclusive, theme),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', Icons.pending_actions, theme),
          const SizedBox(width: 8),
          _buildFilterChip('Selesai', Icons.check_circle, theme),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, ThemeData theme) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedFilter = label),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.primaryBlue),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primaryBlue,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          )),
        ],
      ),
      backgroundColor: AppTheme.primaryBlue.withOpacity(0.08),
      selectedColor: AppTheme.primaryBlue,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.primaryBlue.withOpacity(0.2),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildTaskItem(dynamic task, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 1,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: task.isCompleted 
                ? Colors.green.withValues(alpha: 0.1)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              task.isCompleted ? Icons.check : Icons.local_shipping,
              color: task.isCompleted ? Colors.green : theme.colorScheme.primary,
            ),
          ),
          title: Text(task.title, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${task.id}', style: theme.textTheme.bodySmall),
              if (task.description != null)
                Text(task.description!, 
                     maxLines: 1, 
                     overflow: TextOverflow.ellipsis,
                     style: theme.textTheme.bodySmall?.copyWith(
                       color: Colors.grey[600],
                     )),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!task.isCompleted)
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final provider = Provider.of<OfflineFirstDeliveryProvider>(context, listen: false);
                    await provider.toggleTaskComplete(task.id);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Pengiriman ${task.id} berhasil diselesaikan!'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  tooltip: 'Selesaikan Pengiriman',
                ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryDetailPage(taskId: task.id),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, 
               size: 64, 
               color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Belum ada data pengiriman', 
               style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Provider.of<OfflineFirstDeliveryProvider>(context, listen: false).fetchTasks(),
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}