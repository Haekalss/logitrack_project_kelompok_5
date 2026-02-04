import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool showPulse;

  const StatusBadge({
    super.key,
    required this.status,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.showPulse = false,
  });

  factory StatusBadge.completed() {
    return const StatusBadge(
      status: 'Selesai',
      backgroundColor: Color(0xFF10B981),
      textColor: Colors.white,
      icon: Icons.check_circle,
    );
  }

  factory StatusBadge.pending() {
    return const StatusBadge(
      status: 'Pending',
      backgroundColor: Color(0xFFF59E0B),
      textColor: Colors.white,
      icon: Icons.pending,
      showPulse: true,
    );
  }

  factory StatusBadge.inProgress() {
    return const StatusBadge(
      status: 'Sedang Dikirim',
      backgroundColor: Color(0xFF3B82F6),
      textColor: Colors.white,
      icon: Icons.local_shipping,
      showPulse: true,
    );
  }

  factory StatusBadge.cancelled() {
    return const StatusBadge(
      status: 'Dibatalkan',
      backgroundColor: Color(0xFFEF4444),
      textColor: Colors.white,
      icon: Icons.cancel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary;
    final txtColor = textColor ?? Colors.white;

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: txtColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: TextStyle(
              color: txtColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (showPulse) {
      return PulsingWidget(child: badge);
    }

    return badge;
  }
}

class PulsingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PulsingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? action,
    String? actionLabel,
  }) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = const Color(0xFF10B981);
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case SnackBarType.error:
        backgroundColor = const Color(0xFFEF4444);
        textColor = Colors.white;
        icon = Icons.error;
        break;
      case SnackBarType.warning:
        backgroundColor = const Color(0xFFF59E0B);
        textColor = Colors.white;
        icon = Icons.warning;
        break;
      case SnackBarType.info:
        backgroundColor = const Color(0xFF3B82F6);
        textColor = Colors.white;
        icon = Icons.info;
        break;
    }

    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        action: action != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: textColor,
                onPressed: action,
              )
            : null,
      ),
    );
  }
}

enum SnackBarType {
  success,
  error,
  warning,
  info,
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? 'Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}