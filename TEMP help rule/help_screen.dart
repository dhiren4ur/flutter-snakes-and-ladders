import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'How to Play',
          style: GoogleFonts.fredoka(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1a237e),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: const Color(0xFF1a237e),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[300],
              indicatorColor: Colors.amber,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Rules'),
                Tab(text: 'Squares'),
                Tab(text: 'Moves'),
                Tab(text: 'Tips'),
                Tab(text: 'FAQ'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRulesTab(),
                _buildSquaresTab(),
                _buildMovesTab(),
                _buildTipsTab(),
                _buildFAQTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: RULES
  Widget _buildRulesTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('🎮 Game Objective'),
            _buildBodyText(
              'Be the first player to move all 4 pawns to square 100 (home).',
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('🎲 How to Play'),
            _buildBulletPoint('Roll the dice (1-6)'),
            _buildBulletPoint('Select a pawn to move'),
            _buildBulletPoint('Your pawn moves forward by the rolled amount'),
            _buildBulletPoint('Special squares apply their effects'),
            _buildBulletPoint('Pass turn to next player'),
            const SizedBox(height: 16),
            _buildSectionHeader('📍 Entry Rules'),
            _buildBodyText(
              'Any roll (1, 2, 3, 4, 5, or 6) allows a pawn to enter the board from the base.',
            ),
            _buildBodyText('Example: If you roll 4, your pawn enters at square 4.'),
            const SizedBox(height: 16),
            _buildSectionHeader('⚠️ Important'),
            _buildBulletPoint('You can only move ONE pawn per turn'),
            _buildBulletPoint('Pawns cannot move beyond square 100'),
            _buildBulletPoint('Base (0) and Home (100) are safe zones'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // TAB 2: SPECIAL SQUARES
  Widget _buildSquaresTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSquareInfo(
              '🪜 LADDERS (Green)',
              'Climb up the board and earn +20 coins!',
              '2→38, 7→14, 8→31, 15→26, 21→42, 28→84, 36→44, 51→67, 71→91, 78→98, 87→94',
              const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 16),
            _buildSquareInfo(
              '🐍 SNAKES (Red)',
              'Slide down and lose -10 coins!',
              '16→6, 46→25, 49→11, 62→19, 64→60, 74→53, 89→68, 92→88, 95→75, 99→80',
              const Color(0xFFF44336),
            ),
            const SizedBox(height: 16),
            _buildSquareInfo(
              '💰 GOLD MINES (Yellow)',
              'Earn +30 coins and get an EXTRA TURN!',
              'Squares: 10, 20, 30, 50, 61, 70',
              const Color(0xFFFFD700),
            ),
            const SizedBox(height: 16),
            _buildSquareInfo(
              '🕳️ BIG HOLES (Brown)',
              'Skip your NEXT turn!',
              'Squares: 27, 57, 86',
              const Color(0xFF8B4513),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // TAB 3: MOVEMENT
  Widget _buildMovesTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('🎯 Pawn Movement'),
            _buildStepBox('Step 1', 'Roll the Dice',
                'Tap the dice button to roll (generates 1-6)'),
            _buildStepBox('Step 2', 'Select Pawn',
                'Tap the pawn you want to move from your base or board'),
            _buildStepBox('Step 3', 'Move Forward',
                'Pawn automatically moves by the rolled amount'),
            _buildStepBox('Step 4', 'Land on Square',
                'Check if special square - ladder, snake, gold, or hole'),
            _buildStepBox('Step 5', 'Next Player',
                'Turn passes to next player (unless you got extra turn)'),
            const SizedBox(height: 16),
            _buildSectionHeader('💥 Collision System'),
            _buildBodyText(
              'If your pawn lands on an opponent\'s pawn, they are sent back to the base!',
            ),
            _buildBodyText('This is a powerful offensive move!'),
            _buildBodyText(
              'Safe zones (base and home) cannot be hit - no collisions there.',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // TAB 4: TIPS
  Widget _buildTipsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTipBox(
              '💡 Tip 1: Use Ladders Wisely',
              'Plan your moves to land on ladders for big jumps forward.',
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildTipBox(
              '⚠️ Tip 2: Avoid Snakes',
              'Try to skip over snake heads - they slide you backward!',
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildTipBox(
              '🎯 Tip 3: Hit Opponents',
              'Use the collision system to send opponents back to base and slow them down.',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildTipBox(
              '💰 Tip 4: Collect Gold Mines',
              'Landing on gold mines gives coins and extra turns - very valuable!',
              Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildTipBox(
              '📊 Tip 5: Spread Your Pawns',
              'Don\'t focus on one pawn - spread progress across all 4 to win faster.',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildTipBox(
              '🤖 Tip 6: Watch AI Opponents',
              'CobraBot (aggressive), Laddie (balanced), DiceMaster (defensive) - each plays differently!',
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildTipBox(
              '⏱️ Tip 7: Time Management',
              'You have 15 seconds per turn - plan your move quickly!',
              Colors.teal,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // TAB 5: FAQ
  Widget _buildFAQTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFAQItem(
              'Q: How do pawns enter the board?',
              'A: Any roll (1-6) can enter from the base. This is different from traditional Snakes & Ladders!',
            ),
            _buildFAQItem(
              'Q: Can I have negative coins?',
              'A: No, your coin balance cannot go below 0. It will stay at 0 if you hit too many snakes.',
            ),
            _buildFAQItem(
              'Q: What happens if I get extra turn?',
              'A: If you land on a gold mine, you roll again immediately. The turn doesn\'t pass to the next player.',
            ),
            _buildFAQItem(
              'Q: How long is a skip turn?',
              'A: If you fall into a hole, you skip your NEXT turn (you lose 1 turn).',
            ),
            _buildFAQItem(
              'Q: Can I hit my own pawns?',
              'A: No, you can only hit opponent pawns. Hitting sends them to base (0).',
            ),
            _buildFAQItem(
              'Q: What\'s the maximum coins I can get?',
              'A: If you land on all 11 ladders (+220 coins) and 6 gold mines (+180 coins) = 400 coins max.',
            ),
            _buildFAQItem(
              'Q: Are coins important to win?',
              'A: No, winning means getting all 4 pawns to square 100. Coins are secondary ranking.',
            ),
            _buildFAQItem(
              'Q: How many players can play?',
              'A: 2-4 players: You + 1-3 AI opponents (CobraBot, Laddie, DiceMaster).',
            ),
            _buildFAQItem(
              'Q: What if I run out of time?',
              'A: If 15 seconds pass, the game auto-selects a valid pawn and moves it for you.',
            ),
            _buildFAQItem(
              'Q: Can I pause the game?',
              'A: Yes, tap the pause button to pause/resume anytime during gameplay.',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // HELPER WIDGETS
  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1a237e),
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 14,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1a237e),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareInfo(
    String title,
    String description,
    String details,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.left(
          side: BorderSide(color: color, width: 4),
        ),
        color: color.withOpacity(0.05),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            details,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBox(String step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a237e),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      step.split(' ')[1],
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1a237e),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipBox(String title, String content, Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.05),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.fredoka(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1a237e),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            color: Colors.grey[300],
            height: 1,
          ),
        ],
      ),
    );
  }
}
