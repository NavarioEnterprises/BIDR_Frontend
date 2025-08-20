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
  _CustomVideoPlayerWidgetState createState() => _CustomVideoPlayerWidgetState();
}

class _CustomVideoPlayerWidgetState extends State<CustomVideoPlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = false;
  bool _isBuffering = false;
  bool _hasError = false;
  String _errorMessage = '';
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      // Reset error state
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _isInitialized = false;
      });

      // Validate URL
      if (widget.videoUrl.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video URL is empty';
        });
        return;
      }

      print('Initializing video with URL: ${widget.videoUrl}');

      // Dispose previous controllers
      await _disposeControllers();

      // Validate URL format and accessibility
      if (widget.videoUrl.startsWith('http')) {
        // Check if URL is accessible
        try {
          final uri = Uri.parse(widget.videoUrl);
          if (!uri.hasAbsolutePath) {
            throw Exception('Invalid URL format');
          }
        } catch (e) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Invalid video URL format: ${widget.videoUrl}';
          });
          return;
        }

        // Use the correct method for network videos
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

      // Initialize the controller with timeout
      await _videoPlayerController!.initialize().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Video initialization timeout. Please check your internet connection.');
        },
      );

      // Check if the video was initialized successfully
      if (!_videoPlayerController!.value.isInitialized) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize video. The video format may not be supported or the URL is invalid.';
        });
        return;
      }

      // Additional validation
      if (_videoPlayerController!.value.hasError) {
        setState(() {
          _hasError = true;
          _errorMessage = _videoPlayerController!.value.errorDescription ??
              'Video source not supported. Please check the video URL and format.';
        });
        return;
      }

      // Create Chewie controller
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        showControls: false, // We'll create custom controls
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: widget.placeholder != null
            ? Container(
          color: Colors.black,
          child: Center(
            child: Text(
              widget.placeholder!,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        )
            : Container(
          color: Colors.black,
          child: Center(
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  SizedBox(height: 16),
                  Text(
                    'Error loading video',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Add listeners
      _videoPlayerController!.addListener(_videoListener);

      setState(() {
        _isInitialized = true;
        _totalDuration = _videoPlayerController!.value.duration;
        _isPlaying = _videoPlayerController!.value.isPlaying;
        _hasError = false;
      });

      print('Video initialized successfully. Duration: $_totalDuration');

      // Auto-hide controls after 3 seconds
      if (widget.autoPlay) {
        _autoHideControls();
      }
    } catch (e) {
      print('Error initializing video player: $e');

      String errorMessage;
      if (e.toString().contains('MEDIA_ERR_SRC_NOT_SUPPORTED')) {
        errorMessage = 'Video format not supported. Please try a different video URL or format (MP4, WebM recommended).';
      } else if (e.toString().contains('NetworkException') || e.toString().contains('timeout')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        errorMessage = 'Access denied. The video URL may be restricted.';
      } else if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        errorMessage = 'Video not found. Please check the URL.';
      } else {
        errorMessage = 'Error loading video: ${e.toString()}';
      }

      setState(() {
        _hasError = true;
        _errorMessage = errorMessage;
      });
    }
  }

  Future<void> _disposeControllers() async {
    _videoPlayerController?.removeListener(_videoListener);
    _chewieController?.dispose();
    await _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
  }

  void _videoListener() {
    if (mounted && _videoPlayerController != null) {
      final controller = _videoPlayerController!;
      setState(() {
        _isPlaying = controller.value.isPlaying;
        _isBuffering = controller.value.isBuffering;
        _currentPosition = controller.value.position;
        _volume = controller.value.volume;

        // Check for errors
        if (controller.value.hasError) {
          _hasError = true;
          _errorMessage = controller.value.errorDescription ?? 'Unknown error';
        }
      });
    }
  }

  void _togglePlayPause() {
    if (_videoPlayerController == null) return;

    setState(() {
      if (_isPlaying) {
        _videoPlayerController!.pause();
      } else {
        _videoPlayerController!.play();
      }
    });
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _autoHideControls();
  }

  void _autoHideControls() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _seekTo(Duration position) {
    if (_videoPlayerController == null) return;
    _videoPlayerController!.seekTo(position);
    _showControlsTemporarily();
  }

  void _changeVolume(double volume) {
    if (_videoPlayerController == null) return;
    setState(() {
      _volume = volume;
    });
    _videoPlayerController!.setVolume(volume);
  }

  void _changePlaybackSpeed(double speed) {
    if (_videoPlayerController == null) return;
    setState(() {
      _playbackSpeed = speed;
    });
    _videoPlayerController!.setPlaybackSpeed(speed);
    _showControlsTemporarily();
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
    // Show error state
    if (_hasError) {
      return Column(
        children: [
          Expanded(
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 20),
                      SizedBox(height: 12),
                      Text(
                        'Error loading video',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _initializeVideoPlayer();
                            },
                            child: Text('Retry', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                          SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _showVideoHelp(),
                            child: Text(
                              'Help',
                              style: TextStyle(color: Colors.orange, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Show loading state
    if (!_isInitialized || _chewieController == null) {
      return Column(
        children: [
          Expanded(
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.orange),
                      SizedBox(height: 12),
                      Text(
                        'Loading video...',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            height: 300,
            child: Stack(
              children: [
                // Video Player
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showControls = !_showControls;
                    });
                    if (_showControls) {
                      _autoHideControls();
                    }
                  },
                  child: Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Chewie(controller: _chewieController!),
                    ),
                  ),
                ),

                // Central Play/Pause Button
                Center(
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),

                // Buffering Indicator
                if (_isBuffering)
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.orange,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),

                // Bottom Controls - Simplified
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress Bar
                          Row(
                            children: [
                              Text(
                                _formatDuration(_currentPosition),
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.orange,
                                    inactiveTrackColor: Colors.grey.withOpacity(0.5),
                                    thumbColor: Colors.orange,
                                    overlayColor: Colors.orange.withOpacity(0.3),
                                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4),
                                    trackHeight: 2,
                                  ),
                                  child: Slider(
                                    value: _totalDuration.inMilliseconds > 0
                                        ? _currentPosition.inMilliseconds.toDouble()
                                        : 0.0,
                                    max: _totalDuration.inMilliseconds.toDouble(),
                                    onChanged: (value) {
                                      _seekTo(Duration(milliseconds: value.toInt()));
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                _formatDuration(_totalDuration),
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                              SizedBox(width: 8),
                              // Fullscreen button
                              GestureDetector(
                                onTap: _showFullscreenDialog,
                                child: Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isLarge ? 50 : 40,
        height: isLarge ? 50 : 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: isLarge ? Border.all(color: Colors.orange, width: 2) : null,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isLarge ? 30 : 20,
        ),
      ),
    );
  }

  void _showFullscreenDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  // Video Player
                  Center(
                    child: AspectRatio(
                      aspectRatio: _videoPlayerController?.value.aspectRatio ?? 16/9,
                      child: VideoPlayer(_videoPlayerController!),
                    ),
                  ),
                  
                  // Close button
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  
                  // Play/Pause overlay
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          if (_videoPlayerController!.value.isPlaying) {
                            _videoPlayerController!.pause();
                          } else {
                            _videoPlayerController!.play();
                          }
                        });
                        // Also update main widget state
                        setState(() {
                          _isPlaying = _videoPlayerController!.value.isPlaying;
                        });
                      },
                      child: AnimatedBuilder(
                        animation: _videoPlayerController!,
                        builder: (context, child) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _videoPlayerController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Bottom controls
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        // Progress bar
                        VideoProgressIndicator(
                          _videoPlayerController!,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: Colors.orange,
                            bufferedColor: Colors.grey,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        SizedBox(height: 10),
                        AnimatedBuilder(
                          animation: _videoPlayerController!,
                          builder: (context, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_videoPlayerController!.value.position),
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  _formatDuration(_videoPlayerController!.value.duration),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showVideoHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Video Playback Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Common solutions:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Ensure the video URL is direct and accessible'),
            Text('• Supported formats: MP4, WebM, MOV'),
            Text('• Check your internet connection'),
            Text('• Some websites block external video access'),
            Text('• Try using a different video URL'),
            SizedBox(height: 12),
            Text('Example working URLs:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }
}


