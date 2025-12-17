import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:neuroconecta2/widgets/adaptive_image.dart';

class MediaViewer extends StatefulWidget {
  final String? url;

  const MediaViewer({super.key, this.url});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  // YouTube state
  String? _youtubeVideoId;

  bool _isVideo = false;
  bool _isYoutube = false;
  bool _isUnsupported = false;
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
        // 'export=download' suele ser más fiable para obtener los bytes de la imagen
        return 'https://drive.google.com/uc?export=download&id=$id';
      }
    }
    return url;
  }

  String? _convertUrlToId(String url) {
    if (url.trim().isEmpty) return null;
    for (var exp in [
      RegExp(r"^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$"),
      RegExp(r"^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$")
    ]) {
      Match? match = exp.firstMatch(url);
      if (match != null && match.groupCount >= 1) return match.group(1);
    }
    return null;
  }

  void _initializeMedia() {
    if (_isDisposed) return;
    if (widget.url == null || widget.url!.isEmpty) return;

    final url = widget.url!;
    final lowerUrl = url.toLowerCase();

    // Reset flags
    _isVideo = false;
    _isYoutube = false;
    _isUnsupported = false;

    // 1. Check YouTube
    final videoId = _convertUrlToId(url);
    if (videoId != null) {
      _isYoutube = true;
      _youtubeVideoId = videoId;
      if (mounted) setState(() {});
      return;
    }

    // 2. Check Video Files
    if (lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.avi') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.mkv')) {
      _isVideo = true;
      _initializeVideoPlayer();
      return;
    }

    // 3. Check Drive
    if (url.contains('drive.google.com')) {
      // Asumimos que es imagen por defecto. Si falla, el errorWidget lo manejará.
      if (mounted) setState(() {});
      return;
    }

    // 4. Check Image extensions (para asegurar que es imagen directa)
    if (lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp') ||
        lowerUrl.endsWith('.bmp')) {
       if (mounted) setState(() {});
       return;
    }

    // Si no es nada de lo anterior, es un link no soportado
    _isUnsupported = true;
    if (mounted) setState(() {});
  }

  void _openFullscreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
          ),
          body: SizedBox.expand(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20.0),
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: AdaptiveImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullscreenYoutube(BuildContext context, String videoId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenYoutubePlayer(videoId: videoId),
      ),
    );
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
            'No se pudo cargar el contenido\n$error',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  if (widget.url != null) {
                    final uri = Uri.parse(widget.url!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return const SizedBox.shrink();

    if (widget.url == null || widget.url!.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('URL no válida', style: TextStyle(color: Colors.white))),
      );
    }

    // --- LINK NO SOPORTADO / EXTERNO ---
    if (_isUnsupported) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off, color: Colors.orangeAccent, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Enlace externo no visualizable',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.url!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(widget.url!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir en navegador'),
            ),
          ],
        ),
      );
    }

    // --- YOUTUBE ---
    if (_isYoutube && _youtubeVideoId != null) {
      final thumbnailUrl = 'https://img.youtube.com/vi/$_youtubeVideoId/hqdefault.jpg';
      return GestureDetector(
        onTap: () => _openFullscreenYoutube(context, _youtubeVideoId!),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AdaptiveImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- VIDEO DIRECTO ---
    if (_isVideo) {
      return Container(
        color: Colors.black,
        child: Center(
          child: (_chewieController != null &&
                  _videoPlayerController != null &&
                  _videoPlayerController!.value.isInitialized)
              ? AspectRatio(
                  aspectRatio: _videoPlayerController!.value.aspectRatio,
                  child: Chewie(controller: _chewieController!),
                )
              : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
        ),
      );
    }

    // --- IMAGEN (Drive / Network) ---
    final displayUrl = _getDisplayUrl(widget.url!);

    return GestureDetector(
      onTap: () => _openFullscreenImage(context, displayUrl),
      child: AdaptiveImage(
        imageUrl: displayUrl,
        fit: BoxFit.fitWidth,
        width: double.infinity,
      ),
    );
  }
}

class FullscreenYoutubePlayer extends StatefulWidget {
  final String videoId;
  const FullscreenYoutubePlayer({super.key, required this.videoId});

  @override
  State<FullscreenYoutubePlayer> createState() => _FullscreenYoutubePlayerState();
}

class _FullscreenYoutubePlayerState extends State<FullscreenYoutubePlayer> {
  late YoutubePlayerController _controller;
  bool _hasPlayerError = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
        origin: 'https://www.youtube-nocookie.com',
      ),
    );

    _controller.listen((value) {
      if (value.hasError) {
        if (mounted && !_hasPlayerError) {
          setState(() {
            _hasPlayerError = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPlayerError) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 40),
              const SizedBox(height: 10),
              const Text(
                "No se puede reproducir este video dentro de la app.",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final urlToOpen = "https://www.youtube.com/watch?v=${widget.videoId}";
                  final uri = Uri.parse(urlToOpen);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text("Abrir en YouTube"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          aspectRatio: 16 / 9,
        ),
      ),
    );
  }
}