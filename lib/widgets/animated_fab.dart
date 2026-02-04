import 'package:flutter/material.dart';

class AnimatedFab extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String tooltip;
  final List<FabOption> options;

  const AnimatedFab({
    super.key,
    this.onPressed,
    required this.icon,
    required this.tooltip,
    this.options = const [],
  });

  @override
  State<AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<AnimatedFab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    if (_isOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) {
      return FloatingActionButton(
        onPressed: widget.onPressed,
        tooltip: widget.tooltip,
        child: widget.icon,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...List.generate(widget.options.length, (index) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation.value,
                child: Opacity(
                  opacity: _animation.value,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: FloatingActionButton(
                      mini: true,
                      heroTag: "fab_${widget.options[index].label}",
                      onPressed: _animation.value == 1.0
                          ? widget.options[index].onPressed
                          : null,
                      child: widget.options[index].icon,
                    ),
                  ),
                ),
              );
            },
          );
        }),
        FloatingActionButton(
          onPressed: _toggleFab,
          tooltip: widget.tooltip,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 300),
            turns: _isOpen ? 0.125 : 0,
            child: widget.icon,
          ),
        ),
      ],
    );
  }
}

class FabOption {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  const FabOption({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}