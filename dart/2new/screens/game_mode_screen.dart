
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../widgets/custom_widgets.dart';
import 'player_setup_screen.dart';

class GameModeScreen extends StatefulWidget {
  @override
  _GameModeScreenState createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen> 
    with TickerProviderStateMixin {
  int selectedMode = -1;
  int playerCount = 2;
  int aiCount = 1;
  
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Select Game Mode',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                Text(
                  'Choose Your Game Mode',
                  style: AppStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                Expanded(
                  child: Column(
                    children: [
                      // Play with Friends
                      Expanded(
                        child: GameCard(
                          title: 'Play with Friends',
                          subtitle: 'Pass and play with friends on the same device',
                          icon: Icons.people,
                          iconColor: AppColors.info,
                          isSelected: selectedMode == 0,
                          onTap: () => setState(() => selectedMode = 0),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Play with AI
                      Expanded(
                        child: GameCard(
                          title: 'Play with AI',
                          subtitle: 'Challenge computer opponents',
                          icon: Icons.smart_toy,
                          iconColor: AppColors.error,
                          isSelected: selectedMode == 1,
                          onTap: () => setState(() => selectedMode = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Player count selection
                if (selectedMode != -1) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: AppStyles.cardDecoration,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (selectedMode == 0)
                          PlayerCountSelector(
                            title: 'Number of Players',
                            selectedCount: playerCount,
                            options: const [2, 3, 4],
                            onChanged: (count) => setState(() => playerCount = count),
                          ),
                        
                        if (selectedMode == 1)
                          PlayerCountSelector(
                            title: 'Number of AI Opponents',
                            selectedCount: aiCount,
                            options: const [1, 2, 3],
                            onChanged: (count) => setState(() => aiCount = count),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
                
                // Continue button
                if (selectedMode != -1)
                  CustomButton(
                    text: 'Continue',
                    onPressed: () => _proceedToPlayerSetup(),
                    icon: Icons.arrow_forward,
                  ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _proceedToPlayerSetup() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PlayerSetupScreen(
          gameMode: selectedMode,
          playerCount: selectedMode == 0 ? playerCount : 1,
          aiCount: selectedMode == 1 ? aiCount : 0,
        ),
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
}
