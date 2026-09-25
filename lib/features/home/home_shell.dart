import 'package:flutter/material.dart';

import '../../core/models/track.dart';
import '../../core/services/discord_presence.dart';
import '../../core/services/playback_service.dart';
import '../../core/theme/app_theme.dart';
import '../player/player_controller.dart';
import 'adaptive_components.dart';

/// Below this width Discover uses the phone gutter; above it, the roomier one.
const double _kDiscoverCompactBreakpoint = 620;

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.controller,
    required this.discordPresence,
    this.themeController,
    super.key,
  });

  final PlayerController controller;
  final DiscordPresenceService discordPresence;
  final ThemeModeController? themeController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  PlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_handleControllerChange);
    controller.loadFeatured();
  }

  void _handleControllerChange() {
    widget.discordPresence.update(
      track: controller.currentTrack,
      isPlaying: controller.isPlaying,
    );
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerChange);
    widget.discordPresence.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return _DesktopShell(
                selectedIndex: _selectedIndex,
                controller: controller,
                discordPresence: widget.discordPresence,
                themeController: widget.themeController,
                discordEnabled: widget.discordPresence.userEnabled,
                onDiscordChanged: (enabled) async {
                  await widget.discordPresence.setEnabled(enabled);
                  if (mounted) {
                    setState(() {});
                  }
                },
                onSelect: (index) => setState(() => _selectedIndex = index),
              );
            }

            return _MobileShell(
              selectedIndex: _selectedIndex,
              controller: controller,
              discordPresence: widget.discordPresence,
              themeController: widget.themeController,
              discordEnabled: widget.discordPresence.userEnabled,
              onDiscordChanged: (enabled) async {
                await widget.discordPresence.setEnabled(enabled);
                if (mounted) {
                  setState(() {});
                }
              },
              onSelect: (index) => setState(() => _selectedIndex = index),
            );
          },
        );
      },
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.selectedIndex,
    required this.controller,
    required this.discordPresence,
    required this.themeController,
    required this.discordEnabled,
    required this.onDiscordChanged,
    required this.onSelect,
  });

  final int selectedIndex;
  final PlayerController controller;
  final DiscordPresenceService discordPresence;
  final ThemeModeController? themeController;
  final bool discordEnabled;
  final ValueChanged<bool> onDiscordChanged;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassScope(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              AdaptiveDesktopNavigation(
                currentIndex: selectedIndex,
                onDestinationSelected: onSelect,
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    AppBar(
                      primary: false,
                      toolbarHeight: 58,
                      titleSpacing: 24,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      title: Text(_pageTitle(selectedIndex)),
                      actions: const [
                        Padding(
                          padding: EdgeInsets.only(right: 24),
                          child: Chip(label: Text('PUBLIC CATALOGS')),
                        ),
                      ],
                    ),
                    Expanded(
                      child: _SelectedPage(
                        index: selectedIndex,
                        controller: controller,
                        discordPresence: discordPresence,
                        themeController: themeController,
                        discordEnabled: discordEnabled,
                        onDiscordChanged: onDiscordChanged,
                      ),
                    ),
                    _PlayerDock(controller: controller),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.selectedIndex,
    required this.controller,
    required this.discordPresence,
    required this.themeController,
    required this.discordEnabled,
    required this.onDiscordChanged,
    required this.onSelect,
  });

  final int selectedIndex;
  final PlayerController controller;
  final DiscordPresenceService discordPresence;
  final ThemeModeController? themeController;
  final bool discordEnabled;
  final ValueChanged<bool> onDiscordChanged;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassScope(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: _SelectedPage(
              index: selectedIndex,
              controller: controller,
              discordPresence: discordPresence,
              themeController: themeController,
              discordEnabled: discordEnabled,
              onDiscordChanged: onDiscordChanged,
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.currentTrack != null)
                _MiniPlayer(controller: controller),
              AdaptiveNavigationBar(
                currentIndex: selectedIndex,
                onDestinationSelected: onSelect,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _pageTitle(int index) {
  return switch (index) {
    0 => 'Discover',
    1 => 'Library',
    2 => 'Queue',
    _ => 'Settings',
  };
}

String _sourceLabel(Track track) => track.source ?? 'Catalog';

void _openNowPlaying(BuildContext context, PlayerController controller) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => _NowPlayingPage(controller: controller),
    ),
  );
}

