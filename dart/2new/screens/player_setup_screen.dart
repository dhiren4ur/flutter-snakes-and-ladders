
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../widgets/custom_widgets.dart';
import 'professional_game_screen.dart';

class PlayerSetupScreen extends StatefulWidget {
  final int gameMode;
  final int playerCount;
  final int aiCount;

  const PlayerSetupScreen({
    Key? key,
    required this.gameMode,
    required this.playerCount,
    required this.aiCount,
  }) : super(key: key);

  @override
  _PlayerSetupScreenState createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> 
    with TickerProviderStateMixin {
  final List<TextEditingController> controllers = List.generate(4, (_) => TextEditingController());
  final List<String> defaultNames = ['Player', 'Warrior', 'Champion', 'Hero'];
  final List<String> aiNames = ['AI Alpha', 'AI Beta', 'AI Gamma'];
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    
    _initializePlayerNames();
    _animationController.forward();
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _initializePlayerNames() {
    // Initialize human player names
    for (int i = 0; i < widget.playerCount; i++) {
      controllers[i].text = '${defaultNames[i]} ${i + 1}';
    }
    
    // Initialize AI player names
    if (widget.gameMode == 1) {
      for (int i = 0; i < widget.aiCount; i++) {
        controllers[widget.playerCount + i].text = aiNames[i];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Player Setup',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        message: 'Starting game...',
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    _buildHeader(),
                    
                    const SizedBox(height: 32),
                    
                    Expanded(
                      child: _buildPlayerInputs(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildStartButton(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String subtitle = widget.gameMode == 0 
        ? '${widget.playerCount} Players'
        : '1 Human vs ${widget.aiCount} AI';
        
    return Column(
      children: [
        Text(
          'Enter Player Names',
          style: AppStyles.heading2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppStyles.bodyLarge.copyWith(
            color: AppColors.primaryLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlayerInputs() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _getTotalPlayers(),
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + (index * 50)),
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildPlayerCard(index),
        );
      },
    );
  }

  Widget _buildPlayerCard(int index) {
    bool isAI = _isAIPlayer(index);
    bool isHuman = !isAI;
    Color playerColor = _getPlayerColor(index);
    
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: playerColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: playerColor.withOpacity(0.2),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: playerColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: playerColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppStyles.heading3.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAI ? 'AI Player ${index - widget.playerCount + 1}' : 'Player ${index + 1}',
                      style: AppStyles.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAI ? 'Computer Opponent' : 'Human Player',
                      style: AppStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isAI)
                Icon(
                  Icons.smart_toy,
                  color: AppColors.primaryLight,
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controllers[index],
            enabled: isHuman,
            style: AppStyles.bodyMedium.copyWith(
              color: isHuman ? AppColors.textPrimary : AppColors.textMuted,
            ),
            decoration: AppStyles.inputDecoration(
              'Player Name',
              hint: isAI ? 'AI Name (auto-generated)' : 'Enter player name',
            ).copyWith(
              enabled: isHuman,
              prefixIcon: Icon(
                isAI ? Icons.smart_toy : Icons.person,
                color: playerColor,
              ),
            ),
            maxLength: 15,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
              return Text(
                '$currentLength/$maxLength',
                style: AppStyles.bodySmall,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return CustomButton(
      text: 'START GAME',
      onPressed: _startGame,
      icon: Icons.play_arrow,
      isLoading: isLoading,
    );
  }

  int _getTotalPlayers() {
    return widget.gameMode == 0 ? widget.playerCount : widget.playerCount + widget.aiCount;
  }

  bool _isAIPlayer(int index) {
    return widget.gameMode == 1 && index >= widget.playerCount;
  }

  Color _getPlayerColor(int index) {
    final colors = [
      AppColors.player1,
      AppColors.player2,
      AppColors.player3,
      AppColors.player4,
    ];
    return colors[index % colors.length];
  }

  void _startGame() async {
    // Validate player names
    List<String> names = [];
    for (int i = 0; i < _getTotalPlayers(); i++) {
      String name = controllers[i].text.trim();
      if (name.isEmpty) {
        _showError('Please enter a name for Player ${i + 1}');
        return;
      }
      names.add(name);
    }

    setState(() => isLoading = true);
    
    // Simulate loading delay for better UX
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ProfessionalGameScreen(
            playerNames: names,
            gameMode: widget.gameMode,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
