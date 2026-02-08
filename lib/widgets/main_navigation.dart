import 'package:flutter/material.dart';
import 'package:kirimtrack/efficient_dashboard.dart';
import 'package:kirimtrack/offline_analytics_page.dart';
import 'package:kirimtrack/offline_history_page.dart';
import 'package:kirimtrack/offline_profile_page.dart';
import 'package:kirimtrack/qr_scanner_page.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late List<GlobalKey<NavigatorState>> _navigatorKeys;

  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    NavItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'Riwayat',
    ),
    NavItem(
      icon: Icons.qr_code_scanner_outlined,
      activeIcon: Icons.qr_code_scanner,
      label: 'Scanner',
    ),
    NavItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Analitik',
    ),
    NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _navigatorKeys = List.generate(
      5,
      (index) => GlobalKey<NavigatorState>(),
    );
    
    // Animate FAB on init
    Future.delayed(const Duration(milliseconds: 500), () {
      _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavItemTapped(int index) {
    if (index == 2) {
      // Handle scanner differently (modal)
      _openScanner();
      return;
    }
    
    final adjustedIndex = index > 2 ? index - 1 : index;
    
    if (_currentIndex == adjustedIndex) {
      // Pop to first route of the tab
      _navigatorKeys[adjustedIndex].currentState?.popUntil((route) => route.isFirst);
      return;
    }

    setState(() {
      _currentIndex = adjustedIndex;
    });
    _pageController.animateToPage(
      adjustedIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerPage(),
      ),
    );
    
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Code: $result'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const EfficientDashboard();
      case 1:
        return const OfflineHistoryPage();
      case 2:
        return const OfflineAnalyticsPage();
      case 3:
        return const OfflineProfilePage();
      default:
        return const EfficientDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: 4, // Excluding scanner
        itemBuilder: (context, index) {
          return Navigator(
            key: _navigatorKeys[index],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => _buildPage(index),
                settings: settings,
              );
            },
          );
        },
      ),

      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 28),
        child: ScaleTransition(
          scale: _fabAnimationController,
          child: FloatingActionButton(
            onPressed: _openScanner,
            tooltip: 'Scan QR Code',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2563EB),
            elevation: 6,
            shape: const CircleBorder(),
            child: const Icon(Icons.qr_code_scanner, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: const Color(0xFF1E3A8A),
        elevation: 12,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(child: _buildNavItem(0, theme)),
              Expanded(child: _buildNavItem(1, theme)),
              const SizedBox(width: 56), // Space for FAB
              Expanded(child: _buildNavItem(3, theme)),
              Expanded(child: _buildNavItem(4, theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, ThemeData theme) {
    final adjustedIndex = index > 2 ? index - 1 : index;
    final isActive = _currentIndex == adjustedIndex;
    final navItem = _navItems[index];
    
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? navItem.activeIcon : navItem.icon,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.55),
            size: 24,
          ),
          const SizedBox(height: 3),
          Text(
            navItem.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// Helper widget for smooth transitions
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _previousIndex = oldWidget.index;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: widget.children.asMap().entries.map((entry) {
            final index = entry.key;
            final child = entry.value;
            
            if (index == widget.index) {
              return Opacity(
                opacity: _animation.value,
                child: child,
              );
            } else if (index == _previousIndex) {
              return Opacity(
                opacity: 1 - _animation.value,
                child: child,
              );
            } else {
              return const SizedBox.shrink();
            }
          }).toList(),
        );
      },
    );
  }
}