import 'package:flutter/material.dart';

import '../../core/models/track.dart';
import '../../core/services/discord_presence.dart';
import '../../core/theme/app_theme.dart';
import '../player/player_controller.dart';
import 'adaptive_components.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.controller,
    required this.discordPresence,
    super.key,
  });

  final PlayerController controller;
  final DiscordPresenceService discordPresence;

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
    required this.discordEnabled,
    required this.onDiscordChanged,
    required this.onSelect,
  });

  final int selectedIndex;
  final PlayerController controller;
  final DiscordPresenceService discordPresence;
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
    required this.discordEnabled,
    required this.onDiscordChanged,
    required this.onSelect,
  });

  final int selectedIndex;
  final PlayerController controller;
  final DiscordPresenceService discordPresence;
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
    required this.discordEnabled,
    required this.onDiscordChanged,
  });

  final int index;
  final PlayerController controller;
  final DiscordPresenceService discordPresence;
  final bool discordEnabled;
  final ValueChanged<bool> onDiscordChanged;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => _DiscoverView(controller: controller),
      1 => _LibraryView(controller: controller),
      2 => _QueueView(controller: controller),
      _ => _SettingsView(
          discordConfigured: discordPresence.isConfigured,
          discordEnabled: discordEnabled,
          onDiscordChanged: onDiscordChanged,
        ),
    };
  }
}

class _DiscoverView extends StatelessWidget {
  const _DiscoverView({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final tracks = controller.searchResults;
    final featured =
        controller.featured.isEmpty ? null : controller.featured.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageIntro(controller: controller),
              const SizedBox(height: 26),
              AdaptiveSearchField(onChanged: controller.search),
              if (controller.error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(
                  message: controller.error!,
                  onDismiss: controller.clearError,
                ),
              ],
              if (featured != null && controller.searchResults.isNotEmpty) ...[
                const SizedBox(height: 28),
                _FeaturedTrack(track: featured, controller: controller),
              ],
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Text('Fresh signals',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  if (controller.isSearching)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (controller.isLoading && tracks.isEmpty)
                const _LoadingTracks()
              else if (tracks.isEmpty)
                const _EmptyState(
                  icon: Icons.graphic_eq,
                  title: 'No signals found',
                  message: 'Try a different artist, album, or mood.',
                )
              else
                ...tracks.map(
                  (track) => _TrackRow(
                    track: track,
                    controller: controller,
                    queue: tracks,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final intro = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discover / today',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 10),
            Text('A better way to\nhear the world.',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 10),
            Text(
              'A focused listening room for the tracks worth keeping close.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
        final nowPlaying = Chip(
          avatar: const Icon(Icons.graphic_eq, size: 16),
          label: const Text('Now playing'),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        );

        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              intro,
              if (controller.currentTrack != null) ...[
                const SizedBox(height: 16),
                nowPlaying,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: intro),
            if (controller.currentTrack != null) nowPlaying,
          ],
        );
      },
    );
  }
}

class _FeaturedTrack extends StatelessWidget {
  const _FeaturedTrack({required this.track, required this.controller});

  final Track track;
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final isCurrent = controller.currentTrack?.id == track.id;
    final canPlay = track.hasVerifiedPlayback;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.isPreview ? 'Live catalog preview' : 'Featured signal',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Text(
          track.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          track.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 2),
        Text(
          '${track.album}  /  ${_sourceLabel(track)}  /  ${_formatDuration(track.duration)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        AdaptivePrimaryButton(
          label: canPlay
              ? (isCurrent && controller.isPlaying ? 'Pause' : 'Play signal')
              : 'Unavailable',
          icon: canPlay
              ? (isCurrent && controller.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow)
              : Icons.block,
          isLoading: controller.isLoading && isCurrent,
          onPressed: canPlay
              ? () {
                  if (isCurrent) {
                    controller.togglePlayback();
                  } else {
                    controller.playTrack(track, queue: controller.featured);
                  }
                }
              : null,
        ),
      ],
    );

    return AdaptiveContentCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final artwork = _Artwork(track: track, size: 124, radius: 16);
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                artwork,
                const SizedBox(height: 18),
                details,
              ],
            );
          }

          return Row(
            children: [
              artwork,
              const SizedBox(width: 18),
              Expanded(child: details),
            ],
          );
        },
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
                  color: isCurrent ? colorScheme.primary : colorScheme.onSurface,
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
      child: controller.queue.isEmpty
          ? const _EmptyState(
              icon: Icons.queue_music,
              title: 'Nothing queued',
              message: 'Start a track from Discover and it will appear here.',
            )
          : _TrackList(tracks: controller.queue, controller: controller),
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

class _SettingsView extends StatelessWidget {
  const _SettingsView({
    required this.discordConfigured,
    required this.discordEnabled,
    required this.onDiscordChanged,
  });

  final bool discordConfigured;
  final bool discordEnabled;
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
                    ? 'Show the current track in your Discord profile.'
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
            const ExpansionTile(
              leading: Icon(Icons.palette_outlined),
              title: Text('Appearance'),
              subtitle: Text('Warm white is the default listening surface.'),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'The listening surface uses a warm white background, high-contrast text, and the coral accent to keep controls easy to find without competing with the music.',
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
                          message: 'Choose a track from Discover to open the full player.',
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
              final artworkSize = constraints.maxWidth < 400
                  ? constraints.maxWidth
                  : 360.0;
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
  const _EmptyState(
      {required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

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
  const _LoadingTracks();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Card(
            color: Theme.of(context).colorScheme.surface,
            child: ListTile(
              leading: const SizedBox(width: 54, height: 54),
              title: Container(
                height: 14,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              subtitle: const SizedBox(height: 8),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