class _SelectedPage extends StatelessWidget {
  const _SelectedPage({
    required this.index,
    required this.controller,
    required this.discordPresence,
    required this.themeController,
    required this.discordEnabled,
    required this.onDiscordChanged,
  });

  final int index;
  final PlayerController controller;
  final DiscordPresenceService discordPresence;
  final ThemeModeController? themeController;
  final bool discordEnabled;
  final ValueChanged<bool> onDiscordChanged;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => _DiscoverView(controller: controller),
      1 => _LibraryView(controller: controller),
      2 => _QueueView(controller: controller),
      _ => _SettingsView(
          controller: controller,
          discordConfigured: discordPresence.isConfigured,
          discordEnabled: discordEnabled,
          discordConnectionState: discordPresence.connectionState,
          themeController: themeController,
          onDiscordChanged: onDiscordChanged,
        ),
    };
  }
}

/// A mood or scene the reader can jump straight into.
///
/// These entries are query vocabulary, not catalog content: each one is handed
/// to [PlayerController.search] exactly as if it had been typed. The genre
/// chips beside them are derived from the tracks the controller already holds,
/// so they always point at something the catalog can answer.
class _DiscoveryTerm {
  const _DiscoveryTerm({required this.label, required this.query});

  final String label;
  final String query;
}

const List<_DiscoveryTerm> _moodTerms = [
  _DiscoveryTerm(label: 'Focus', query: 'focus'),
  _DiscoveryTerm(label: 'Unwind', query: 'unwind'),
  _DiscoveryTerm(label: 'Late night', query: 'night'),
  _DiscoveryTerm(label: 'Morning', query: 'morning'),
  _DiscoveryTerm(label: 'Energize', query: 'energy'),
  _DiscoveryTerm(label: 'Vocals', query: 'vocal'),
];

class _DiscoverView extends StatefulWidget {
  const _DiscoverView({required this.controller});

  final PlayerController controller;

  @override
  State<_DiscoverView> createState() => _DiscoverViewState();
}

/// Discover is one hero, one row of quick actions, and the catalog list. The
/// only state it keeps locally is which chip, if any, is driving the search.
class _DiscoverViewState extends State<_DiscoverView> {
  String _query = '';
  String? _activeTerm;

  PlayerController get controller => widget.controller;

  bool get _isBrowsing => _activeTerm != null || _query.trim().isNotEmpty;

  String get _browseLabel => _activeTerm ?? _query.trim();

  /// Genres already present in the loaded catalog, ranked by how many tracks
  /// carry them. Derived, so a chip here never points at nothing.
  List<_DiscoveryTerm> get _genreTerms {
    final counts = <String, int>{};
    for (final track in [...controller.featured, ...controller.library]) {
      final genre = track.genre.trim();
      if (genre.isEmpty) {
        continue;
      }
      counts.update(genre, (value) => value + 1, ifAbsent: () => 1);
    }

    final ranked = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        if (byCount != 0) {
          return byCount;
        }
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    return [
      for (final genre in ranked.take(5))
        _DiscoveryTerm(label: genre, query: genre),
    ];
  }

  void _handleQueryChanged(String value) {
    if (_activeTerm != null || value != _query) {
      setState(() {
        _query = value;
        _activeTerm = null;
      });
    }
    controller.search(value);
  }

  void _applyTerm(_DiscoveryTerm term) {
    final isClearing = _activeTerm == term.query;
    setState(() {
      _activeTerm = isClearing ? null : term.query;
      _query = isClearing ? '' : term.query;
    });
    controller.search(isClearing ? '' : term.query);
  }

  void _clearDiscovery() {
    setState(() {
      _query = '';
      _activeTerm = null;
    });
    controller.search('');
  }

