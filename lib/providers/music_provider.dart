import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

class MusicState {
  final String title;
  final String artist;
  final bool isPlaying;
  final Uint8List? albumArt;

  const MusicState({
    this.title = 'No Music',
    this.artist = 'Not Playing',
    this.isPlaying = false,
    this.albumArt,
  });

  MusicState copyWith({
    String? title,
    String? artist,
    bool? isPlaying,
    Uint8List? albumArt,
  }) {
    return MusicState(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      isPlaying: isPlaying ?? this.isPlaying,
      albumArt: albumArt ?? this.albumArt,
    );
  }
}

class MusicNotifier extends Notifier<MusicState> {
  StreamSubscription<ServiceNotificationEvent>? _subscription;

  @override
  MusicState build() {
    _init();
    
    ref.onDispose(() {
      _subscription?.cancel();
    });

    return const MusicState();
  }

  Future<void> _init() async {
    final bool granted = await NotificationListenerService.isPermissionGranted();
    if (!granted) {
      await NotificationListenerService.requestPermission();
    }
    
    // Listen to all notifications and filter for media players
    _subscription = NotificationListenerService.notificationsStream.listen((event) {
      // Media notifications usually have a specific package and ongoing state.
      // We will look for popular media apps.
      final pkg = event.packageName.toLowerCase();
      if (pkg.contains('spotify') || 
          pkg.contains('music') || 
          pkg.contains('podcast') ||
          pkg.contains('soundcloud')) {
        
        // If the notification is removed, music stopped/paused (sometimes)
        if (event.hasRemoved) {
          state = state.copyWith(isPlaying: false);
          return;
        }

        // title is usually track name, content is usually artist
        state = state.copyWith(
          title: event.title,
          artist: event.content,
          isPlaying: event.title.isNotEmpty,
          albumArt: event.largeIcon, 
        );
      }
    });
  }
}

final musicProvider = NotifierProvider<MusicNotifier, MusicState>(() {
  return MusicNotifier();
});
