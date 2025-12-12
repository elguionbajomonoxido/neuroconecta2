import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MediaViewer extends StatefulWidget {
  final String? url;

  const MediaViewer({super.key, this.url});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void didUpdateWidget(MediaViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _disposeControllers();
      _initializeMedia();
    }
  }

  void _initializeMedia() {
    if (widget.url == null || widget.url!.isEmpty) return;

    final url = widget.url!.toLowerCase();
    // Simple check for video extensions. 
    // In a real app, you might want to check headers or use a more robust method.
    if (url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.avi') ||
        url.endsWith('.webm') ||
        url.endsWith('.mkv')) {
      _isVideo = true;
      _initializeVideoPlayer();
    } else {
      _isVideo = false;
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url!));
      await _videoPlayerController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error al reproducir video: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  void _disposeControllers() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = null;
    _chewieController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url == null || widget.url!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isVideo) {
      if (_chewieController != null && _videoPlayerController!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        );
      } else {
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      }
    } else {
      return CachedNetworkImage(
        imageUrl: widget.url!,
        placeholder: (context, url) => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => const SizedBox(
          height: 200,
          child: Center(child: Icon(Icons.error)),
        ),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
  }
}
