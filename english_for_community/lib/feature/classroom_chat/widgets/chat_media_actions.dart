import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/core/util/file_download.dart';
import 'package:english_for_community/core/utils/global_keys.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Open chat attachments: images/videos in-app, documents download.
class ChatMediaActions {
  ChatMediaActions._();

  static BuildContext _dialogContext(BuildContext context) =>
      rootNavigatorKey.currentContext ?? context;

  static void openMessageMedia(BuildContext context, ClassroomChatMessage message) {
    final media = message.media;
    if (media == null || media.url.isEmpty) return;

    switch (message.type) {
      case ChatMessageType.image:
        openImage(context, url: media.url);
      case ChatMessageType.video:
        openVideo(context, media: media);
      case ChatMessageType.file:
        downloadFile(context, media: media);
      case ChatMessageType.text:
        break;
    }
  }

  static void openImage(BuildContext context, {required String url}) {
    if (url.isEmpty) return;
    showDialog<void>(
      context: _dialogContext(context),
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => _ChatImageViewer(url: url),
    );
  }

  static void openVideo(BuildContext context, {required ChatMedia media}) {
    if (media.url.isEmpty) return;
    showDialog<void>(
      context: _dialogContext(context),
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => _ChatVideoViewer(media: media),
    );
  }

  static Future<void> downloadFile(BuildContext context, {required ChatMedia media}) async {
    if (media.url.isEmpty) return;
    final l10n = context.l10n;
    AppFeedback.success(context, l10n.chatMediaDownloading);

    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        media.url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw StateError('empty response');
      }

      final filename = media.name.trim().isNotEmpty ? media.name.trim() : 'file';
      await downloadBytes(
        filename: filename,
        bytes: bytes,
        mimeType: media.mimeType.isNotEmpty ? media.mimeType : null,
      );

      if (context.mounted) {
        AppFeedback.success(context, l10n.chatMediaDownloadDone);
      }
    } catch (_) {
      if (context.mounted) {
        AppFeedback.error(context, l10n.chatMediaDownloadFailed);
      }
    }
  }
}

class _ChatImageViewer extends StatelessWidget {
  const _ChatImageViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => const AppLoadingIndicator.center(color: Colors.white),
              errorWidget: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white70,
                size: 48,
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 12,
          child: SafeArea(
            child: Material(
              color: Colors.black45,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatVideoViewer extends StatefulWidget {
  const _ChatVideoViewer({required this.media});

  final ChatMedia media;

  @override
  State<_ChatVideoViewer> createState() => _ChatVideoViewerState();
}

class _ChatVideoViewerState extends State<_ChatVideoViewer> {
  late final VideoPlayerController _controller;
  var _initialized = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.media.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _controller.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _failed = true);
      });
    _controller.addListener(_onVideoUpdate);
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_initialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (_failed)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.chatMediaVideoLoadFailed,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          )
        else if (!_initialized)
          const AppLoadingIndicator.center(color: Colors.white)
        else
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio == 0
                ? 16 / 9
                : _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        if (_initialized && !_failed)
          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePlay,
              behavior: HitTestBehavior.translucent,
              child: AnimatedOpacity(
                opacity: _controller.value.isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 72,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 16,
          right: 12,
          child: SafeArea(
            child: Material(
              color: Colors.black45,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
        if (widget.media.name.isNotEmpty)
          Positioned(
            left: 16,
            right: 56,
            bottom: 16,
            child: SafeArea(
              child: Text(
                widget.media.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }
}

/// Visual hint that bubble media is tappable.
class ChatMediaTapTarget extends StatelessWidget {
  const ChatMediaTapTarget({
    super.key,
    required this.onTap,
    required this.child,
    this.showPlayOverlay = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool showPlayOverlay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppColors.primaryStrong,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.passthrough,
          children: [
            child,
            if (showPlayOverlay)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.28),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
