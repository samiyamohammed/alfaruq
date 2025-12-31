import 'package:al_faruk_app/src/core/models/feed_item_model.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class GlobalPlayerState {
  final FeedItem? currentItem;
  final List<FeedItem> relatedContent;
  final VideoPlayerController? videoController;
  final ChewieController? chewieController;
  final YoutubePlayerController? ytController;
  final GlobalKey? playerKey;
  final bool isFloating;
  final bool isYouTube;
  final bool isPlaying;

  GlobalPlayerState({
    this.currentItem,
    this.relatedContent = const [],
    this.videoController,
    this.chewieController,
    this.ytController,
    this.playerKey,
    this.isFloating = false,
    this.isYouTube = false,
    this.isPlaying = true,
  });

  GlobalPlayerState copyWith({
    FeedItem? currentItem,
    List<FeedItem>? relatedContent,
    VideoPlayerController? videoController,
    ChewieController? chewieController,
    YoutubePlayerController? ytController,
    GlobalKey? playerKey,
    bool? isFloating,
    bool? isYouTube,
    bool? isPlaying,
  }) {
    return GlobalPlayerState(
      currentItem: currentItem ?? this.currentItem,
      relatedContent: relatedContent ?? this.relatedContent,
      videoController: videoController ?? this.videoController,
      chewieController: chewieController ?? this.chewieController,
      ytController: ytController ?? this.ytController,
      playerKey: playerKey ?? this.playerKey,
      isFloating: isFloating ?? this.isFloating,
      isYouTube: isYouTube ?? this.isYouTube,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

class GlobalPlayerNotifier extends StateNotifier<GlobalPlayerState> {
  GlobalPlayerNotifier() : super(GlobalPlayerState());

  // Use a static key so it never changes during the app session
  static final GlobalKey _sharedPlayerKey = GlobalKey();

  void setPlayer({
    required FeedItem item,
    required List<FeedItem> related,
    VideoPlayerController? video,
    ChewieController? chewie,
    YoutubePlayerController? yt,
    required bool isYouTube,
  }) {
    // If it's already the same item, don't reset to avoid restarts
    if (state.currentItem?.id == item.id &&
        (state.videoController != null || state.ytController != null)) {
      return;
    }

    state = state.copyWith(
      currentItem: item,
      relatedContent: related,
      videoController: video,
      chewieController: chewie,
      ytController: yt,
      playerKey: _sharedPlayerKey,
      isYouTube: isYouTube,
      isFloating: false,
      isPlaying: true,
    );
  }

  void togglePlayPause() {
    bool nextPlayState = !state.isPlaying;
    if (state.isYouTube) {
      if (nextPlayState)
        state.ytController?.play();
      else
        state.ytController?.pause();
    } else {
      if (nextPlayState)
        state.videoController?.play();
      else
        state.videoController?.pause();
    }
    state = state.copyWith(isPlaying: nextPlayState);
  }

  void switchToPiP() {
    if (state.currentItem != null) {
      state = state.copyWith(isFloating: true);
    }
  }

  void restoreFromPiP() {
    state = state.copyWith(isFloating: false);
  }

  void closePlayer() {
    state.videoController?.dispose();
    state.chewieController?.dispose();
    state.ytController?.dispose();
    state = GlobalPlayerState(isPlaying: false);
  }
}

final globalPlayerProvider =
    StateNotifierProvider<GlobalPlayerNotifier, GlobalPlayerState>((ref) {
  return GlobalPlayerNotifier();
});
