
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import 'game_mode_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import '../widgets/custom_widgets.dart';

class MainMenuScreen extends StatefulWidget {
  @override
  _MainMenuScreenState createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
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
                          'Professional Edition',
                          style: AppStyles.bodyLarge.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        
                        const Spacer(flex: 3),
                        
                        // Menu Buttons
                        _buildMenuButtons(context),
                        
                        const Spacer(flex: 2),
                        
                        // Version Info
                        Text(
                          'Version 1.0.0',
                          style: AppStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.games,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'SNAKES',
          style: AppStyles.gameTitle,
        ),
        Text(
          '& LADDERS',
          style: AppStyles.gameTitle.copyWith(
            color: AppColors.primaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomButton(
          text: 'PLAY GAME',
          onPressed: () => _navigateToGameMode(context),
          icon: Icons.play_arrow,
          gradient: AppColors.primaryGradient,
        ),
        const SizedBox(height: 16),
        
        CustomButton(
          text: 'GAME RULES',
          onPressed: () => _navigateToRules(context),
          icon: Icons.help_outline,
          isSecondary: true,
        ),
        const SizedBox(height: 16),
        
        CustomButton(
          text: 'SETTINGS',
          onPressed: () => _navigateToSettings(context),
          icon: Icons.settings,
          isSecondary: true,
        ),
        const SizedBox(height: 16),
        
        CustomButton(
          text: 'EXIT GAME',
          onPressed: () => _showExitDialog(context),
          icon: Icons.exit_to_app,
          isSecondary: true,
        ),
      ],
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

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Exit Game',
            style: AppStyles.heading3,
          ),
          content: Text(
            'Are you sure you want to exit the game?',
            style: AppStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppStyles.buttonMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Exit app logic here
              },
              child: Text('Exit'),
            ),
          ],
        );
      },
    );
  }
}
