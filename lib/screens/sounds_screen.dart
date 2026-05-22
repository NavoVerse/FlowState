import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';

class SoundTrack {
  final String title;
  final String category;
  final String url;
  final IconData icon;
  final Color color;

  const SoundTrack({
    required this.title,
    required this.category,
    required this.url,
    required this.icon,
    required this.color,
  });
}

class SoundsScreen extends StatefulWidget {
  const SoundsScreen({super.key});

  @override
  State<SoundsScreen> createState() => _SoundsScreenState();
}

class _SoundsScreenState extends State<SoundsScreen> {
  late AudioPlayer _audioPlayer;
  
  // State variables
  String? _playingTrackUrl;
  bool _isPlaying = false;
  double _volume = 0.5;
  bool _isLoading = false;

  final List<SoundTrack> _tracks = const [
    SoundTrack(
      title: "Rain showers",
      category: "Nature",
      url: "https://www.soundjay.com/nature/sounds/rain-07.mp3",
      icon: Icons.umbrella_outlined,
      color: Color(0xFF5C78FF),
    ),
    SoundTrack(
      title: "Ocean Waves",
      category: "Water",
      url: "https://www.soundjay.com/nature/sounds/ocean-wave-1.mp3",
      icon: Icons.water_outlined,
      color: Color(0xFF4DB6AC),
    ),
    SoundTrack(
      title: "Forest Wind",
      category: "Wind",
      url: "https://www.soundjay.com/nature/sounds/forest-wind-1.mp3",
      icon: Icons.forest_outlined,
      color: Color(0xFF8FA382),
    ),
    SoundTrack(
      title: "Gentle White Noise",
      category: "Ambient",
      url: "https://www.soundjay.com/misc/sounds/white-noise-1.mp3",
      icon: Icons.waves_outlined,
      color: Color(0xFFFFB74D),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.setVolume(_volume);

    // Audio status listeners
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.stopped || state == PlayerState.completed) {
            _playingTrackUrl = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(SoundTrack track) async {
    if (_playingTrackUrl == track.url) {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() => _isLoading = true);
        try {
          await _audioPlayer.resume();
        } catch (e) {
          _showErrorSnackBar();
        } finally {
          setState(() => _isLoading = false);
        }
      }
    } else {
      // Play a new track
      setState(() {
        _isLoading = true;
        _playingTrackUrl = track.url;
      });

      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(track.url));
        await _audioPlayer.setVolume(_volume);
      } catch (e) {
        _showErrorSnackBar();
        setState(() {
          _playingTrackUrl = null;
          _isPlaying = false;
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Streaming failed. Check connection or try another track.',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _setVolume(double newVolume) async {
    setState(() {
      _volume = newVolume;
    });
    await _audioPlayer.setVolume(newVolume);
  }

  Future<void> _stopAll() async {
    await _audioPlayer.stop();
    setState(() {
      _playingTrackUrl = null;
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ambient Soundscapes',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Calming introduction card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155).withOpacity(0.3) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Focus your mind",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Overlay a soothing ambient layer to wash away distracting noises and settle your nervous system.",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "🎧",
                        style: const TextStyle(fontSize: 40),
                      ),
                    ],
                  ),
                ),
              ),

              // Volume Slider (only shown when something is active)
              if (_playingTrackUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF34D399).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _volume == 0
                              ? Icons.volume_mute_outlined
                              : _volume < 0.5
                                  ? Icons.volume_down_outlined
                                  : Icons.volume_up_outlined,
                          color: const Color(0xFF34D399),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Soundscape volume",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFF34D399),
                                  inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
                                  thumbColor: const Color(0xFF34D399),
                                  overlayColor: const Color(0xFF34D399).withOpacity(0.2),
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  value: _volume,
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: _setVolume,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent, size: 28),
                          onPressed: _stopAll,
                          tooltip: "Stop Soundscape",
                        )
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Tracks List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    final isCurrent = _playingTrackUrl == track.url;
                    
                    return GestureDetector(
                      onTap: _isLoading ? null : () => _togglePlay(track),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        padding: const EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (isCurrent
                                  ? track.color.withOpacity(0.08)
                                  : const Color(0xFF334155).withOpacity(0.25))
                              : (isCurrent
                                  ? track.color.withOpacity(0.08)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isCurrent 
                                ? track.color.withOpacity(0.6) 
                                : (isDark ? Colors.white10 : Colors.black12),
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Circular icon badge
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent 
                                    ? track.color.withOpacity(0.2) 
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              ),
                              child: Icon(
                                track.icon,
                                color: isCurrent ? track.color : (isDark ? Colors.white54 : Colors.black54),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 18),

                            // Track Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.category.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                      color: isCurrent ? track.color : (isDark ? Colors.white30 : Colors.black38),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    track.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Play / Pause Indicator
                            if (isCurrent && _isLoading)
                              const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                                ),
                              )
                            else if (isCurrent && _isPlaying)
                              // Pulsing Waveform effect using Icons
                              Icon(
                                Icons.volume_up,
                                color: track.color,
                                size: 28,
                              )
                            else
                              Icon(
                                isCurrent ? Icons.play_arrow : Icons.play_arrow_outlined,
                                color: isDark ? Colors.white38 : Colors.black38,
                                size: 28,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
