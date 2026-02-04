import 'package:flutter/material.dart';
import 'package:kirimtrack/efficient_dashboard.dart';
import 'package:kirimtrack/analytics_page.dart';
import 'package:kirimtrack/history_page.dart';
import 'package:kirimtrack/profile_page.dart';
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
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Analytics',
    ),
    NavItem(
      icon: Icons.qr_code_scanner_outlined,
      activeIcon: Icons.qr_code_scanner,
      label: 'Scanner',
    ),
    NavItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'History',
    ),
    NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
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
        return const AnalyticsPage();
      case 2:
        return const HistoryPage();
      case 3:
        return const ProfilePage();
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
      floatingActionButton: ScaleTransition(
        scale: _fabAnimationController,
        child: FloatingActionButton(
          onPressed: _openScanner,
          tooltip: 'Scan QR Code',
          elevation: 8,
          child: const Icon(Icons.qr_code_scanner, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          height: 52,
          color: Colors.transparent,
          elevation: 0,
          notchMargin: 6,
          shape: const CircularNotchedRectangle(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left items (Dashboard, Analytics)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, theme),
                      _buildNavItem(1, theme),
                    ],
                  ),
                ),
                
                // Space for FAB
                const SizedBox(width: 70),
                
                // Right items (History, Profile)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(3, theme), // History (index 3 becomes 2)
                      _buildNavItem(4, theme), // Profile (index 4 becomes 3)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, ThemeData theme) {
    final adjustedIndex = index > 2 ? index - 1 : index;
    final isActive = _currentIndex == adjustedIndex;
    final navItem = _navItems[index];
    
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isActive 
            ? theme.colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? navItem.activeIcon : navItem.icon,
              color: isActive 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
              size: 16,
            ),
            Text(
              navItem.label,
              style: TextStyle(
                fontSize: 8,
                color: isActive 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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