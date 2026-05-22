import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'breath_screen.dart';
import 'mood_screen.dart';
import 'sounds_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const HomeScreen({super.key, required this.toggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _dailyQuote;

  static const List<String> _affirmations = [
    "Breathing in, I calm my body. Breathing out, I smile.",
    "You do not have to control your thoughts. You just have to stop letting them control you.",
    "This stress is only temporary. I am capable, strong, and centered.",
    "With every breath, I release anxiety and invite peace into my heart.",
    "Slow down. You are doing just fine. Trust the journey.",
    "I am grounded, safe, and supported in this present moment.",
    "Peace begins with a single conscious breath.",
    "I am allowed to rest, recharge, and take care of my well-being.",
    "My mind is clear, my heart is calm, and my soul is at peace."
  ];

  @override
  void initState() {
    super.initState();
    _dailyQuote = _affirmations[Random().nextInt(_affirmations.length)];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final email = user?.email ?? 'Friend';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Greeting & Theme Toggle)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        Text(
                          email.split('@')[0],
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                          onPressed: widget.toggleTheme,
                          tooltip: "Toggle Theme",
                          color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_outlined),
                          onPressed: () => authService.signOut(),
                          tooltip: "Sign Out",
                          color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 32),

                // Daily Affirmation Card (Glassmorphism/Gradient)
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF34D399), // Emerald
                        Color(0xFF3B82F6), // Ocean Blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34D399).withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "DAILY AFFIRMATION",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const Icon(Icons.spa_outlined, color: Colors.white, size: 20),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '"$_dailyQuote"',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Core Feature Grid
                Text(
                  "Choose your flow",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.2 : 2.5,
                  children: [
                    _buildFeatureCard(
                      context,
                      title: "Deep Breathing",
                      subtitle: "Steady your breath and heart rate",
                      emoji: "🧘",
                      color: const Color(0xFF34D399),
                      destination: const BreathScreen(),
                      isDark: isDark,
                    ),
                    _buildFeatureCard(
                      context,
                      title: "Mood Space",
                      subtitle: "Track your emotions & progress",
                      emoji: "📝",
                      color: const Color(0xFF3B82F6),
                      destination: const MoodScreen(),
                      isDark: isDark,
                    ),
                    _buildFeatureCard(
                      context,
                      title: "Ambient Sounds",
                      subtitle: "Immerse in soothing loops",
                      emoji: "🎧",
                      color: const Color(0xFF8B5CF6),
                      destination: const SoundsScreen(),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Mindfulness Prompt / Tip
                Container(
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        "🌱",
                        style: TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mindful Minute",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Just taking a one-minute pause right now to feel the weight of your feet on the floor can restore balance.",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
    required Widget destination,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155).withValues(alpha: 0.25) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white30 : Colors.black26,
            )
          ],
        ),
      ),
    );
  }
}
