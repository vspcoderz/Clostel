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
    if (!usesAppleLiquidGlass) {
      return child;
    }

    return LiquidGlassBackdropGroup(
      settings: LiquidGlassSettings.matteLight,
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
            LiquidGlassNavItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
              iosSystemImage: 'gearshape',
              iosSelectedSystemImage: 'gearshape.fill',
            ),
          ],
        ),
      );
    }

    return NavigationBar(
      backgroundColor: AppTheme.surface,
      indicatorColor: AppTheme.accent.withValues(alpha: 0.18),
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.explore_outlined), label: 'Discover'),
        NavigationDestination(
            icon: Icon(Icons.library_music_outlined), label: 'Library'),
        NavigationDestination(
            icon: Icon(Icons.queue_music_outlined), label: 'Queue'),
        NavigationDestination(
            icon: Icon(Icons.settings_outlined), label: 'Settings'),
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
      minWidth: 248,
      backgroundColor: AppTheme.surface,
      indicatorColor: AppTheme.accent.withValues(alpha: 0.18),
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
              child: const Icon(Icons.graphic_eq,
                  color: AppTheme.background, size: 22),
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
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }
}

class AdaptiveDesktopTabs extends StatefulWidget {
  const AdaptiveDesktopTabs({
    required this.currentIndex,
    required this.onChanged,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  State<AdaptiveDesktopTabs> createState() => _AdaptiveDesktopTabsState();
}

class _AdaptiveDesktopTabsState extends State<AdaptiveDesktopTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.currentIndex,
    );
  }

  @override
  void didUpdateWidget(covariant AdaptiveDesktopTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _controller.index) {
      _controller.animateTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.graphic_eq,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 11),
                Text('clostel', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          Expanded(
            child: TabBar(
              controller: _controller,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              onTap: widget.onChanged,
              labelColor: AppTheme.paper,
              unselectedLabelColor: AppTheme.muted,
              indicatorColor: AppTheme.accent,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontFamily: 'FunnelDisplay',
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'FunnelDisplay',
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.explore_outlined), text: 'Discover'),
                Tab(icon: Icon(Icons.library_music_outlined), text: 'Library'),
                Tab(icon: Icon(Icons.queue_music_outlined), text: 'Queue'),
                Tab(icon: Icon(Icons.settings_outlined), text: 'Settings'),
              ],
            ),
          ),
          const Chip(label: Text('BETA')),
        ],
      ),
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
        settings: LiquidGlassSettings.matteLight.copyWith(
          tintColor: AppTheme.surface,
          tintOpacity: 0.74,
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
  const AdaptiveContentCard(
      {required this.child,
      this.padding = const EdgeInsets.all(18),
      super.key});

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
