import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:egg_toeic/core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;
  final bool showHomeIcon;

  const CustomAppBar({
    super.key,
    required this.title,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.actions,
    this.leading,
    this.bottom,
    this.automaticallyImplyLeading = true,
    this.showHomeIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    // For now, we'll show the home icon on all screens where it's enabled
    // The home screen should explicitly set showHomeIcon: false when using this widget
    List<Widget> appBarActions = [];

    // Add home icon if we should show it
    if (showHomeIcon) {
      appBarActions.add(
        IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () {
            // Navigate to home screen
            context.go('/');
          },
          tooltip: '홈으로',
        ),
      );
    }

    // Add any additional actions passed in
    if (actions != null) {
      appBarActions.addAll(actions!);
    }

    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      actions: appBarActions.isNotEmpty ? appBarActions : null,
      leading: leading,
      bottom: bottom,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  @override
  Size get preferredSize {
    double height = kToolbarHeight;
    if (bottom != null) {
      height += bottom!.preferredSize.height;
    }
    return Size.fromHeight(height);
  }
}