  @override
  Widget build(BuildContext context) {
    final results = controller.searchResults;
    final featured = controller.featured;
    final isLoadingList =
        results.isEmpty && (controller.isLoading || controller.isSearching);
    final gutter = _isCompactScreen(context) ? 16.0 : 24.0;

    final countLabel = results.isEmpty
        ? null
        : '${results.length} ${results.length == 1 ? 'track' : 'tracks'}'
            '${_isBrowsing ? ' matching "$_browseLabel"' : ''}';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(gutter, 28, gutter, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DiscoverHeader(controller: controller),
              const SizedBox(height: 24),
              AdaptiveSearchField(onChanged: _handleQueryChanged),
              if (controller.isSearching) ...[
                const SizedBox(height: 12),
                const _SearchProgress(),
              ],
              if (controller.error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(
                  message: controller.error!,
                  onDismiss: controller.clearError,
                ),
              ],
              if (controller.downloadError != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(
                  message: controller.downloadError!,
                  onDismiss: controller.clearDownloadError,
                ),
              ],
              const SizedBox(height: 20),
              _DiscoveryChips(
                terms: [..._moodTerms, ..._genreTerms],
                activeTerm: _activeTerm,
                onTermSelected: _applyTerm,
              ),
              if (_isBrowsing) ...[
                const SizedBox(height: 4),
                _ActiveTermNotice(
                  label: _browseLabel,
                  onClear: _clearDiscovery,
                ),
              ],
              if (featured.isNotEmpty) ...[
                const SizedBox(height: 28),
                _FeaturedHero(track: featured.first, controller: controller),
              ],
              const SizedBox(height: 32),
              _SectionHeading(
                eyebrow: _isBrowsing ? 'Results' : 'Catalog',
                title: _isBrowsing ? 'Matching signals' : 'Fresh signals',
                subtitle: countLabel,
              ),
              const SizedBox(height: 12),
              if (isLoadingList)
                const _LoadingTracks(count: 4)
              else if (results.isEmpty)
                _DiscoverEmptyState(
                  isBrowsing: _isBrowsing,
                  label: _browseLabel,
                  hasError: controller.error != null,
                  onClear: _clearDiscovery,
                  onRetry:
                      controller.isLoading ? null : controller.loadFeatured,
                )
              else
                for (final track in results)
                  _TrackRow(
                    track: track,
                    controller: controller,
                    queue: results,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// True when the window is phone-sized, used to pick the page gutter.
bool _isCompactScreen(BuildContext context) {
  return MediaQuery.sizeOf(context).width < _kDiscoverCompactBreakpoint;
}

String _playbackStatusLabel(PlayerController controller) {
  if (controller.isLoading) {
    return 'Loading';
  }
  return switch (controller.status) {
    PlaybackStatus.idle => 'Idle',
    PlaybackStatus.loading => 'Loading',
    PlaybackStatus.buffering => 'Buffering',
    PlaybackStatus.playing => 'Playing',
    PlaybackStatus.paused => 'Paused',
    PlaybackStatus.failed => 'Playback failed',
    PlaybackStatus.ended => 'Finished',
  };
}

/// Title block plus one quiet line of playback context, so the reader knows
/// what the room is doing without a second card competing with the hero.
class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final track = controller.currentTrack;
    final status = track == null
        ? 'Nothing playing yet'
        : '${_playbackStatusLabel(controller)}  ·  ${track.title}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Discover', style: theme.textTheme.labelMedium),
        const SizedBox(height: 10),
        Text(
          'A better way to\nhear the world.',
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: 10),
        Text(
          'A focused listening room for the tracks worth keeping close.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: track == null ? null : colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _DiscoveryChips extends StatelessWidget {
  const _DiscoveryChips({
    required this.terms,
    required this.activeTerm,
    required this.onTermSelected,
  });

  final List<_DiscoveryTerm> terms;
  final String? activeTerm;
  final ValueChanged<_DiscoveryTerm> onTermSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Browse by mood or genre',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final term in terms)
            _TermChip(
              term: term,
              isSelected: term.query == activeTerm,
              onPressed: () => onTermSelected(term),
            ),
        ],
      ),
    );
  }
}

/// Sticks to the app chip theme rather than restyling, so the quick actions
/// stay recognisably secondary to the hero's primary button.
class _TermChip extends StatelessWidget {
  const _TermChip({
    required this.term,
    required this.isSelected,
    required this.onPressed,
  });

