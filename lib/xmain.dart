
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_mode_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_manager.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await AdManager.instance.initialize();
  }
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  // Enable edge-to-edge display (Android 15+)
  // Set system UI overlay style (Android only)
  if (!kIsWeb && Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }


  runApp(SnakesAndLaddersApp());
}

class SnakesAndLaddersApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snakes & Ladders Twisted',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        fontFamily: GoogleFonts.nunito().fontFamily,
      ),
      home: MainMenuScreen(),
    );
  }
}

// === MAIN MENU SCREEN ===
class MainMenuScreen extends StatefulWidget {
  @override
  _MainMenuScreenState createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  void _loadBannerAd() {
    // Only load ads on mobile platforms - ADD THIS CHECK
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      AdManager.instance.loadBannerAd(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad;
          });
        },
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column( // CHANGED: Column instead of single child
            children: [
              Expanded( // ADDED: Expanded wrapper
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Spacer(flex: 2),

                              // Game Logo/Title
                              _buildGameTitle(),
                              const SizedBox(height: 20),

                              // Subtitle
                              Text(
                                'Twisted Edition',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),

                              const Spacer(flex: 3),

                              // Menu Buttons
                              _buildMenuButtons(context),

                              const Spacer(flex: 2),

                              // Version Info
                              Text(
                                'Version 1.0.8',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Banner Ad at bottom - ADD THIS SECTION
              if (_bannerAd != null && !kIsWeb && (Platform.isAndroid || Platform.isIOS))
                Container(
                  alignment: Alignment.center,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildGameTitle() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Image.asset(
            'assets/icon.png', // Replace with your PNG file path
            width: 100,
            height: 100,
            //color: Colors.white, // Optional: applies color filter to the image
            //colorBlendMode: BlendMode.srcIn, // Required when using color property
          ),

          /*child: Icon(
            Icons.shield_sharp,
            size: 60,
            color: Colors.white,
          ),*/
        ),
        const SizedBox(height: 24),
        Text(
          'Snakes',
          style: GoogleFonts.cedarvilleCursive(
            fontSize: 40,
            fontWeight: FontWeight.normal,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 0.0,
                color: Colors.blue,
                offset: Offset(0, 0),
              ),
              Shadow(
                blurRadius: 20.0,
                color: Colors.blueAccent,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
        Text(
          'LADDERS',
          style: GoogleFonts.pressStart2p(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
            shadows: [
              Shadow(
                blurRadius: 0.0,
                color: Colors.blue,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMenuButton(
          context,
          text: 'PLAY GAME',
          icon: Icons.play_arrow,
          onPressed: () => _navigateToGameMode(context),
          isPrimary: true,
        ),
        const SizedBox(height: 16),
        
        _buildMenuButton(
          context,
          text: 'GAME RULES',
          icon: Icons.help_outline,
          onPressed: () => _navigateToRules(context),
        ),
        const SizedBox(height: 16),
        
        _buildMenuButton(
          context,
          text: 'EXIT GAME',
          icon: Icons.exit_to_app,
          onPressed: () => _showExitDialog(context),
        ),
      ],
    );
  }

  Widget _buildMenuButton(BuildContext context, {
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isPrimary 
            ? LinearGradient(colors: [Colors.blue, Colors.blueAccent])
            : null,
        color: isPrimary ? null : Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? null : Border.all(color: Colors.blue, width: 1),
        boxShadow: [
          BoxShadow(
            color: (isPrimary ? Colors.blue : Colors.grey[800]!).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? Colors.white : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToGameMode(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => GameModeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToRules(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RulesScreen(),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Exit Game',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Text(
            'Are you sure you want to exit the game?',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                SystemNavigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text('Exit'),
            ),
          ],
        );
      },
    );
  }
}

// === RULES SCREEN ===

class RulesScreen extends StatefulWidget {
  @override
  _RulesScreenState createState() => _RulesScreenState();
}


class _RulesScreenState extends State<RulesScreen> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    // Only load ads on mobile platforms - ADD THIS CHECK
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      AdManager.instance.loadBannerAd(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad;
          });
        },
      );
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          'Game Rules',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple[900]!, Colors.grey[900]!],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRuleCard(
                      title: 'Game Objective',
                      icon: Icons.flag,
                      content: [
                        'Be the first player to move all 4 of your pawns from the starting base to the home square (square 100).',
                        'Navigate through the board while avoiding snakes and using ladders to your advantage.',
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildRuleCard(
                      title: 'How to Play',
                      icon: Icons.play_circle,
                      content: [
                        '1. Roll the dice to determine your move',
                        '2. Select a pawn to move',
                        '3. You cannot move past square 100',
                        '4. Pass the turn to the next player',
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildRuleCard(
                      title: 'Special Squares',
                      icon: Icons.star,
                      content: [
                        '🪜 Ladders : Climb up to a higher square instantly',
                        '🐍 Snakes : Slide down to a lower square',
                        '🕳️ Holes: Skip your next turn if you land here',
                        '✨ Gold Mines: Get bonus coins and an extra turn!',
                        '🎯 Hit Opponent : If your pawn lands on an opponent\'s pawn, they are sent back to the base!',
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildRuleCard(
                      title: 'Winning the Game',
                      icon: Icons.emoji_events,
                      content: [
                        'The first player to get all 4 pawns to square 100 wins!',
                        'The game continues for remaining players to determine 2nd, 3rd place.',
                        'Strategy tip: Sometimes it\'s better to move different pawns rather than focusing on just one.',
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Banner Ad at bottom
            if (_bannerAd != null && !kIsWeb && (Platform.isAndroid || Platform.isIOS))
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard({
    required String title,
    required IconData icon,
    required List<String> content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.blueAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...content.map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          )),
        ],
      ),
    );
  }
}


/*
class RulesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          'Game Rules',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple[900]!, Colors.grey[900]!],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRuleCard(
                title: 'Game Objective',
                icon: Icons.flag,
                content: [
                  'Be the first player to move all 4 of your pawns from the starting base to the home square (square 100).',
                  'Navigate through the board while avoiding snakes and using ladders to your advantage.',
                ],
              ),
              const SizedBox(height: 24),
              _buildRuleCard(
                title: 'How to Play',
                icon: Icons.play_circle,
                content: [
                  '1. Roll the dice to determine your move',
                  '2. To enter the board, you must roll a 1',
                  '3. Select a pawn to move the number of squares shown on the dice',
                  '4. You cannot move past square 100',
                  '5. Pass the turn to the next player',
                ],
              ),
              const SizedBox(height: 24),
              _buildRuleCard(
                title: 'Special Squares',
                icon: Icons.star,
                content: [
                  '🪜 Ladders (Green): Climb up to a higher square instantly',
                  '🐍 Snakes (Red): Slide down to a lower square',
                  '🕳️ Holes: Skip your next turn if you land here',
                ],
              ),
              const SizedBox(height: 24),
              _buildRuleCard(
                title: 'Winning the Game',
                icon: Icons.emoji_events,
                content: [
                  'The first player to get all 4 pawns to square 100 wins!',
                  'The game continues for remaining players to determine 2nd, 3rd place.',
                  'Strategy tip: Sometimes it\'s better to move different pawns rather than focusing on just one.',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleCard({
    required String title,
    required IconData icon,
    required List<String> content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.blueAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...content.map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          )),
        ],
      ),
    );
  }
}
*/
