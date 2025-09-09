import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final String? placeholder;

  const CustomVideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.placeholder,
  }) : super(key: key);

  @override
  State<CustomVideoPlayerWidget> createState() => _CustomVideoPlayerWidgetState();
}

class _CustomVideoPlayerWidgetState extends State<CustomVideoPlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _isInitialized = false;
      });

      if (widget.videoUrl.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video URL is empty';
        });
        return;
      }

      print('Initializing video with URL: ${widget.videoUrl}');

      // Dispose previous controller
      await _videoPlayerController?.dispose();

      if (widget.videoUrl.startsWith('http')) {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          httpHeaders: {
            'User-Agent': 'Mozilla/5.0 (compatible; VideoPlayer/1.0)',
            'Access-Control-Allow-Origin': '*',
          },
        );
      } else {
        _videoPlayerController = VideoPlayerController.asset(widget.videoUrl);
      }

      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Video initialization timeout.');
        },
      );

      if (!_videoPlayerController!.value.isInitialized) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize video.';
        });
        return;
      }

      if (_videoPlayerController!.value.hasError) {
        setState(() {
          _hasError = true;
          _errorMessage = _videoPlayerController!.value.errorDescription ?? 'Video error';
        });
        return;
      }

      setState(() {
        _isInitialized = true;
        _hasError = false;
      });

      print('Video initialized successfully');

    } catch (e) {
      print('Error initializing video player: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading video: ${e.toString()}';
      });
    }
  }

  Widget _buildThumbnail() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern or thumbnail
          if (_isInitialized && !_hasError)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VideoPlayer(_videoPlayerController!),
              ),
            ),
          
          // Dark overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),
          
          // Play button
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 50,
                color: Colors.red.shade600,
              ),
            ),
          ),
          
          // Duration badge (if video is initialized)
          if (_isInitialized && !_hasError)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(_videoPlayerController!.value.duration),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          
          // Error overlay
          if (_hasError)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade400,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Video Error',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Loading overlay
          if (!_isInitialized && !_hasError)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading video...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openVideoDialog() {
    if (!_isInitialized || _hasError) {
      // Show error or retry
      _showErrorDialog();
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (context) => _VideoDialog(
        videoController: _videoPlayerController!,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Video Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeVideoPlayer();
            },
            child: Text('Retry', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openVideoDialog,
      child: Container(
        width: double.infinity,
        height: 200, // Fixed height for consistency
        child: _buildThumbnail(),
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }
}

class _VideoDialog extends StatefulWidget {
  final VideoPlayerController videoController;
  final bool autoPlay;
  final bool looping;

  const _VideoDialog({
    Key? key,
    required this.videoController,
    required this.autoPlay,
    required this.looping,
  }) : super(key: key);

  @override
  State<_VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<_VideoDialog> {
  ChewieController? _chewieController;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeChewieController();
  }

  void _initializeChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: widget.videoController,
      autoPlay: widget.autoPlay,
      looping: widget.looping,
      showControls: true,
      allowFullScreen: false,
      allowMuting: true,
      allowPlaybackSpeedChanging: true,
      aspectRatio: widget.videoController.value.aspectRatio,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        handleColor: Colors.red,
        backgroundColor: Colors.grey.shade600,
        bufferedColor: Colors.grey.shade400,
      ),
      placeholder: Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      ),
    );

    // Auto-hide controls after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Video Player
            Center(
              child: _chewieController != null
                  ? AspectRatio(
                      aspectRatio: widget.videoController.value.aspectRatio,
                      child: Chewie(controller: _chewieController!),
                    )
                  : CircularProgressIndicator(color: Colors.red),
            ),
            
            // Close button
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  widget.videoController.pause();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    super.dispose();
  }
}