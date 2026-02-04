import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kirimtrack/providers/delivery_task_provider.dart';
import 'package:kirimtrack/profile_page.dart';
import 'package:kirimtrack/delivery_detail_page.dart';
import 'package:kirimtrack/qr_scanner_page.dart';
import 'package:kirimtrack/history_page.dart';
import 'package:kirimtrack/delivery_task_model.dart';

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
      Provider.of<DeliveryTaskProvider>(context, listen: false).fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('KirimTrack - Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const HistoryPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const ProfilePage()),
            ),
          ),
        ],
      ),
      body: Consumer<DeliveryTaskProvider>(
        builder: (context, provider, child) {
          return _buildContent(context, provider, theme);
        },
      ),
      floatingActionButton: _buildFAB(context, theme),
    );
  }

  Widget _buildContent(BuildContext context, DeliveryTaskProvider provider, ThemeData theme) {
    switch (provider.state) {
      case TaskState.Loading:
        return const Center(
          child: CircularProgressIndicator(),
        );
      
      case TaskState.Error:
        return _buildErrorView(provider, theme);
      
      case TaskState.Loaded:
        return _buildTaskList(provider, theme);
      
      default:
        return const Center(child: Text('Memulai...'));
    }
  }

  Widget _buildErrorView(DeliveryTaskProvider provider, ThemeData theme) {
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
            Text(provider.errorMessage,
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

  Widget _buildTaskList(DeliveryTaskProvider provider, ThemeData theme) {
    final allTasks = provider.tasks;
    
    if (allTasks.isEmpty) {
      return _buildEmptyView(theme);
    }

    // Filter tasks efficiently
    final filteredTasks = _getFilteredTasks(allTasks);
    
    return RefreshIndicator(
      onRefresh: () => provider.refreshTasks(),
      child: CustomScrollView(
        slivers: [
          // Header Stats
          SliverToBoxAdapter(
            child: _buildStatsHeader(allTasks, theme),
          ),
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

  Widget _buildStatsHeader(List<DeliveryTask> allTasks, ThemeData theme) {
    final total = allTasks.length;
    final completed = allTasks.where((t) => t.isCompleted).length;
    final pending = total - completed;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selamat datang!',
               style: theme.textTheme.titleLarge?.copyWith(
                 color: Colors.white,
                 fontWeight: FontWeight.bold,
               )),
          const SizedBox(height: 8),
          Text('Kelola pengiriman Anda dengan mudah',
               style: theme.textTheme.bodyMedium?.copyWith(
                 color: Colors.white.withOpacity(0.9),
               )),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', total.toString(), Colors.white),
              _buildStatItem('Selesai', completed.toString(), Colors.green[200]!),
              _buildStatItem('Pending', pending.toString(), Colors.orange[200]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
             style: TextStyle(
               fontSize: 20,
               fontWeight: FontWeight.bold,
               color: color,
             )),
        const SizedBox(height: 4),
        Text(label,
             style: TextStyle(
               fontSize: 12,
               color: color.withOpacity(0.8),
             )),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Cari berdasarkan ID atau Judul...',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: theme.colorScheme.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
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
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
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
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      backgroundColor: Colors.grey[100],
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
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
                ? Colors.green.withOpacity(0.1)
                : theme.colorScheme.primary.withOpacity(0.1),
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
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.primary,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryDetailPage(task: task),
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
               color: theme.colorScheme.onSurface.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('Belum ada data pengiriman', 
               style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Provider.of<DeliveryTaskProvider>(context, listen: false).fetchTasks(),
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScannerPage()),
          );
          if (result != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Paket terdeteksi: $result')),
            );
          }
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Pindai QR'),
        elevation: 4,
      ),
    );
  }
}