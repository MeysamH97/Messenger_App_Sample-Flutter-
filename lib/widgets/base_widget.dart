import 'package:flutter/material.dart';

class BaseWidget extends StatelessWidget {
  const BaseWidget({
    super.key,
    this.appBar,
    this.padding,
    required this.child,
    this.floatingActionButton,
    this.floatingActionButtonIcon, this.floatingActionButtonAnimation,
  });

  final double? padding;
  final PreferredSizeWidget? appBar;
  final VoidCallback? floatingActionButton;
  final IconData? floatingActionButtonIcon;
  final Animation<double>? floatingActionButtonAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton != null
          ? AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: ScaleTransition(
              scale: floatingActionButtonAnimation!,
              child: FloatingActionButton(
                  onPressed: floatingActionButton,
                  backgroundColor: Theme.of(context).colorScheme.onBackground,
                  hoverColor:
                      Theme.of(context).colorScheme.background.withOpacity(0.2),
                  child: Icon(
                    floatingActionButtonIcon,
                    size: 35,
                    color: Theme.of(context).colorScheme.background,
                  ),
                ),
            ),
          )
          : null,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding ?? 10),
        child: Center(child: child),
      ),
    );
  }
}
