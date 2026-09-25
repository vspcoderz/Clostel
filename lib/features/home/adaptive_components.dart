import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_kit/flutter_liquid_glass_kit.dart';

import '../../core/theme/app_theme.dart';

bool get usesAppleLiquidGlass {
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

class AdaptiveGlassScope extends StatelessWidget {
  const AdaptiveGlassScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassBackdropGroup(
      settings: const LiquidGlassSettings.matteDark,
      child: child,
    );
  }
}

class AdaptiveNavigationBar extends StatelessWidget {
  const AdaptiveNavigationBar({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    if (usesAppleLiquidGlass) {
      return SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: LiquidGlassNavBar(
          currentIndex: currentIndex,
          onTap: onDestinationSelected,
          items: const [
            LiquidGlassNavItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Discover',
              iosSystemImage: 'safari',
              iosSelectedSystemImage: 'safari.fill',
            ),
            LiquidGlassNavItem(
              icon: Icon(Icons.library_music_outlined),
              activeIcon: Icon(Icons.library_music),
              label: 'Library',
              iosSystemImage: 'music.note.list',
              iosSelectedSystemImage: 'music.note.list',
            ),
            LiquidGlassNavItem(
              icon: Icon(Icons.queue_music_outlined),
              activeIcon: Icon(Icons.queue_music),
              label: 'Queue',
              iosSystemImage: 'list.bullet',
              iosSelectedSystemImage: 'list.bullet',
            ),
          ],
        ),
      );
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Discover'),
        NavigationDestination(icon: Icon(Icons.library_music_outlined), label: 'Library'),
        NavigationDestination(icon: Icon(Icons.queue_music_outlined), label: 'Queue'),
      ],
    );
  }
}

class AdaptiveDesktopNavigation extends StatelessWidget {
  const AdaptiveDesktopNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: true,
      minWidth: 220,
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      groupAlignment: -0.75,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 28),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.graphic_eq, color: AppTheme.background, size: 22),
            ),
            const SizedBox(width: 11),
            Text(
              'clostel',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    letterSpacing: -0.8,
                  ),
            ),
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: Text('Discover'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.library_music_outlined),
          selectedIcon: Icon(Icons.library_music),
          label: Text('Library'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.queue_music_outlined),
          selectedIcon: Icon(Icons.queue_music),
          label: Text('Queue'),
        ),
      ],
    );
  }
}

class AdaptiveSearchField extends StatelessWidget {
  const AdaptiveSearchField({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (usesAppleLiquidGlass) {
      return LiquidGlassTextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Search artists, albums, or moods',
          prefixIcon: Icon(Icons.search),
        ),
      );
    }

    return SearchBar(
      onChanged: onChanged,
      hintText: 'Search artists, albums, or moods',
      leading: const Icon(Icons.search),
    );
  }
}

class AdaptivePrimaryButton extends StatelessWidget {
  const AdaptivePrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(label),
      ],
    );

    if (usesAppleLiquidGlass) {
      return LiquidGlassButton(
        onPressed: isLoading ? null : onPressed,
        isLoading: isLoading,
        settings: const LiquidGlassSettings(
          tintColor: AppTheme.accent,
          tintOpacity: 0.92,
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : child,
    );
  }
}

class AdaptivePlayerSurface extends StatelessWidget {
  const AdaptivePlayerSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (usesAppleLiquidGlass) {
      return LiquidGlassCard(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        androidColor: AppTheme.surface,
        settings: const LiquidGlassSettings(
          tintColor: AppTheme.surface,
          tintOpacity: 0.78,
        ),
        child: child,
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: child,
      ),
    );
  }
}

class AdaptiveContentCard extends StatelessWidget {
  const AdaptiveContentCard({required this.child, this.padding = const EdgeInsets.all(18), super.key});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.surface,
      child: Padding(padding: padding, child: child),
    );
  }
}
