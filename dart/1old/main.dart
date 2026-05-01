import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MaterialApp(
    home: GameModeScreen(),
  ));
}

// === GAME MODE SELECTION SCREEN ===

class GameModeScreen extends StatefulWidget {
  @override
  _GameModeScreenState createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen> {
  int _selectedMode = 0;
  int _playerCount = 2;
  int _aiCount = 1;

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
            // Header with glowing title
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
              child: Text(
                'SNACKS & LADDERS',
                style: GoogleFonts.pressStart2p(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.purple,
                      offset: Offset(0, 0),
                    ),
                    Shadow(
                      blurRadius: 20.0,
                      color: Colors.purpleAccent,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 40),

            // Game mode selection with images
            Text(
              'CHOOSE YOUR GAME MODE',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 30),

            // Play with Friends Option
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMode = 0;
                });
              },
              child: Container(
                width: 300,
                height: 150,
                margin: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _selectedMode == 0 ? Colors.blue[800] : Colors.grey[800],
                  border: Border.all(
                    color: _selectedMode == 0 ? Colors.blueAccent : Colors.grey,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedMode == 0 ? Colors.blueAccent.withOpacity(0.5) : Colors.transparent,
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Placeholder for image - replace with your actual image
                    Center(
                      child: Icon(
                        Icons.people,
                        size: 60,
                        color: Colors.white54,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Text(
                        'PLAY WITH FRIENDS',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Player Count Selector for Friends mode
            if (_selectedMode == 0) ...[
              SizedBox(height: 20),
              Text(
                'NUMBER OF PLAYERS',
                style: GoogleFonts.orbitron(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [2, 3, 4].map((count) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _playerCount = count;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _playerCount == count ? Colors.blueAccent : Colors.grey[700],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Play with AI Option
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMode = 1;
                });
              },
              child: Container(
                width: 300,
                height: 150,
                margin: EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _selectedMode == 1 ? Colors.red[800] : Colors.grey[800],
                  border: Border.all(
                    color: _selectedMode == 1 ? Colors.redAccent : Colors.grey,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedMode == 1 ? Colors.redAccent.withOpacity(0.5) : Colors.transparent,
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Placeholder for image - replace with your actual image
                    Center(
                      child: Icon(
                        Icons.android,
                        size: 60,
                        color: Colors.white54,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Text(
                        'PLAY WITH AI',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // AI Count Selector
            if (_selectedMode == 1) ...[
              SizedBox(height: 10),
              Text(
                'NUMBER OF AI OPPONENTS',
                style: GoogleFonts.orbitron(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [1, 2, 3].map((count) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _aiCount = count;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _aiCount == count ? Colors.redAccent : Colors.grey[700],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            Spacer(),

            // Start Button
            Container(
              margin: EdgeInsets.only(bottom: 40),
              child: ElevatedButton(
                onPressed: _proceedToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'START GAME',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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

// === LOGIN SCREEN (UPDATED) ===

class LoginScreen extends StatefulWidget {
  final int gameMode;
  final int playerCount;
  final int aiCount;

  LoginScreen({required this.gameMode, required this.playerCount, required this.aiCount});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final List<TextEditingController> controllers =
  List.generate(4, (_) => TextEditingController());

  final List<String> _friendNames = ['Cobra', 'Climber', 'Achiever', 'Sniper'];

  @override
  void initState() {
    super.initState();

    // Pre-fill AI player names based on game mode
    if (widget.gameMode == 0) {
      // Play with Friends mode - only human players
      for (int i = widget.playerCount; i < 4; i++) {
        controllers[i].text = '';
      }
    } else {
      // Play with AI mode - set AI names based on count
      final aiNames = ['CobraBot', 'Laddie', 'DiceMaster'];
      for (int i = 0; i < 4; i++) {
        if (i >= (1 + widget.aiCount)) {
          controllers[i].text = ''; // Empty for non-participating players
        } else if (i > 0) {
          controllers[i].text = aiNames[i-1]; // Set AI names
        }
      }
    }
  }

  void _startGame() {
    List<String> names =
    controllers.map((controller) => controller.text.trim()).toList();

    // For Play with Friends mode, ensure only selected players are included
    if (widget.gameMode == 0) {
      for (int i = widget.playerCount; i < names.length; i++) {
        names[i] = ''; // Clear any input for non-participating players
      }
    }

    // Replace empty names with AI bot names
    final aiNames = ['CobraBot', 'Laddie', 'DiceMaster'];
    int aiIndex = 0;

    for (int i = 0; i < names.length; i++) {
      if (names[i].isEmpty && aiIndex < aiNames.length) {
        names[i] = aiNames[aiIndex++];
      }
    }

    // Filter out non-participating players
    List<String> finalNames = [];
    for (int i = 0; i < names.length; i++) {
      if (widget.gameMode == 0 && i >= widget.playerCount) {
        // In Play with Friends mode, only include selected number of players
        continue;
      }
      if (widget.gameMode == 1 && i >= (1 + widget.aiCount)) {
        // In Play with AI mode, only include selected number of players
        continue;
      }
      finalNames.add(names[i]);
    }

    if (finalNames.isEmpty || (finalNames.length == 1 && finalNames[0].isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter at least one player name.')));
      return;
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => GameScreen(playerNames: finalNames)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple[900]!, Colors.grey[900]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              SizedBox(height: MediaQuery.of(context).padding.top + 20),
              Text(
                'ENTER PLAYER NAMES',
                style: GoogleFonts.pressStart2p(
                  fontSize: 20,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 8.0,
                      color: Colors.purple,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              Text(
                widget.gameMode == 0
                    ? '${widget.playerCount} PLAYER${widget.playerCount > 1 ? 'S' : ''}'
                    : '1 HUMAN vs ${widget.aiCount} AI',
                style: GoogleFonts.orbitron(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              SizedBox(height: 30),

              Expanded(
                child: ListView(
                  children: [
                    ...List.generate(
                      4,
                          (index) {
                        if (widget.gameMode == 0 && index >= widget.playerCount) {
                          return SizedBox.shrink();
                        }
                        if (widget.gameMode == 1 && index >= (1 + widget.aiCount)) {
                          return SizedBox.shrink();
                        }

                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.purpleAccent),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              controller: controllers[index],
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                labelText: widget.gameMode == 1 && index > 0
                                    ? 'AI Player ${index}'
                                    : 'Player ${index + 1}',
                                labelStyle: GoogleFonts.orbitron(
                                  color: Colors.white70,
                                ),
                                hintText: widget.gameMode == 1 && index > 0
                                    ? 'AI Name'
                                    : 'Enter name',
                                hintStyle: GoogleFonts.orbitron(
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'START ADVENTURE',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}