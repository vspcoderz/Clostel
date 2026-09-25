import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liquid_glass_kit/flutter_liquid_glass_kit.dart';

bool get usesAppleLiquidGlass {
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

LiquidGlassSettings _glassSettingsFor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? LiquidGlassSettings.matteDark
      : LiquidGlassSettings.matteLight;
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
      settings: _glassSettingsFor(context),
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

  Widget _glassDestinationIcon(
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = currentIndex == index;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        selected: isSelected,
        excludeSemantics: true,
        child: Icon(icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (usesAppleLiquidGlass) {
      final horizontalInset =
          MediaQuery.sizeOf(context).width < 360 ? 10.0 : 16.0;

      return SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(horizontalInset, 0, horizontalInset, 12),
        child: LiquidGlassNavBar(
          currentIndex: currentIndex,
          onTap: onDestinationSelected,
          activeColor: colorScheme.onSurface,
          inactiveColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
          items: [
            LiquidGlassNavItem(
              icon: _glassDestinationIcon(
                Icons.explore_outlined,
                'Discover',
                0,
              ),
              activeIcon: _glassDestinationIcon(
                Icons.explore,
                'Discover',
                0,
              ),
              label: 'Discover',
              iosSystemImage: 'safari',
              iosSelectedSystemImage: 'safari.fill',
            ),
            LiquidGlassNavItem(
              icon: _glassDestinationIcon(
                Icons.library_music_outlined,
                'Library',
                1,
              ),
              activeIcon: _glassDestinationIcon(
                Icons.library_music,
                'Library',
                1,
              ),
              label: 'Library',
              iosSystemImage: 'music.note.list',
              iosSelectedSystemImage: 'music.note.list',
            ),
            LiquidGlassNavItem(
              icon: _glassDestinationIcon(
                Icons.queue_music_outlined,
                'Queue',
                2,
              ),
              activeIcon: _glassDestinationIcon(
                Icons.queue_music,
                'Queue',
                2,
              ),
              label: 'Queue',
              iosSystemImage: 'list.bullet',
              iosSelectedSystemImage: 'list.bullet',
            ),
            LiquidGlassNavItem(
              icon: _glassDestinationIcon(
                Icons.settings_outlined,
                'Settings',
                3,
              ),
              activeIcon: _glassDestinationIcon(
                Icons.settings,
                'Settings',
                3,
              ),
              label: 'Settings',
              iosSystemImage: 'gearshape',
              iosSelectedSystemImage: 'gearshape.fill',
            ),
          ],
        ),
      );
    }

    return Semantics(
      label: 'Main navigation',
      container: true,
      child: NavigationBar(
        height: 64,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            label: 'Queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
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

  Widget _destinationIcon(
    IconData icon,
    String label,
    bool extended,
  ) {
    final iconWidget = Icon(icon);
    if (extended) {
      return iconWidget;
    }
    return Tooltip(message: label, child: iconWidget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final extended = constraints.maxWidth >= 1080;
        final brand = Semantics(
          label: 'Clostel',
          header: true,
          excludeSemantics: true,
          child: extended
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
                  child: Row(
                    children: [
                      _ClostelMark(colorScheme: colorScheme),
                      const SizedBox(width: 12),
                      Text(
                        'clostel',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 23,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 22),
                  child: Tooltip(
                    message: 'Clostel',
                    child: _ClostelMark(colorScheme: colorScheme),
                  ),
                ),
        );

        return Semantics(
          label: 'Main navigation',
          container: true,
          child: SafeArea(
            right: false,
            child: NavigationRail(
              extended: extended,
              minWidth: 76,
              minExtendedWidth: 224,
              backgroundColor: colorScheme.surface,
              indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              groupAlignment: -0.85,
              mainAxisAlignment: MainAxisAlignment.start,
              selectedLabelTextStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              selectedIconTheme: IconThemeData(
                color: colorScheme.primary,
                size: 22,
              ),
              unselectedIconTheme: IconThemeData(
                color: colorScheme.onSurfaceVariant,
                size: 22,
              ),
              leading: brand,
              destinations: [
                NavigationRailDestination(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  icon: _destinationIcon(
                    Icons.explore_outlined,
                    'Discover',
                    extended,
                  ),
                  selectedIcon: _destinationIcon(
                    Icons.explore,
                    'Discover',
                    extended,
                  ),
                  label: const Text('Discover'),
                ),
                NavigationRailDestination(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  icon: _destinationIcon(
                    Icons.library_music_outlined,
                    'Library',
                    extended,
                  ),
                  selectedIcon: _destinationIcon(
                    Icons.library_music,
                    'Library',
                    extended,
                  ),
                  label: const Text('Library'),
                ),
                NavigationRailDestination(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  icon: _destinationIcon(
                    Icons.queue_music_outlined,
                    'Queue',
                    extended,
                  ),
                  selectedIcon: _destinationIcon(
                    Icons.queue_music,
                    'Queue',
                    extended,
                  ),
                  label: const Text('Queue'),
                ),
                NavigationRailDestination(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  icon: _destinationIcon(
                    Icons.settings_outlined,
                    'Settings',
                    extended,
                  ),
                  selectedIcon: _destinationIcon(
                    Icons.settings,
                    'Settings',
                    extended,
                  ),
                  label: const Text('Settings'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ClostelMark extends StatelessWidget {
  const _ClostelMark({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.graphic_eq,
        color: colorScheme.onPrimary,
        size: 23,
      ),
    );
  }
}

class AdaptiveDesktopTabs extends StatefulWidget {
  const AdaptiveDesktopTabs({
    required this.currentIndex,
    required this.onChanged,
    super.key,
  }) : assert(currentIndex >= 0 && currentIndex < 4);

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1080;
        final horizontalPadding = compact ? 12.0 : 24.0;
        final brandWidth = compact ? 50.0 : 190.0;
        final showBeta = constraints.maxWidth >= 720;

        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  SizedBox(
                    width: brandWidth,
                    child: Semantics(
                      label: 'Clostel',
                      header: true,
                      excludeSemantics: true,
                      child: Row(
                        children: [
                          _ClostelMark(colorScheme: colorScheme),
                          if (!compact) ...[
                            const SizedBox(width: 11),
                            Text(
                              'clostel',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBar(
                      controller: _controller,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      onTap: widget.onChanged,
                      labelColor: colorScheme.onSurface,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      indicatorColor: colorScheme.primary,
                      indicatorWeight: 3,
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle:
                          theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: [
                        const Tab(
                          icon: Tooltip(
                            message: 'Discover',
                            child: Icon(Icons.explore_outlined),
                          ),
                          text: 'Discover',
                        ),
                        const Tab(
                          icon: Tooltip(
                            message: 'Library',
                            child: Icon(Icons.library_music_outlined),
                          ),
                          text: 'Library',
                        ),
                        const Tab(
                          icon: Tooltip(
                            message: 'Queue',
                            child: Icon(Icons.queue_music_outlined),
                          ),
                          text: 'Queue',
                        ),
                        const Tab(
                          icon: Tooltip(
                            message: 'Settings',
                            child: Icon(Icons.settings_outlined),
                          ),
                          text: 'Settings',
                        ),
                      ],
                    ),
                  ),
                  if (showBeta) ...[
                    const SizedBox(width: 12),
                    const Tooltip(
                      message: 'Clostel beta',
                      child: Chip(label: Text('BETA')),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AdaptiveSearchField extends StatelessWidget {
  const AdaptiveSearchField({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (usesAppleLiquidGlass) {
      return LiquidGlassTextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        enableSuggestions: false,
        keyboardAppearance: theme.brightness,
        cursorColor: colorScheme.primary,
        scrollPadding: const EdgeInsets.all(24),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: const InputDecoration(
          labelText: 'Search catalog',
          hintText: 'Artists, albums, or moods',
          prefixIcon: Tooltip(
            message: 'Search',
            child: Icon(Icons.search),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 52),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          constraints: BoxConstraints(minHeight: 56),
        ),
      );
    }

    return Semantics(
      label: 'Search catalog',
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: SearchBar(
          onChanged: onChanged,
          hintText: 'Artists, albums, or moods',
          leading: const Tooltip(
            message: 'Search',
            child: Icon(Icons.search),
          ),
        ),
      ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = onPressed != null && !isLoading;
    final foregroundColor = isEnabled
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withValues(alpha: 0.54);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: foregroundColor, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: foregroundColor,
          ),
        ),
      ],
    );
    final tooltipMessage = isLoading
        ? '$label, loading'
        : isEnabled
            ? label
            : '$label, unavailable';

    if (usesAppleLiquidGlass) {
      return Tooltip(
        message: tooltipMessage,
        child: _FocusableLiquidGlassButton(
          label: label,
          onPressed: onPressed,
          isLoading: isLoading,
          foregroundColor: foregroundColor,
          settings: _glassSettingsFor(context).copyWith(
            tintColor: colorScheme.primary,
            tintOpacity: isEnabled ? 0.92 : 0.64,
            borderOpacity: theme.brightness == Brightness.dark ? 0.24 : 0.42,
          ),
          child: child,
        ),
      );
    }

    return Tooltip(
      message: tooltipMessage,
      child: Semantics(
        label: isLoading ? '$label, loading' : null,
        liveRegion: isLoading,
        child: FilledButton(
          onPressed: isEnabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor:
                colorScheme.onSurface.withValues(alpha: 0.12),
            disabledForegroundColor:
                colorScheme.onSurface.withValues(alpha: 0.54),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            overlayColor: colorScheme.onPrimary.withValues(alpha: 0.12),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : child,
        ),
      ),
    );
  }
}

class _FocusableLiquidGlassButton extends StatefulWidget {
  const _FocusableLiquidGlassButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.foregroundColor,
    required this.settings,
    required this.child,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color foregroundColor;
  final LiquidGlassSettings settings;
  final Widget child;

  @override
  State<_FocusableLiquidGlassButton> createState() =>
      _FocusableLiquidGlassButtonState();
}

class _FocusableLiquidGlassButtonState
    extends State<_FocusableLiquidGlassButton> {
  bool _hasFocus = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _activate() {
    if (_isEnabled) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final button = LiquidGlassButton(
      onPressed: _isEnabled ? widget.onPressed : null,
      isLoading: widget.isLoading,
      settings: widget.settings,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: widget.foregroundColor),
        child: widget.child,
      ),
    );

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): _activate,
        const SingleActivator(LogicalKeyboardKey.space): _activate,
      },
      child: Semantics(
        button: true,
        enabled: _isEnabled,
        label: widget.isLoading ? '${widget.label}, loading' : widget.label,
        liveRegion: widget.isLoading,
        onTap: _isEnabled ? widget.onPressed : null,
        excludeSemantics: true,
        child: Focus(
          canRequestFocus: _isEnabled,
          onFocusChange: (hasFocus) {
            if (_hasFocus != hasFocus) {
              setState(() => _hasFocus = hasFocus);
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              button,
              if (_hasFocus && _isEnabled)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.onSurface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdaptivePlayerSurface extends StatelessWidget {
  const AdaptivePlayerSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final player = usesAppleLiquidGlass
        ? LiquidGlassCard(
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            settings: _glassSettingsFor(context).copyWith(
              tintColor: colorScheme.surface,
              tintOpacity: isDark ? 0.82 : 0.76,
              borderOpacity: isDark ? 0.24 : 0.52,
            ),
            child: child,
          )
        : Card(
            margin: EdgeInsets.zero,
            color: colorScheme.surface,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: child,
            ),
          );

    return Semantics(
      label: 'Player',
      container: true,
      explicitChildNodes: true,
      child: player,
    );
  }
}

class AdaptiveContentCard extends StatelessWidget {
  const AdaptiveContentCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
