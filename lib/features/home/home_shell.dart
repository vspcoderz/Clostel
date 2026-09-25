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
                discordEnabled: widget.discordPresence.isEnabled,
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
              discordEnabled: widget.discordPresence.isEnabled,
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
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              AdaptiveDesktopTabs(
                currentIndex: selectedIndex,
                onChanged: onSelect,
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
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fresh signals',
                      style: Theme.of(context).textTheme.headlineSmall),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DISCOVER / TODAY',
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
          ),
        ),
        if (controller.currentTrack != null)
          const Chip(
            avatar: Icon(Icons.graphic_eq, size: 16),
            label: Text('Now playing'),
            side: BorderSide(color: AppTheme.line),
            backgroundColor: AppTheme.surface,
          ),
      ],
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

    return AdaptiveContentCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _Artwork(track: track, size: 124, radius: 16),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.isPreview ? 'LIVE CATALOG PREVIEW' : 'FEATURED SIGNAL',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Text(track.title,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  track.isPreview
                      ? '${track.artist}  /  ${track.album}  /  Deezer preview'
                      : '${track.artist}  /  ${track.album}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                AdaptivePrimaryButton(
                  label: isCurrent && controller.isPlaying
                      ? 'Pause'
                      : 'Play signal',
                  icon: isCurrent && controller.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  isLoading: controller.isLoading && isCurrent,
                  onPressed: () {
                    if (isCurrent) {
                      controller.togglePlayback();
                    } else {
                      controller.playTrack(track, queue: controller.featured);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
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
    final actionIcon =
        isCurrent && controller.isPlaying ? Icons.pause : Icons.play_arrow;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.surface,
      child: ListTile(
        onTap: () => controller.playTrack(track, queue: queue),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _Artwork(track: track, size: 54, radius: 10),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isCurrent ? AppTheme.accent : AppTheme.paper,
              ),
        ),
        subtitle: Text(
          '${track.artist}  /  ${track.isPreview ? 'Deezer preview' : track.genre}  /  ${_formatDuration(track.duration)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: isSaved ? 'Remove from library' : 'Save to library',
              onPressed: () => controller.toggleLibrary(track),
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            ),
            IconButton(
              tooltip: isCurrent && controller.isPlaying
                  ? 'Pause ${track.title}'
                  : 'Play ${track.title}',
              onPressed: () {
                if (isCurrent) {
                  controller.togglePlayback();
                } else {
                  controller.playTrack(track, queue: queue);
                }
              },
              icon: Icon(actionIcon),
            ),
          ],
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
      eyebrow: 'LIBRARY / YOUR ROTATION',
      title: 'Keep the good\nstuff close.',
      message:
          'Save the tracks you want to hear again. Your library follows you across Clostel surfaces.',
      child: controller.library.isEmpty
          ? const _EmptyState(
              icon: Icons.bookmark_border,
              title: 'Your library is quiet',
              message: 'Tap the bookmark on a track to keep it here.',
            )
          : _TrackList(tracks: controller.library, controller: controller),
    );
  }
}

class _QueueView extends StatelessWidget {
  const _QueueView({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      eyebrow: 'QUEUE / UP NEXT',
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
      eyebrow: 'SETTINGS / PERSONALIZE',
      title: 'Make Clostel\nfeel like yours.',
      message: 'Keep the interface quiet, useful, and connected to the music.',
      child: Card(
        color: AppTheme.surface,
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
            const ListTile(
              leading: Icon(Icons.music_note_outlined),
              title: Text('Music catalog'),
              subtitle: Text('Deezer previews with local offline fallback.'),
              trailing: Icon(Icons.chevron_right),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.palette_outlined),
              title: Text('Appearance'),
              subtitle: Text('Warm white is the default listening surface.'),
              trailing: Icon(Icons.chevron_right),
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
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.background,
                  ),
                  icon: Icon(
                      controller.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                  tooltip: 'Next track',
                  onPressed: controller.hasNext ? controller.skipNext : null,
                  icon: const Icon(Icons.skip_next),
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
                    onChanged: (next) =>
                        controller.seek(Duration(milliseconds: next.round())),
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
              icon: Icon(controller.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
          ],
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, AppTheme.background, 0.78)!],
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, AppTheme.background, 0.78)!],
        ),
      ),
      child: Icon(
        Icons.graphic_eq,
        color: AppTheme.background.withValues(alpha: 0.82),
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
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accent, size: 32),
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
            color: AppTheme.surface,
            child: ListTile(
              leading: const SizedBox(width: 54, height: 54),
              title: Container(height: 14, color: AppTheme.surfaceRaised),
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
