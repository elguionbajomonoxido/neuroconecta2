import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MediaViewer extends StatefulWidget {
  final String? url;

  const MediaViewer({super.key, this.url});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;

  bool _isVideo = false;
  bool _isYoutube = false;
  bool _isDisposed = false;

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

  /// Extrae el ID de Google Drive de varios formatos de URL
  String? _getDriveId(String url) {
    final RegExp regExp = RegExp(r"\/d\/(.+?)\/|id=(.+?)(&|$)");
    final match = regExp.firstMatch(url);
    return match?.group(1) ?? match?.group(2);
  }

  /// Convierte URL de Drive a URL de descarga directa para visualización
  String _getDisplayUrl(String url) {
    if (url.contains('drive.google.com')) {
      final id = _getDriveId(url);
      if (id != null) {
        return 'https://drive.google.com/uc?export=view&id=$id';
      }
    }
    return url;
  }

  void _initializeMedia() {
    if (_isDisposed) return;
    if (widget.url == null || widget.url!.isEmpty) return;

    final url = widget.url!;
    final lowerUrl = url.toLowerCase();

    // 1. Check YouTube
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      _isYoutube = true;
      _isVideo = false;
      _initializeYoutubePlayer(videoId);
      return;
    }

    // 2. Check Video Files
    if (lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.avi') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.mkv')) {
      _isVideo = true;
      _isYoutube = false;
      _initializeVideoPlayer();
    } else {
      // 3. Assume Image
      _isVideo = false;
      _isYoutube = false;
      if (mounted) setState(() {});
    }
  }

  void _initializeYoutubePlayer(String videoId) {
    if (_isDisposed) return;

    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
      ),
    );

    if (!mounted || _isDisposed) {
      controller.dispose();
      return;
    }

    _youtubeController = controller;
    setState(() {});
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      if (_isDisposed) return;

      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.url!));

      await controller.initialize();

      if (_isDisposed || !mounted) {
        controller.dispose();
        return;
      }

      _videoPlayerController = controller;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: const Center(
            child: CircularProgressIndicator(color: Colors.white)),
        errorBuilder: (context, errorMessage) {
          return _buildErrorWidget(errorMessage);
        },
      );

      if (mounted && !_isDisposed) {
        setState(() {});
      } else {
        _disposeControllers();
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  void _disposeControllers() {
    if (_videoPlayerController != null) {
      final vController = _videoPlayerController!;
      _videoPlayerController = null;
      try {
        vController.dispose();
      } catch (e) {
        debugPrint('Error disposing VideoPlayer: $e');
      }
    }

    if (_chewieController != null) {
      final cController = _chewieController!;
      _chewieController = null;
      try {
        cController.dispose();
      } catch (e) {
        debugPrint('Error disposing Chewie: $e');
      }
    }

    if (_youtubeController != null) {
      final yController = _youtubeController!;
      _youtubeController = null;
      try {
        yController.dispose();
      } catch (e) {
        debugPrint('Error disposing YoutubePlayer: $e');
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeControllers();
    super.dispose();
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          Text(
            'No se pudo cargar el contenido',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _disposeControllers();
              _initializeMedia();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 16,
      child: Material(
        color: Colors.black45, // Fondo semitransparente
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Cerrar',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return const SizedBox.shrink();

    if (widget.url == null || widget.url!.isEmpty) {
      return const Scaffold(
          backgroundColor: Colors.black, body: SizedBox.shrink());
    }

    // --- YOUTUBE ---
    if (_isYoutube) {
      if (_youtubeController != null) {
        return YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.red,
            progressColors: const ProgressBarColors(
              playedColor: Colors.red,
              handleColor: Colors.redAccent,
            ),
          ),
          builder: (context, player) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Center(child: player),
                  // Botón de cierre flotante (solo visible si no está en fullscreen nativo)
                  _buildCloseButton(context),
                ],
              ),
            );
          },
        );
      } else {
        return Scaffold(
            backgroundColor: Colors.black, body: _buildLoading());
      }
    }

    // --- VIDEO DIRECTO ---
    if (_isVideo) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: (_chewieController != null &&
                      _videoPlayerController != null &&
                      _videoPlayerController!.value.isInitialized)
                  ? AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: Chewie(controller: _chewieController!),
                    )
                  : _buildLoading(),
            ),
            _buildCloseButton(context),
          ],
        ),
      );
    }

    // --- IMAGEN (Drive / Network) ---
    final displayUrl = _getDisplayUrl(widget.url!);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: displayUrl,
                fadeInDuration: const Duration(milliseconds: 300),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => _buildLoading(),
                errorWidget: (context, url, error) =>
                    _buildErrorWidget(error.toString()),
              ),
            ),
          ),
          _buildCloseButton(context),
        ],
      ),
    );
  }
}
