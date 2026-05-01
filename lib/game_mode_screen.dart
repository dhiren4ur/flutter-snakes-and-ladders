import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'game_screen.dart';

// === GAME MODE SELECTION SCREEN ===
class GameModeScreen extends StatefulWidget {
  @override
  _GameModeScreenState createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen>
    with TickerProviderStateMixin {
  int _selectedMode = 0;
  int _playerCount = 2;
  int _aiCount = 1;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _proceedToLogin() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => LoginScreen(
        gameMode: _selectedMode,
        playerCount: _playerCount,
        aiCount: _aiCount,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Select Game Mode',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple[900]!, Colors.grey[900]!],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Choose Your Game Mode',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Game Mode Cards
                  SizedBox(
                    height: 300,
                    child: Column(
                      children: [
                        // Play with Friends
                        Expanded(
                          child: _buildGameModeCard(
                            title: 'Play with Friends',
                            subtitle: 'Pass and play',
                            icon: Icons.people,
                            isSelected: _selectedMode == 0,
                            onTap: () => setState(() => _selectedMode = 0),
                            gradient: LinearGradient(
                              colors: [Colors.blue[800]!, Colors.blue[600]!],
                            ),
                            selectedGradient: LinearGradient(
                              colors: [Colors.blueAccent, Colors.blue[400]!],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Play with AI
                        Expanded(
                          child: _buildGameModeCard(
                            title: 'Play with AI',
                            subtitle: 'Challenge computer opponents',
                            icon: Icons.smart_toy,
                            isSelected: _selectedMode == 1,
                            onTap: () => setState(() => _selectedMode = 1),
                            gradient: LinearGradient(
                              colors: [Colors.red[800]!, Colors.red[600]!],
                            ),
                            selectedGradient: LinearGradient(
                              colors: [Colors.redAccent, Colors.red[400]!],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Player count selection
                  if (_selectedMode != -1) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
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
                        children: [
                          if (_selectedMode == 0)
                            _buildPlayerCountSelector(
                              title: 'Number of Players',
                              selectedCount: _playerCount,
                              options: const [2, 3, 4],
                              onChanged: (count) =>
                                  setState(() => _playerCount = count),
                              color: Colors.blueAccent,
                            ),
                          if (_selectedMode == 1)
                            _buildPlayerCountSelector(
                              title: 'Number of AI Opponents',
                              selectedCount: _aiCount,
                              options: const [1, 2, 3],
                              onChanged: (count) =>
                                  setState(() => _aiCount = count),
                              color: Colors.redAccent,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Continue button
                  if (_selectedMode != -1) _buildContinueButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Gradient gradient,
    required Gradient selectedGradient,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isSelected ? selectedGradient : gradient,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: (isSelected ? Colors.white : Colors.black).withOpacity(0.2),
            blurRadius: isSelected ? 12 : 8,
            offset: Offset(0, isSelected ? 6 : 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCountSelector({
    required String title,
    required int selectedCount,
    required List<int> options,
    required Function(int) onChanged,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: options.map((count) {
            final isSelected = count == selectedCount;
            return GestureDetector(
              onTap: () => onChanged(count),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [color, color.withOpacity(0.7)])
                      : null,
                  color: isSelected ? null : Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : color,
                    width: 2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.green[500]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _proceedToLogin,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// === LOGIN SCREEN ===
class LoginScreen extends StatefulWidget {
  final int gameMode; // 0 = friends, 1 = ai
  final int playerCount;
  final int aiCount;

  LoginScreen({
    required this.gameMode,
    required this.playerCount,
    required this.aiCount,
  });

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late List<TextEditingController> controllers;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final totalPlayers = _getTotalPlayers();
    controllers = List.generate(totalPlayers, (_) => TextEditingController());

    // Pre-fill AI player names for AI mode
    if (widget.gameMode == 1) {
      final aiNames = ['CobraBot', 'Laddie', 'DiceMaster'];
      for (int i = 1; i < totalPlayers; i++) {
        controllers[i].text = aiNames[i - 1];
      }
    }
  }

  int _getTotalPlayers() {
    return widget.gameMode == 0
        ? widget.playerCount
        : (1 + widget.aiCount);
  }

  bool _isAIPlayer(int index) {
    return widget.gameMode == 1 && index > 0;
  }

  void _startGame() async {
    List<String> names =
        controllers.map((controller) => controller.text.trim()).toList();

    // Ensure no empty name for human
    if (names[0].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter your name.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Ensure all fields filled (just for polish)
    for (int i = 1; i < names.length; i++) {
      if (names[i].isEmpty) {
        final aiNames = ['CobraBot', 'Laddie', 'DiceMaster'];
        names[i] = aiNames[i - 1];
      }
    }

    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GameScreen(playerNames: names)),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPlayers = _getTotalPlayers();
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Enter Player Names',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple[900]!, Colors.grey[900]!],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text(
                      widget.gameMode == 0
                          ? '${widget.playerCount} PLAYER${widget.playerCount > 1 ? 'S' : ''}'
                          : '1 HUMAN vs ${widget.aiCount} AI',
                      style: GoogleFonts.nunito(
                        color: Colors.blueAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 30),
                    Expanded(
                      child: ListView.builder(
                        itemCount: totalPlayers,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.blueAccent),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 5),
                              child: TextField(
                                controller: controllers[index],
                                enabled: !_isAIPlayer(index),
                                style: GoogleFonts.nunito(
                                  color: _isAIPlayer(index)
                                      ? Colors.grey
                                      : Colors.white,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  labelText: _isAIPlayer(index)
                                      ? 'AI Player $index'
                                      : 'Player ${index + 1}',
                                  labelStyle: GoogleFonts.nunito(
                                    color: Colors.blueAccent,
                                  ),
                                  hintText: _isAIPlayer(index)
                                      ? 'AI Name (auto-generated)'
                                      : 'Enter player name',
                                  hintStyle: GoogleFonts.nunito(
                                    color: Colors.white54,
                                  ),
                                  prefixIcon: Icon(
                                    _isAIPlayer(index)
                                        ? Icons.smart_toy
                                        : Icons.person,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                maxLength: 15,
                                buildCounter: (context,
                                    {required currentLength,
                                    required isFocused,
                                    maxLength}) {
                                  return Text(
                                    '$currentLength/$maxLength',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[700]!, Colors.green[500]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isLoading ? null : _startGame,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    'START GAME',
                                    style: GoogleFonts.nunito(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(Colors.blueAccent),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Starting game...',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
