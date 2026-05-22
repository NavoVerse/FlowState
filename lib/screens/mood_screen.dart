import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/mood_log.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final _noteController = TextEditingController();
  
  // Selection state
  double _score = 4.0; // 1 to 5
  String _selectedMoodType = "Calm";

  final List<Map<String, dynamic>> _moodTypes = [
    {'type': 'Sad', 'emoji': '🌧️', 'label': 'Sad', 'color': const Color(0xFF5C78FF)},
    {'type': 'Anxious', 'emoji': '🌀', 'label': 'Anxious', 'color': const Color(0xFF9E7CFF)},
    {'type': 'Neutral', 'emoji': '🍃', 'label': 'Neutral', 'color': const Color(0xFF8FA382)},
    {'type': 'Calm', 'emoji': '🧘', 'label': 'Calm', 'color': const Color(0xFF4DB6AC)},
    {'type': 'Happy', 'emoji': '☀️', 'label': 'Happy', 'color': const Color(0xFFFFB74D)},
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveMood(String userId) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    
    try {
      await dbService.addMoodLog(
        userId,
        _score,
        _noteController.text.trim(),
        _selectedMoodType,
      );
      
      _noteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged successfully. Breathe easy.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFF4DB6AC),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save mood log. Try again.', style: GoogleFonts.inter()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Color _getCurrentColor() {
    return _moodTypes.firstWhere((m) => m['type'] == _selectedMoodType)['color'];
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dbService = Provider.of<DatabaseService>(context);
    final userId = authService.currentUser?.uid ?? 'guest';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mood Space',
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
              // Log New Mood Section (collapsible card)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155).withValues(alpha: 0.35) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getCurrentColor().withValues(alpha: 0.08),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "How is your mind breathing today?",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Emojis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _moodTypes.map((m) {
                          final isSelected = m['type'] == _selectedMoodType;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMoodType = m['type'];
                                // Automatically adjust score corresponding to mood
                                switch (m['type']) {
                                  case 'Sad': _score = 1.0; break;
                                  case 'Anxious': _score = 2.0; break;
                                  case 'Neutral': _score = 3.0; break;
                                  case 'Calm': _score = 4.0; break;
                                  case 'Happy': _score = 5.0; break;
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? m['color'].withValues(alpha: 0.2)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? m['color'] : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    m['emoji'],
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    m['label'],
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected 
                                          ? (isDark ? Colors.white : const Color(0xFF1E293B))
                                          : (isDark ? Colors.white38 : Colors.black38),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Text input notes
                      TextField(
                        controller: _noteController,
                        maxLines: 2,
                        maxLength: 140,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Add a brief calming thought or note...",
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          counterText: "",
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Save button
                      ElevatedButton(
                        onPressed: () => _saveMood(userId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getCurrentColor(),
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Log This Moment",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Title for History
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                child: Text(
                  "Your Peaceful Journey",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),

              // List of logs
              Expanded(
                child: StreamBuilder<List<MoodLog>>(
                  stream: dbService.getMoodLogs(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final logs = snapshot.data ?? [];

                    if (logs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "🌱",
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No mood logs yet.",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                              Text(
                                "Log your first mood above to start tracking your mindfulness journey.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? Colors.white30 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final timeString = DateFormat('MMMM d, h:mm a').format(log.timestamp);
                        final cardColor = Color(log.colorHex);
                        
                        return Dismissible(
                          key: Key(log.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            dbService.deleteMoodLog(log.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Moment log deleted.', style: GoogleFonts.inter()),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Emoji badge
                                Container(
                                  height: 48,
                                  width: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: cardColor.withValues(alpha: 0.15),
                                    border: Border.all(color: cardColor.withValues(alpha: 0.3), width: 1),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    log.emoji,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Text details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            log.moodType,
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: cardColor,
                                            ),
                                          ),
                                          Text(
                                            timeString,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: isDark ? Colors.white30 : Colors.black38,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        log.note.isEmpty ? "No reflection notes added." : log.note,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontStyle: log.note.isEmpty ? FontStyle.italic : FontStyle.normal,
                                          color: log.note.isEmpty 
                                              ? (isDark ? Colors.white30 : Colors.black38)
                                              : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
