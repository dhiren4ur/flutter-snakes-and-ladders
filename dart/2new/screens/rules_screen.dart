
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../widgets/custom_widgets.dart';

class RulesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Game Rules',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildObjectiveSection(),
              const SizedBox(height: 24),
              _buildSetupSection(),
              const SizedBox(height: 24),
              _buildGameplaySection(),
              const SizedBox(height: 24),
              _buildSpecialSquaresSection(),
              const SizedBox(height: 24),
              _buildWinningSection(),
              const SizedBox(height: 24),
              _buildTipsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObjectiveSection() {
    return _buildRuleCard(
      title: 'Game Objective',
      icon: Icons.flag,
      iconColor: AppColors.success,
      content: [
        'Be the first player to move all 4 of your pawns from the starting base to the home square (square 100).',
        'Navigate through the board while avoiding snakes and using ladders to your advantage.',
      ],
    );
  }

  Widget _buildSetupSection() {
    return _buildRuleCard(
      title: 'Game Setup',
      icon: Icons.settings,
      iconColor: AppColors.info,
      content: [
        '• Choose between 2-4 players (human or AI)',
        '• Each player gets 4 pawns of their color',
        '• All pawns start in the player\'s base',
        '• Players take turns in clockwise order',
      ],
    );
  }

  Widget _buildGameplaySection() {
    return _buildRuleCard(
      title: 'How to Play',
      icon: Icons.play_circle,
      iconColor: AppColors.primary,
      content: [
        '1. Roll the dice to determine your move',
        '2. To enter the board, you must roll a 1',
        '3. Select a pawn to move the number of squares shown on the dice',
        '4. You cannot move past square 100',
        '5. Pass the turn to the next player',
      ],
    );
  }

  Widget _buildSpecialSquaresSection() {
    return _buildRuleCard(
      title: 'Special Squares',
      icon: Icons.star,
      iconColor: AppColors.warning,
      content: [
        '🪜 Ladders (Green): Climb up to a higher square instantly',
        '🐍 Snakes (Red): Slide down to a lower square',
        '💰 Gold Mines: Collect bonus coins for future features',
        '🕳️ Holes: Skip your next turn if you land here',
      ],
    );
  }

  Widget _buildWinningSection() {
    return _buildRuleCard(
      title: 'Winning the Game',
      icon: Icons.emoji_events,
      iconColor: AppColors.warning,
      content: [
        'The first player to get all 4 pawns to square 100 wins!',
        'The game continues for remaining players to determine 2nd, 3rd place.',
        'Strategy tip: Sometimes it\'s better to move different pawns rather than focusing on just one.',
      ],
    );
  }

  Widget _buildTipsSection() {
    return _buildRuleCard(
      title: 'Pro Tips',
      icon: Icons.lightbulb,
      iconColor: AppColors.primaryLight,
      content: [
        '• Spread your pawns to increase your chances',
        '• Be cautious near snakes, especially long ones',
        '• Try to land on ladder squares for quick advancement',
        '• Watch out for holes - they can cost you a turn',
        '• Plan ahead and consider all your pawn options',
      ],
    );
  }

  Widget _buildRuleCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> content,
  }) {
    return Container(
      decoration: AppStyles.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppStyles.heading3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...content.map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              text,
              style: AppStyles.bodyMedium,
            ),
          )),
        ],
      ),
    );
  }
}
