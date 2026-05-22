import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BreathPhase { inhale, holdIn, exhale, holdOut }

class BreathingTechnique {
  final String name;
  final String description;
  final int inhaleSeconds;
  final int holdInSeconds;
  final int exhaleSeconds;
  final int holdOutSeconds;

  const BreathingTechnique({
    required this.name,
    required this.description,
    required this.inhaleSeconds,
    required this.holdInSeconds,
    required this.exhaleSeconds,
    required this.holdOutSeconds,
  });
}

class BreathScreen extends StatefulWidget {
  const BreathScreen({super.key});

  @override
  State<BreathScreen> createState() => _BreathScreenState();
}

class _BreathScreenState extends State<BreathScreen> with SingleTickerProviderStateMixin {
  static const List<BreathingTechnique> _techniques = [
    BreathingTechnique(
      name: "Box Breathing",
      description: "Ideal for clearing the mind, focusing attention, and lowering stress levels.",
      inhaleSeconds: 4,
      holdInSeconds: 4,
      exhaleSeconds: 4,
      holdOutSeconds: 4,
    ),
    BreathingTechnique(
      name: "4-7-8 Breath (Relax)",
      description: "Acts as a natural tranquilizer for the nervous system, helpful for falling asleep.",
      inhaleSeconds: 4,
      holdInSeconds: 7,
      exhaleSeconds: 8,
      holdOutSeconds: 0,
    ),
    BreathingTechnique(
      name: "Equal Breathing",
      description: "A great standard technique for balance and steadying heart rate.",
      inhaleSeconds: 5,
      holdInSeconds: 0,
      exhaleSeconds: 5,
      holdOutSeconds: 0,
    ),
  ];

  late BreathingTechnique _selectedTechnique;
  late AnimationController _animController;
  
  // State variables
  bool _isPlaying = false;
  BreathPhase _currentPhase = BreathPhase.inhale;
  int _secondsRemaining = 4;
  Timer? _timer;
  int _completedCycles = 0;

  @override
  void initState() {
    super.initState();
    _selectedTechnique = _techniques[0];
    _secondsRemaining = _selectedTechnique.inhaleSeconds;
    
    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _selectedTechnique.inhaleSeconds),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _isPlaying = true;
      _completedCycles = 0;
      _currentPhase = BreathPhase.inhale;
      _secondsRemaining = _selectedTechnique.inhaleSeconds;
    });
    
    _runPhase();
  }

  void _stopBreathing() {
    _timer?.cancel();
    _animController.stop();
    _animController.reset();
    setState(() {
      _isPlaying = false;
      _currentPhase = BreathPhase.inhale;
      _secondsRemaining = _selectedTechnique.inhaleSeconds;
    });
  }

  void _runPhase() {
    _timer?.cancel();
    
    int duration;

    switch (_currentPhase) {
      case BreathPhase.inhale:
        duration = _selectedTechnique.inhaleSeconds;
        _animController.duration = Duration(seconds: duration);
        _animController.forward(from: 0.0);
        break;
      case BreathPhase.holdIn:
        duration = _selectedTechnique.holdInSeconds;
        _animController.duration = Duration(seconds: duration);
        // Remains expanded
        break;
      case BreathPhase.exhale:
        duration = _selectedTechnique.exhaleSeconds;
        _animController.duration = Duration(seconds: duration);
        _animController.reverse(from: 1.0);
        break;
      case BreathPhase.holdOut:
        duration = _selectedTechnique.holdOutSeconds;
        _animController.duration = Duration(seconds: duration);
        // Remains contracted
        break;
    }

    setState(() {
      _secondsRemaining = duration;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _transitionToNextPhase();
      }
    });
  }

  void _transitionToNextPhase() {
    if (!mounted || !_isPlaying) return;

    setState(() {
      switch (_currentPhase) {
        case BreathPhase.inhale:
          if (_selectedTechnique.holdInSeconds > 0) {
            _currentPhase = BreathPhase.holdIn;
          } else {
            _currentPhase = BreathPhase.exhale;
          }
          break;
        case BreathPhase.holdIn:
          _currentPhase = BreathPhase.exhale;
          break;
        case BreathPhase.exhale:
          if (_selectedTechnique.holdOutSeconds > 0) {
            _currentPhase = BreathPhase.holdOut;
          } else {
            _currentPhase = BreathPhase.inhale;
            _completedCycles++;
          }
          break;
        case BreathPhase.holdOut:
          _currentPhase = BreathPhase.inhale;
          _completedCycles++;
          break;
      }
    });

    _runPhase();
  }

  String _getPhaseText() {
    switch (_currentPhase) {
      case BreathPhase.inhale:
        return "Breathe In";
      case BreathPhase.holdIn:
        return "Hold";
      case BreathPhase.exhale:
        return "Breathe Out";
      case BreathPhase.holdOut:
        return "Hold & Rest";
    }
  }

  Color _getPhaseColor() {
    switch (_currentPhase) {
      case BreathPhase.inhale:
        return const Color(0xFF34D399); // Soft Emerald
      case BreathPhase.holdIn:
        return const Color(0xFF3B82F6); // Soft Ocean Blue
      case BreathPhase.exhale:
        return const Color(0xFF8B5CF6); // Soft Violet
      case BreathPhase.holdOut:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Deep Breath',
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
            children: [
              const SizedBox(height: 16),
              
              // Technique Selector (dropdown)
              if (!_isPlaying) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155).withOpacity(0.5) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BreathingTechnique>(
                        value: _selectedTechnique,
                        icon: const Icon(Icons.arrow_drop_down),
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        items: _techniques.map((tech) {
                          return DropdownMenuItem<BreathingTechnique>(
                            value: tech,
                            child: Text(
                              tech.name,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (tech) {
                          if (tech != null) {
                            setState(() {
                              _selectedTechnique = tech;
                              _secondsRemaining = tech.inhaleSeconds;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    _selectedTechnique.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ] else ...[
                // Active indicators
                Text(
                  _selectedTechnique.name,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Completed Cycles: $_completedCycles",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
              
              const Spacer(),

              // Breathing Animation Circle
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  // Grow circle from 140 to 280 logical pixels in diameter based on animation val
                  final scale = 0.6 + (_animController.value * 0.4);
                  
                  return Container(
                    height: 300,
                    width: 300,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft Dynamic Glow Ring
                        Container(
                          height: 250 * scale,
                          width: 250 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            boxShadow: [
                              BoxShadow(
                                color: _getPhaseColor().withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 10 * scale,
                              ),
                            ],
                          ),
                        ),
                        // Inner Calming Circle
                        Container(
                          height: 220 * scale,
                          width: 220 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _getPhaseColor().withOpacity(0.85),
                                _getPhaseColor().withOpacity(0.45),
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            height: 212 * scale,
                            width: 212 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getPhaseText(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 22 * (0.8 + (scale * 0.2)),
                                    fontWeight: FontWeight.bold,
                                    color: _getPhaseColor(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "$_secondsRemaining",
                                  style: GoogleFonts.outfit(
                                    fontSize: 48 * (0.8 + (scale * 0.2)),
                                    fontWeight: FontWeight.w300,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(),

              // Action Button
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: SizedBox(
                  width: 200,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isPlaying ? _stopBreathing : _startBreathing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying ? Colors.redAccent.withOpacity(0.8) : const Color(0xFF34D399),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      _isPlaying ? "End Session" : "Begin Breathing",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