  final _DiscoveryTerm term;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(term.label),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      onSelected: (_) => onPressed(),
    );
  }
}

class _ActiveTermNotice extends StatelessWidget {
  const _ActiveTermNotice({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Showing "$label"',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          onPressed: onClear,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: const Text('Clear'),
        ),
      ],
    );
  }
}

/// A hairline for in-flight searches. No copy, no spinner: the list below it
/// swaps to skeletons, which already says what is happening.
class _SearchProgress extends StatelessWidget {
  const _SearchProgress();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Searching the catalog',
      child: const ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        child: LinearProgressIndicator(minHeight: 2),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: theme.textTheme.labelSmall),
        const SizedBox(height: 6),
        Text(title, style: theme.textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// The one thing the screen leads with: artwork, strong type, the source and
/// licensing line, and the single primary action. Everything else is a list.
class _FeaturedHero extends StatelessWidget {
  const _FeaturedHero({required this.track, required this.controller});

  final Track track;
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPlay = track.hasVerifiedPlayback;
    final isCurrent = controller.currentTrack?.id == track.id;
    final isBusy = isCurrent && controller.isLoading;
    final isPlaying = isCurrent && controller.isPlaying;
    final isSaved = controller.isSaved(track);
    final isQueued = controller.queue.any((item) => item.id == track.id);
    final canDownload = controller.canDownload(track);
    final isDownloading = controller.isTrackDownloading(track);
    final isDownloaded = controller.isTrackDownloaded(track);

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.isPreview ? 'Catalog preview' : 'Featured signal',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Text(
          track.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          track.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          '${track.album}  /  ${_sourceLabel(track)}  /  '
          '${track.isPreview ? 'Preview' : 'Full track'}  /  '
          '${_formatDuration(track.duration)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AdaptivePrimaryButton(
              label: canPlay
                  ? (isBusy ? 'Loading' : (isPlaying ? 'Pause' : 'Play'))
                  : 'Unavailable',
              icon: canPlay
                  ? (isPlaying ? Icons.pause : Icons.play_arrow)
                  : Icons.block,
              isLoading: isBusy,
              onPressed: canPlay
                  ? () {
                      if (isCurrent) {
                        controller.togglePlayback();
                      } else {
                        controller.playTrack(
                          track,
                          queue: controller.featured,
                        );
                      }
                    }
                  : null,
            ),
            TextButton(
              onPressed: () => controller.toggleLibrary(track),
              child: Text(isSaved ? 'Saved' : 'Save'),
            ),
            TextButton(
              onPressed: isQueued || !canPlay
                  ? null
                  : () => controller.addToQueue(track),
              child: Text(isQueued ? 'Queued' : 'Queue'),
            ),
            if (canDownload)
              TextButton(
                onPressed: isDownloaded || isDownloading
                    ? null
                    : () => controller.downloadTrack(track),
                child: Text(
                  isDownloaded
                      ? 'Downloaded'
                      : isDownloading
                          ? 'Downloading'
                          : 'Download',
                ),
              ),
          ],
        ),
      ],
    );

    return AdaptiveContentCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final artworkSize = constraints.maxWidth < 480 ? 104.0 : 132.0;
          final artwork = Semantics(
            image: true,
            label: 'Artwork for ${track.title}',
            child: _Artwork(track: track, size: artworkSize, radius: 18),
          );

          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                artwork,
                const SizedBox(height: 16),
                details,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              artwork,
              const SizedBox(width: 20),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _DiscoverEmptyState extends StatelessWidget {
  const _DiscoverEmptyState({
    required this.isBrowsing,
    required this.label,
    required this.hasError,
    required this.onClear,
    required this.onRetry,
  });

  final bool isBrowsing;
  final String label;
  final bool hasError;
  final VoidCallback onClear;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isBrowsing) {
      return _EmptyState(
        icon: Icons.search_off,
        title: 'Nothing matches "$label"',
        message: 'Try a different mood, or search for an artist or album.',
        action: TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.close, size: 20),
          label: const Text('Clear search'),
        ),
      );
    }

    return _EmptyState(
      icon: hasError ? Icons.cloud_off : Icons.graphic_eq,
      title: hasError
          ? 'The catalog did not load'
          : 'The catalog is quiet right now',
      message: hasError
          ? 'Clostel could not reach the public adapters. The banner above has '
              'the details.'
          : 'No public adapter returned any tracks. Loading again is usually '
              'enough.',
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh, size: 20),
        label: const Text('Try again'),
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow(
      {required this.track, required this.controller, required this.queue});

  final Track track;
  final PlayerController controller;
  final List<Track> queue;

  @override
  Widget build(BuildContext context) {
    final isCurrent = controller.currentTrack?.id == track.id;
    final isSaved = controller.isSaved(track);
    final canPlay = track.hasVerifiedPlayback;
    final playLabel = isCurrent && controller.isPlaying ? 'Pause' : 'Play';
    final colorScheme = Theme.of(context).colorScheme;
    final canDownload = controller.canDownload(track);
    final isDownloading = controller.isTrackDownloading(track);
    final isDownloaded = controller.isTrackDownloaded(track);

    return Semantics(
      label: '${track.title} by ${track.artist}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: colorScheme.surface,
        child: ListTile(
          onTap: canPlay
              ? () {
                  if (isCurrent) {
                    controller.togglePlayback();
                  } else {
                    controller.playTrack(track, queue: queue);
                  }
                }
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minVerticalPadding: 8,
          isThreeLine: true,
          leading: _Artwork(track: track, size: 54, radius: 10),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:
                      isCurrent ? colorScheme.primary : colorScheme.onSurface,
                ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontSize: 14, height: 1.15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${track.album}  /  ${_sourceLabel(track)}  /  ${track.isPreview ? 'Preview' : track.licenseName ?? track.genre}  /  ${_formatDuration(track.duration)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12, height: 1.15),
                ),
              ],
            ),
          ),
          trailing: PopupMenuButton<String>(
            tooltip: 'Actions for ${track.title}',
            onSelected: (action) {
              if (action == 'play') {
                if (isCurrent) {
                  controller.togglePlayback();
                } else {
                  controller.playTrack(track, queue: queue);
                }
              } else if (action == 'queue') {
                controller.addToQueue(track);
              } else if (action == 'next') {
                controller.playNext(track);
              } else if (action == 'download') {
                controller.downloadTrack(track);
              } else if (action == 'save') {
                controller.toggleLibrary(track);
              }
            },
            itemBuilder: (context) => [
              if (canPlay)
                PopupMenuItem<String>(
                  value: 'play',
                  child: Row(
                    children: [
                      Icon(isCurrent && controller.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$playLabel ${track.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (canPlay)
                PopupMenuItem<String>(
                  value: 'next',
                  child: Row(
                    children: [
                      const Icon(Icons.playlist_play),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Play next: ${track.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (canPlay)
                PopupMenuItem<String>(
                  value: 'queue',
                  child: Row(
                    children: [
                      const Icon(Icons.queue_music),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add to queue: ${track.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (canDownload)
                PopupMenuItem<String>(
                  value: 'download',
                  enabled: !isDownloading && !isDownloaded,
                  child: Row(
                    children: [
                      Icon(isDownloaded
                          ? Icons.download_done
                          : Icons.download_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isDownloaded
                              ? 'Downloaded'
                              : isDownloading
                                  ? 'Downloading'
                                  : 'Download audio',
                        ),
                      ),
                    ],
                  ),
                ),
              if (!canPlay)
                const PopupMenuItem<String>(
                  enabled: false,
                  child: Row(
                    children: [
                      Icon(Icons.block),
                      SizedBox(width: 12),
                      Text('Playback unavailable'),
                    ],
                  ),
                ),
              PopupMenuItem<String>(
                value: 'save',
                child: Row(
                  children: [
                    Icon(isSaved ? Icons.bookmark_remove : Icons.bookmark_add),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isSaved ? 'Remove from library' : 'Save to library',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      eyebrow: 'Library / your rotation',
      title: 'Keep the good\nstuff close.',
      message:
          'Save the tracks you want to hear again. Your library follows you across Clostel surfaces.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final message = Text(
                'Your files stay on this device unless you explicitly move them.',
                style: Theme.of(context).textTheme.bodyMedium,
              );
              final importButton = FilledButton.icon(
                onPressed: controller.isImportingLibrary
                    ? null
                    : controller.importLocalTracks,
                icon: controller.isImportingLibrary
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.library_music_outlined),
                label: const Text('Import audio'),
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    message,
                    const SizedBox(height: 12),
                    importButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: message),
                  const SizedBox(width: 16),
                  importButton,
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          if (controller.library.isEmpty)
            const _EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'Your offline library is empty',
              message: 'Import audio files you own or are licensed to use.',
            )
          else
            _TrackList(tracks: controller.library, controller: controller),
        ],
      ),
    );
  }
}

class _QueueView extends StatelessWidget {
  const _QueueView({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      eyebrow: 'Queue / up next',
      title: 'Let the room\nkeep moving.',
      message: 'The queue is shared across every Clostel surface.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.queue.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: controller.clearQueue,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear queue'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (controller.queue.isEmpty)
            const _EmptyState(
              icon: Icons.queue_music,
              title: 'Nothing queued',
              message: 'Start a track from Discover and it will appear here.',
            )
          else
            _TrackList(tracks: controller.queue, controller: controller),
        ],
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  const _TrackList({required this.tracks, required this.controller});

  final List<Track> tracks;
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tracks
          .map((track) =>
              _TrackRow(track: track, controller: controller, queue: tracks))
          .toList(),
    );
  }
}

String _discordStatusLabel(DiscordPresenceConnectionState state) {
  return switch (state) {
    DiscordPresenceConnectionState.disabled => 'Currently off.',
    DiscordPresenceConnectionState.connecting => 'Connecting to Discord…',
    DiscordPresenceConnectionState.connected => 'Connected to Discord.',
    DiscordPresenceConnectionState.unavailable =>
      'Discord is unavailable. Clostel will keep playing normally.',
  };
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({
    required this.controller,
    required this.discordConfigured,
    required this.discordEnabled,
    required this.discordConnectionState,
    required this.themeController,
    required this.onDiscordChanged,
  });

  final PlayerController controller;
  final bool discordConfigured;
  final bool discordEnabled;
  final DiscordPresenceConnectionState discordConnectionState;
  final ThemeModeController? themeController;
  final ValueChanged<bool> onDiscordChanged;

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      eyebrow: 'Settings / personalize',
      title: 'Make Clostel\nfeel like yours.',
      message: 'Keep the interface quiet, useful, and connected to the music.',
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            SwitchListTile.adaptive(
              value: discordEnabled,
              onChanged: discordConfigured ? onDiscordChanged : null,
              secondary: const Icon(Icons.forum_outlined),
              title: const Text('Discord Rich Presence'),
              subtitle: Text(
                discordConfigured
                    ? _discordStatusLabel(discordConnectionState)
                    : 'Configure DISCORD_APPLICATION_ID to enable this.',
              ),
            ),
            const Divider(height: 1),
            const ExpansionTile(
              leading: Icon(Icons.music_note_outlined),
              title: Text('Music catalog'),
              subtitle: Text(
                'Public adapters with per-track licensing and local offline fallback.',
              ),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Clostel shows the source, playback kind, and licensing context for every track. The catalog stays read-only here; playback and library actions remain available from each track.',
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            ExpansionTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Downloads & storage'),
              subtitle: Text(
                controller.downloadedTrackIds.isEmpty
                    ? 'No downloaded tracks yet.'
                    : '${controller.downloadedTrackIds.length} downloaded '
                        'track${controller.downloadedTrackIds.length == 1 ? '' : 's'}.',
              ),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Explicit yt-dlp downloads are saved in the Clostel application-data folder. Downloads are never created automatically when a track plays.',
                    ),
                  ),
                ),
                if (controller.lastDownloadedPath != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SelectableText(
                        'Last download: ${controller.lastDownloadedPath}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 1),
            ExpansionTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Appearance'),
              subtitle: Text(
                themeController == null
                    ? 'System appearance is active.'
                    : 'Choose how Clostel looks on this device.',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: themeController == null
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'The app is following the system appearance.',
                          ),
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text('System'),
                                icon: Icon(Icons.brightness_auto),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text('Light'),
                                icon: Icon(Icons.light_mode_outlined),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text('Dark'),
                                icon: Icon(Icons.dark_mode_outlined),
                              ),
                            ],
                            selected: {themeController!.value},
                            onSelectionChanged: (selection) =>
                                themeController!.setMode(selection.first),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimplePage extends StatelessWidget {
  const _SimplePage({
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 10),
              Text(title, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 10),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 30),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _NowPlayingPage extends StatelessWidget {
  const _NowPlayingPage({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final track = controller.currentTrack;
        return AdaptiveGlassScope(
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                tooltip: 'Close Now Playing',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
              title: const Text('Now playing'),
            ),
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.backgroundGradientFor(context),
              ),
              child: SafeArea(
                top: false,
                child: track == null
                    ? const Center(
                        child: _EmptyState(
                          icon: Icons.album_outlined,
                          title: 'Nothing is playing yet',
                          message:
                              'Choose a track from Discover to open the full player.',
                        ),
                      )
                    : _NowPlayingContent(track: track, controller: controller),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NowPlayingContent extends StatelessWidget {
  const _NowPlayingContent({required this.track, required this.controller});

  final Track track;
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final artworkSize =
                  constraints.maxWidth < 400 ? constraints.maxWidth : 360.0;
              final artwork = Semantics(
                image: true,
                label: 'Artwork for ${track.title}',
                child: _Artwork(track: track, size: artworkSize, radius: 24),
              );
              final details = _NowPlayingDetails(track: track);
              final controls = _NowPlayingControls(controller: controller);

              if (constraints.maxWidth < 720) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: artwork),
                    const SizedBox(height: 28),
                    details,
                    const SizedBox(height: 28),
                    controls,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      artwork,
                      const SizedBox(width: 52),
                      Expanded(child: details),
                    ],
                  ),
                  const SizedBox(height: 34),
                  controls,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NowPlayingDetails extends StatelessWidget {
  const _NowPlayingDetails({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Now playing', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 10),
        Text(
          track.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          track.artist,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _NowPlayingDetailLine(label: 'Album', value: track.album),
        _NowPlayingDetailLine(label: 'Source', value: _sourceLabel(track)),
        _NowPlayingDetailLine(
          label: 'Format',
          value: track.isPreview ? 'Catalog preview' : 'Full track',
        ),
        _NowPlayingDetailLine(
          label: 'Length',
          value: _formatDuration(track.duration),
        ),
        if (track.genre.isNotEmpty)
          _NowPlayingDetailLine(label: 'Genre', value: track.genre),
        if (track.licenseName != null)
          _NowPlayingDetailLine(label: 'License', value: track.licenseName!),
        if (track.attribution != null)
          _NowPlayingDetailLine(
            label: 'Attribution',
            value: track.attribution!,
          ),
      ],
    );
  }
}

class _NowPlayingDetailLine extends StatelessWidget {
  const _NowPlayingDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    height: 1.25,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingControls extends StatelessWidget {
  const _NowPlayingControls({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final maxMillis = controller.duration.inMilliseconds <= 0
        ? 1.0
        : controller.duration.inMilliseconds.toDouble();
    final value = controller.position.inMilliseconds
        .toDouble()
        .clamp(0.0, maxMillis)
        .toDouble();

    return Semantics(
      container: true,
      label: 'Playback controls',
      child: AdaptivePlayerSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  _formatDuration(controller.position),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Expanded(
                  child: Slider(
                    value: value,
                    max: maxMillis,
                    semanticFormatterCallback: (next) =>
                        '${_formatDuration(Duration(milliseconds: next.round()))} of ${_formatDuration(controller.duration)}',
                    onChanged: controller.isLoading
                        ? null
                        : (next) => controller.seek(
                              Duration(milliseconds: next.round()),
                            ),
                  ),
                ),
                Text(
                  _formatDuration(controller.duration),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous track',
                  onPressed:
                      controller.hasPrevious ? controller.skipPrevious : null,
                  iconSize: 30,
                  icon: const Icon(Icons.skip_previous),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  tooltip: controller.isLoading
                      ? 'Loading track'
                      : (controller.isPlaying ? 'Pause' : 'Play'),
                  onPressed:
                      controller.isLoading ? null : controller.togglePlayback,
                  iconSize: 32,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: const Size(64, 64),
                  ),
                  icon: Icon(
                    controller.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Next track',
                  onPressed: controller.hasNext ? controller.skipNext : null,
                  iconSize: 30,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerDock extends StatelessWidget {
  const _PlayerDock({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final track = controller.currentTrack;
    if (track == null) {
      return const SizedBox.shrink();
    }

    final maxMillis = controller.duration.inMilliseconds <= 0
        ? 1.0
        : controller.duration.inMilliseconds.toDouble();
    final value = controller.position.inMilliseconds
        .toDouble()
        .clamp(0.0, maxMillis)
        .toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: AdaptivePlayerSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _Artwork(track: track, size: 48, radius: 9),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Previous track',
                  onPressed:
                      controller.hasPrevious ? controller.skipPrevious : null,
                  icon: const Icon(Icons.skip_previous),
                ),
                IconButton.filled(
                  tooltip: controller.isPlaying ? 'Pause' : 'Play',
                  onPressed: controller.togglePlayback,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  icon: Icon(
                      controller.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                  tooltip: 'Next track',
                  onPressed: controller.hasNext ? controller.skipNext : null,
                  icon: const Icon(Icons.skip_next),
                ),
                IconButton(
                  tooltip: 'Open Now Playing',
                  onPressed: () => _openNowPlaying(context, controller),
                  icon: const Icon(Icons.open_in_full),
                ),
              ],
            ),
            Row(
              children: [
                Text(_formatDuration(controller.position),
                    style: Theme.of(context).textTheme.labelMedium),
                Expanded(
                  child: Slider(
                    value: value,
                    max: maxMillis,
                    semanticFormatterCallback: (next) =>
                        '${_formatDuration(Duration(milliseconds: next.round()))} of ${_formatDuration(controller.duration)}',
                    onChanged: controller.isLoading
                        ? null
                        : (next) => controller.seek(
                              Duration(milliseconds: next.round()),
                            ),
                  ),
                ),
                Text(_formatDuration(controller.duration),
                    style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final track = controller.currentTrack!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: AdaptivePlayerSurface(
        child: Semantics(
          container: true,
          button: true,
          onTap: () => _openNowPlaying(context, controller),
          label: 'Open Now Playing for ${track.title}',
          hint: 'Shows expanded playback controls',
          child: Tooltip(
            message: 'Open Now Playing',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openNowPlaying(context, controller),
              child: Row(
                children: [
                  _Artwork(track: track, size: 42, radius: 8),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 13),
                        ),
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: controller.isPlaying ? 'Pause' : 'Play',
                    onPressed: controller.togglePlayback,
                    icon: Icon(
                        controller.isPlaying ? Icons.pause : Icons.play_arrow),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork(
      {required this.track, required this.size, required this.radius});

  final Track track;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = Color(track.accentValue);
    final background = Theme.of(context).colorScheme.surface;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, background, 0.78)!],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: track.artworkUrl == null
            ? _ArtworkFallback(color: color, size: size)
            : Image.network(
                track.artworkUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _ArtworkFallback(color: color, size: size),
              ),
      ),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).colorScheme.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, background, 0.78)!],
        ),
      ),
      child: Icon(
        Icons.graphic_eq,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.82),
        size: size * 0.42,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Optional recovery affordance, e.g. clearing a search or retrying a load.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 5),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF3A2421),
      child: ListTile(
        leading:
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB4A2)),
        title: Text(message, style: const TextStyle(color: Color(0xFFFFD7CF))),
        trailing: IconButton(
          tooltip: 'Dismiss',
          onPressed: onDismiss,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}

class _LoadingTracks extends StatelessWidget {
  const _LoadingTracks({this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);

    return Column(
      children: [
        for (var index = 0; index < count; index++)
          Card(
            color: colorScheme.surface,
            child: ListTile(
              leading: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              title: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
